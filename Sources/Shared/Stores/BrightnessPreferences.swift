import Foundation

struct BrightnessPreferences: Sendable {
    static let defaultTargetBrightnessPercent = 100
    static let targetBrightnessPercentRange = 1...100

    private enum Key {
        static let autoFullEnabled = "autoMaxEnabled"
        static let targetBrightnessPercent = "targetBrightnessPercent"
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard
    }

    var autoFullEnabled: Bool {
        get {
            defaults.bool(forKey: Key.autoFullEnabled)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.autoFullEnabled)
        }
    }

    var targetBrightnessPercent: Int {
        get {
            let percent = defaults.object(forKey: Key.targetBrightnessPercent) as? Int ?? Self.defaultTargetBrightnessPercent
            return Self.clampedTargetBrightnessPercent(percent)
        }
        nonmutating set {
            let percent = Self.clampedTargetBrightnessPercent(newValue)
            defaults.set(percent, forKey: Key.targetBrightnessPercent)
        }
    }

    var targetBrightnessValue: Float {
        Float(targetBrightnessPercent) / 100
    }

    static func clampedTargetBrightnessPercent(_ percent: Int) -> Int {
        min(max(percent, targetBrightnessPercentRange.lowerBound), targetBrightnessPercentRange.upperBound)
    }
}
