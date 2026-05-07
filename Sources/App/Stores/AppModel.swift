import AppKit
import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let brightnessClient = DisplayBrightnessClient.shared
    private var preferences = BrightnessPreferences()
    private var monitor: DisplayConnectionMonitor?
    private var screenParametersObserver: NSObjectProtocol?
    private var autoBrightnessTask: Task<Void, Never>?
    private var displayRefreshTask: Task<Void, Never>?

    var displays: [DisplayDevice] = []
    var lastRunResult: BrightnessRunResult?

    var autoMaxEnabled: Bool {
        get { preferences.autoMaxEnabled }
        set {
            guard preferences.autoMaxEnabled != newValue else { return }
            preferences.autoMaxEnabled = newValue
            ControlCenterReloader.reloadBrightnessControls()

            if newValue {
                setAllDisplaysToMaximum()
            } else {
                autoBrightnessTask?.cancel()
                autoBrightnessTask = nil
            }
        }
    }

    init() {
        refreshDisplays()
        monitor = DisplayConnectionMonitor { [weak self] _, flags in
            self?.handleDisplayChange(flags: flags)
        }
        observeScreenParameterChanges()
        startDisplayRefreshPolling()

        if autoMaxEnabled {
            scheduleAutoBrightnessPass()
        }
    }

    func refreshDisplays() {
        let brightnessClient = brightnessClient

        Task { [weak self] in
            let latestDisplays = await brightnessClient.displays()
            await self?.applyDisplays(latestDisplays, clearsLastRunResult: false)
        }
    }

    func setAllDisplaysToMaximum() {
        let brightnessClient = brightnessClient

        Task { [weak self] in
            let result = await brightnessClient.setAllDisplaysToMaximum()
            let latestDisplays = await brightnessClient.displays()
            await self?.applyBrightnessRunResult(result, displays: latestDisplays)
        }
    }

    private func handleDisplayChange(flags: CGDisplayChangeSummaryFlags) {
        refreshDisplays()

        guard autoMaxEnabled, flags.shouldTriggerAutoBrightness else { return }
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
        refreshDisplays()

        if autoMaxEnabled {
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
                await self?.applyDisplays(latestDisplays, clearsLastRunResult: true)
            }
        }
    }

    private func applyDisplays(_ latestDisplays: [DisplayDevice], clearsLastRunResult: Bool) {
        guard latestDisplays != displays else { return }

        displays = latestDisplays
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
                    guard self?.autoMaxEnabled == true else { return }
                    self?.setAllDisplaysToMaximum()
                }
            }
        }
    }
}

private enum RefreshCadence {
    static let displayPolling: Duration = .milliseconds(500)
    static let autoBrightnessDelays: [Duration] = [.milliseconds(600), .seconds(2), .seconds(5)]
}

private extension CGDisplayChangeSummaryFlags {
    var shouldTriggerAutoBrightness: Bool {
        contains(.addFlag) || contains(.enabledFlag) || contains(.setModeFlag)
    }
}
