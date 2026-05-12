import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let brightnessClient = DisplayBrightnessClient.shared
    private let arrangementController = DisplayArrangementController()
    private var preferences = BrightnessPreferences()
    private var arrangementPreferences = DisplayArrangementPreferences()
    private var keyboardShortcutPreferences = KeyboardShortcutPreferences()
    private var monitor: DisplayConnectionMonitor?
    private var screenParametersObserver: NSObjectProtocol?
    private var autoBrightnessTask: Task<Void, Never>?
    private var displayRefreshTask: Task<Void, Never>?
    private var suppressArrangementHandlingUntil: Date?

    var displays: [DisplayDevice] = []
    var lastRunResult: BrightnessRunResult?
    var lastArrangementResult: DisplayArrangementResult?
    var displayLayoutProfiles: [DisplayLayoutProfile] = []
    var selectedDisplayLayoutProfileID: UUID?
    var pendingNewDisplayPrompt: NewDisplayPrompt?
    var keyboardShortcuts: [ShortcutAction: AppKeyboardShortcut] = [:]

    var autoFullEnabled: Bool {
        get { preferences.autoFullEnabled }
        set {
            guard preferences.autoFullEnabled != newValue else { return }
            preferences.autoFullEnabled = newValue
            ControlCenterReloader.reloadBrightnessControls()

            if newValue {
                setDisplaysToFullLevel()
            } else {
                autoBrightnessTask?.cancel()
                autoBrightnessTask = nil
            }
        }
    }

    var targetBrightnessPercent: Int {
        get { preferences.targetBrightnessPercent }
        set {
            let clampedValue = BrightnessPreferences.clampedTargetBrightnessPercent(newValue)
            guard preferences.targetBrightnessPercent != clampedValue else { return }

            preferences.targetBrightnessPercent = clampedValue
            lastRunResult = nil
            ControlCenterReloader.reloadBrightnessControls()
        }
    }

    var autoFitEnabled: Bool {
        get { arrangementPreferences.autoFitEnabled }
        set {
            guard arrangementPreferences.autoFitEnabled != newValue else { return }
            arrangementPreferences.autoFitEnabled = newValue

            if newValue {
                applyActiveDisplayLayout()
            }
        }
    }

    var promptForNewDisplays: Bool {
        get { arrangementPreferences.promptForNewDisplays }
        set {
            arrangementPreferences.promptForNewDisplays = newValue
        }
    }

    var defaultNewDisplayPlacementRule: DisplayPlacementRule? {
        get { arrangementPreferences.defaultNewDisplayPlacementRule }
        set {
            arrangementPreferences.defaultNewDisplayPlacementRule = newValue
        }
    }

    var arrangementSnapshot: DisplayArrangementSnapshot {
        arrangementController.snapshot(displays: displays)
    }

    var activeDisplayLayoutProfile: DisplayLayoutProfile? {
        guard let selectedDisplayLayoutProfileID else { return displayLayoutProfiles.first }
        return displayLayoutProfiles.first { $0.id == selectedDisplayLayoutProfileID }
    }

    init() {
        let shortcutPreferences = keyboardShortcutPreferences
        displayLayoutProfiles = arrangementPreferences.layoutProfiles
        if let savedProfileID = arrangementPreferences.activeProfileID,
           displayLayoutProfiles.contains(where: { $0.id == savedProfileID }) {
            selectedDisplayLayoutProfileID = savedProfileID
        } else {
            selectedDisplayLayoutProfileID = displayLayoutProfiles.first?.id
            arrangementPreferences.activeProfileID = selectedDisplayLayoutProfileID
        }
        keyboardShortcuts = Dictionary(
            uniqueKeysWithValues: ShortcutAction.allCases.map { action in
                (action, shortcutPreferences.shortcut(for: action))
            }
        )
        refreshDisplays()
        monitor = DisplayConnectionMonitor { [weak self] _, flags in
            self?.handleDisplayChange(flags: flags)
        }
        observeScreenParameterChanges()
        startDisplayRefreshPolling()

        if autoFullEnabled {
            scheduleAutoBrightnessPass()
        }
    }

    func refreshDisplays() {
        refreshDisplays(clearsLastRunResult: false, handlesArrangementChange: false)
    }

    private func refreshDisplays(clearsLastRunResult: Bool, handlesArrangementChange: Bool) {
        let brightnessClient = brightnessClient

        Task { [weak self] in
            let latestDisplays = await brightnessClient.displays()
            self?.applyDisplays(latestDisplays, clearsLastRunResult: clearsLastRunResult)

            if handlesArrangementChange {
                self?.handleArrangementChange()
            }
        }
    }

    func setDisplaysToFullLevel() {
        let brightnessClient = brightnessClient
        let targetBrightness = preferences.targetBrightnessValue

        Task { [weak self] in
            let result = await brightnessClient.setAllDisplays(to: targetBrightness)
            let latestDisplays = await brightnessClient.displays()
            self?.applyBrightnessRunResult(result, displays: latestDisplays)
        }
    }

    func shortcut(for action: ShortcutAction) -> AppKeyboardShortcut {
        keyboardShortcuts[action] ?? action.defaultShortcut
    }

    func setShortcut(_ shortcut: AppKeyboardShortcut, for action: ShortcutAction) -> ShortcutUpdateResult {
        if let duplicateAction = ShortcutAction.allCases.first(where: { candidate in
            candidate != action && self.shortcut(for: candidate) == shortcut
        }) {
            return .duplicate(duplicateAction)
        }

        if ShortcutReservedKeyEquivalent.isReserved(shortcut) {
            return .reserved
        }

        keyboardShortcutPreferences.setShortcut(shortcut, for: action)
        keyboardShortcuts[action] = shortcut
        return .saved
    }

    func resetShortcut(for action: ShortcutAction) {
        keyboardShortcutPreferences.resetShortcut(for: action)
        keyboardShortcuts[action] = action.defaultShortcut
    }

    func selectDisplayLayoutProfile(_ profileID: UUID?) {
        selectedDisplayLayoutProfileID = profileID
        arrangementPreferences.activeProfileID = profileID
        lastArrangementResult = nil
    }

    func saveCurrentDisplayLayout() {
        guard let profile = arrangementController.makeProfile(
            name: defaultDisplayLayoutProfileName(),
            displays: displays
        ) else {
            lastArrangementResult = DisplayArrangementResult(
                status: .noDisplays,
                attemptedCount: 0,
                succeededCount: 0,
                missingDisplayNames: [],
                failedDisplayNames: [],
                completedAt: Date()
            )
            return
        }

        if let selectedDisplayLayoutProfileID,
           let index = displayLayoutProfiles.firstIndex(where: { $0.id == selectedDisplayLayoutProfileID }) {
            displayLayoutProfiles[index].placements = profile.placements
            displayLayoutProfiles[index].updatedAt = Date()
            persistDisplayLayoutProfiles()
            lastArrangementResult = DisplayArrangementResult(
                status: .saved,
                attemptedCount: profile.displayCount,
                succeededCount: profile.displayCount,
                missingDisplayNames: [],
                failedDisplayNames: [],
                completedAt: Date()
            )
            markCurrentDisplaysKnown()
            return
        }

        displayLayoutProfiles.insert(profile, at: 0)
        selectDisplayLayoutProfile(profile.id)
        persistDisplayLayoutProfiles()
        lastArrangementResult = DisplayArrangementResult(
            status: .saved,
            attemptedCount: profile.displayCount,
            succeededCount: profile.displayCount,
            missingDisplayNames: [],
            failedDisplayNames: [],
            completedAt: Date()
        )
        markCurrentDisplaysKnown()
    }

    func deleteSelectedDisplayLayoutProfile() {
        guard let selectedDisplayLayoutProfileID else { return }
        displayLayoutProfiles.removeAll { $0.id == selectedDisplayLayoutProfileID }
        let nextProfileID = displayLayoutProfiles.first?.id
        selectDisplayLayoutProfile(nextProfileID)
        persistDisplayLayoutProfiles()
        lastArrangementResult = nil
    }

    func applyActiveDisplayLayout() {
        suppressArrangementHandlingUntil = Date().addingTimeInterval(3)
        let result = arrangementController.apply(profile: activeDisplayLayoutProfile, to: displays)
        lastArrangementResult = result

        if !result.isWarning {
            markCurrentDisplaysKnown()
            refreshDisplays()
        }
    }

    func applyPendingDisplays(using rule: DisplayPlacementRule) {
        guard let pendingNewDisplayPrompt else { return }

        applyNewDisplays(pendingNewDisplayPrompt.displays, using: rule)
        self.pendingNewDisplayPrompt = nil
    }

    func saveLayoutForPendingDisplays() {
        saveCurrentDisplayLayout()
        if let pendingNewDisplayPrompt {
            markDisplaysKnown(pendingNewDisplayPrompt.displays)
        }
        pendingNewDisplayPrompt = nil
    }

    func applyActiveLayoutForPendingDisplays() {
        if let pendingNewDisplayPrompt {
            markDisplaysKnown(pendingNewDisplayPrompt.displays)
        }
        pendingNewDisplayPrompt = nil
        applyActiveDisplayLayout()
    }

    func dismissPendingNewDisplayPrompt() {
        pendingNewDisplayPrompt = nil
    }

    private func handleDisplayChange(flags: CGDisplayChangeSummaryFlags) {
        refreshDisplays(clearsLastRunResult: false, handlesArrangementChange: flags.shouldTriggerDisplayFit)

        guard autoFullEnabled, flags.shouldTriggerAutoBrightness else { return }
        scheduleAutoBrightnessPass()
    }

    private func observeScreenParameterChanges() {
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenParametersChange()
            }
        }
    }

    private func handleScreenParametersChange() {
        refreshDisplays(clearsLastRunResult: false, handlesArrangementChange: true)

        if autoFullEnabled {
            scheduleAutoBrightnessPass()
        }
    }

    private func startDisplayRefreshPolling() {
        displayRefreshTask?.cancel()
        let brightnessClient = brightnessClient

        displayRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: RefreshCadence.displayPolling)
                guard !Task.isCancelled else { return }

                let latestDisplays = await brightnessClient.displays()
                self?.applyDisplays(latestDisplays, clearsLastRunResult: true)
            }
        }
    }

    private func applyDisplays(_ latestDisplays: [DisplayDevice], clearsLastRunResult: Bool) {
        guard latestDisplays != displays else { return }

        displays = latestDisplays
        seedKnownDisplaysIfNeeded()

        if clearsLastRunResult {
            lastRunResult = nil
        }
    }

    private func applyBrightnessRunResult(_ result: BrightnessRunResult, displays latestDisplays: [DisplayDevice]) {
        lastRunResult = result
        applyDisplays(latestDisplays, clearsLastRunResult: false)
        ControlCenterReloader.reloadBrightnessControls()
    }

    private func scheduleAutoBrightnessPass() {
        autoBrightnessTask?.cancel()

        autoBrightnessTask = Task { [weak self] in
            for delay in RefreshCadence.autoBrightnessDelays {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self?.autoFullEnabled == true else { return }
                    self?.setDisplaysToFullLevel()
                }
            }
        }
    }

    private func handleArrangementChange() {
        seedKnownDisplaysIfNeeded()

        if let suppressArrangementHandlingUntil,
           suppressArrangementHandlingUntil > Date() {
            return
        }

        let snapshot = arrangementSnapshot
        let knownDisplayIDs = arrangementPreferences.knownDisplayFingerprintIDs
        let newDisplays = snapshot.placements.filter { !knownDisplayIDs.contains($0.id) }

        if !newDisplays.isEmpty {
            if let defaultNewDisplayPlacementRule {
                applyNewDisplays(newDisplays, using: defaultNewDisplayPlacementRule)
            } else if promptForNewDisplays {
                pendingNewDisplayPrompt = NewDisplayPrompt(displays: newDisplays)
            } else {
                markDisplaysKnown(newDisplays)
                if autoFitEnabled {
                    applyActiveDisplayLayout()
                }
            }

            return
        }

        if autoFitEnabled {
            applyActiveDisplayLayout()
        }
    }

    private func applyNewDisplays(_ placements: [DisplayPlacement], using rule: DisplayPlacementRule) {
        let targetIDs = Set(placements.map(\.id))
        let profile = arrangementController.makePlacementProfile(
            rule: rule,
            targetPlacementIDs: targetIDs,
            displays: displays
        )

        suppressArrangementHandlingUntil = Date().addingTimeInterval(3)
        let result = arrangementController.apply(profile: profile, to: displays)
        lastArrangementResult = result
        markDisplaysKnown(placements)
        refreshDisplays()
    }

    private func seedKnownDisplaysIfNeeded() {
        guard !arrangementPreferences.didSeedKnownDisplays else { return }

        markCurrentDisplaysKnown()
        arrangementPreferences.didSeedKnownDisplays = true
    }

    private func markCurrentDisplaysKnown() {
        markDisplaysKnown(arrangementSnapshot.placements)
    }

    private func markDisplaysKnown(_ placements: [DisplayPlacement]) {
        var knownDisplayIDs = arrangementPreferences.knownDisplayFingerprintIDs
        knownDisplayIDs.formUnion(placements.map(\.id))
        arrangementPreferences.knownDisplayFingerprintIDs = knownDisplayIDs
    }

    private func persistDisplayLayoutProfiles() {
        arrangementPreferences.layoutProfiles = displayLayoutProfiles
        arrangementPreferences.activeProfileID = selectedDisplayLayoutProfileID
    }

    private func defaultDisplayLayoutProfileName() -> String {
        let displayCount = max(displays.count, 1)
        return L10n.string("arrangement.profile.default_name_format", displayCount)
    }
}

enum ShortcutUpdateResult: Equatable {
    case saved
    case duplicate(ShortcutAction)
    case reserved
}

private enum ShortcutReservedKeyEquivalent {
    static func isReserved(_ shortcut: AppKeyboardShortcut) -> Bool {
        reservedShortcuts.contains(shortcut)
    }

    private static let reservedShortcuts = Set([
        AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_Q), key: "Q", modifiers: [.command]),
        AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_Comma), key: ",", modifiers: [.command]),
        AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_H), key: "H", modifiers: [.command]),
        AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_M), key: "M", modifiers: [.command]),
        AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_W), key: "W", modifiers: [.command]),
    ])
}

private enum RefreshCadence {
    static let displayPolling: Duration = .milliseconds(500)
    static let autoBrightnessDelays: [Duration] = [.milliseconds(600), .seconds(2), .seconds(5)]
}

private extension CGDisplayChangeSummaryFlags {
    var shouldTriggerAutoBrightness: Bool {
        contains(.addFlag) || contains(.enabledFlag) || contains(.setModeFlag)
    }

    var shouldTriggerDisplayFit: Bool {
        contains(.addFlag) || contains(.enabledFlag) || contains(.setModeFlag)
    }
}
