import Foundation

struct KeyboardShortcutPreferences {
    private var defaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard
    }

    func shortcut(for action: ShortcutAction) -> AppKeyboardShortcut {
        guard let value = defaults.string(forKey: key(for: action)),
              let shortcut = AppKeyboardShortcut(serializedValue: value) else {
            return action.defaultShortcut
        }

        return shortcut
    }

    func setShortcut(_ shortcut: AppKeyboardShortcut, for action: ShortcutAction) {
        defaults.set(shortcut.serializedValue, forKey: key(for: action))
    }

    func resetShortcut(for action: ShortcutAction) {
        defaults.removeObject(forKey: key(for: action))
    }

    private func key(for action: ShortcutAction) -> String {
        "keyboardShortcut.\(action.rawValue)"
    }
}
