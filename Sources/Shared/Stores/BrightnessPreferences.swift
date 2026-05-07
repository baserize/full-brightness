import Foundation

struct BrightnessPreferences: Sendable {
    private enum Key {
        static let autoMaxEnabled = "autoMaxEnabled"
    }

    var autoMaxEnabled: Bool {
        get {
            let value = CFPreferencesCopyAppValue(Key.autoMaxEnabled as CFString, AppConstants.appBundleIdentifier as CFString)
            return (value as? Bool) ?? false
        }
        nonmutating set {
            CFPreferencesSetAppValue(Key.autoMaxEnabled as CFString, newValue as CFBoolean, AppConstants.appBundleIdentifier as CFString)
            CFPreferencesAppSynchronize(AppConstants.appBundleIdentifier as CFString)
        }
    }
}
