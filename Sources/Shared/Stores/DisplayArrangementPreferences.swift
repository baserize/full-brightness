import Foundation

struct DisplayArrangementPreferences: Sendable {
    private enum Key {
        static let autoFitEnabled = "displayArrangement.autoFitEnabled"
        static let promptForNewDisplays = "displayArrangement.promptForNewDisplays"
        static let defaultNewDisplayPlacementRule = "displayArrangement.defaultNewDisplayPlacementRule"
        static let defaultNewDisplayPlacementOffset = "displayArrangement.defaultNewDisplayPlacementOffset"
        static let displayPlacementPreferences = "displayArrangement.displayPlacementPreferences"
        static let layoutProfiles = "displayArrangement.layoutProfiles"
        static let activeProfileID = "displayArrangement.activeProfileID"
        static let knownDisplayFingerprints = "displayArrangement.knownDisplayFingerprints"
        static let didSeedKnownDisplays = "displayArrangement.didSeedKnownDisplays"
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard
    }

    var autoFitEnabled: Bool {
        get {
            defaults.bool(forKey: Key.autoFitEnabled)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.autoFitEnabled)
        }
    }

    var promptForNewDisplays: Bool {
        get {
            guard defaults.object(forKey: Key.promptForNewDisplays) != nil else { return true }
            return defaults.bool(forKey: Key.promptForNewDisplays)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.promptForNewDisplays)
        }
    }

    var defaultNewDisplayPlacementRule: DisplayPlacementRule? {
        get {
            guard let rawValue = defaults.string(forKey: Key.defaultNewDisplayPlacementRule) else { return nil }
            return DisplayPlacementRule(rawValue: rawValue)
        }
        nonmutating set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: Key.defaultNewDisplayPlacementRule)
            } else {
                defaults.removeObject(forKey: Key.defaultNewDisplayPlacementRule)
            }
        }
    }

    var defaultNewDisplayPlacementOffset: DisplayPlacementOffset {
        get {
            guard let data = defaults.data(forKey: Key.defaultNewDisplayPlacementOffset),
                  let offset = try? JSONDecoder().decode(DisplayPlacementOffset.self, from: data) else {
                return .zero
            }

            return offset
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.defaultNewDisplayPlacementOffset)
        }
    }

    var displayPlacementPreferences: [DisplayPlacementPreference] {
        get {
            guard let data = defaults.data(forKey: Key.displayPlacementPreferences) else { return [] }
            return (try? JSONDecoder().decode([DisplayPlacementPreference].self, from: data)) ?? []
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.displayPlacementPreferences)
        }
    }

    var layoutProfiles: [DisplayLayoutProfile] {
        get {
            guard let data = defaults.data(forKey: Key.layoutProfiles) else { return [] }
            return (try? JSONDecoder().decode([DisplayLayoutProfile].self, from: data)) ?? []
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.layoutProfiles)
        }
    }

    var activeProfileID: UUID? {
        get {
            guard let rawValue = defaults.string(forKey: Key.activeProfileID) else { return nil }
            return UUID(uuidString: rawValue)
        }
        nonmutating set {
            defaults.set(newValue?.uuidString, forKey: Key.activeProfileID)
        }
    }

    var knownDisplayFingerprintIDs: Set<String> {
        get {
            Set(defaults.stringArray(forKey: Key.knownDisplayFingerprints) ?? [])
        }
        nonmutating set {
            defaults.set(Array(newValue).sorted(), forKey: Key.knownDisplayFingerprints)
        }
    }

    var didSeedKnownDisplays: Bool {
        get {
            defaults.bool(forKey: Key.didSeedKnownDisplays)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.didSeedKnownDisplays)
        }
    }
}
