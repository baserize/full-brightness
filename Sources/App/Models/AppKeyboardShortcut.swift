import AppKit
import Carbon.HIToolbox
import SwiftUI

enum ShortcutAction: String, CaseIterable, Identifiable {
    case setFullLevel
    case refreshDisplays

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .setFullLevel:
            "settings.shortcut.set_full"
        case .refreshDisplays:
            "settings.shortcut.refresh"
        }
    }

    var systemImage: String {
        switch self {
        case .setFullLevel:
            "sun.max.fill"
        case .refreshDisplays:
            "arrow.clockwise"
        }
    }

    var defaultShortcut: AppKeyboardShortcut {
        switch self {
        case .setFullLevel:
            AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_B), key: "B", modifiers: [.command, .shift])
        case .refreshDisplays:
            AppKeyboardShortcut(keyCode: UInt16(kVK_ANSI_R), key: "R", modifiers: [.command])
        }
    }
}

struct AppKeyboardShortcut: Equatable, Hashable {
    let keyCode: UInt16
    let key: String
    let modifiers: NSEvent.ModifierFlags

    var displayText: String {
        modifierDisplayText + key.uppercased()
    }

    var keyEquivalent: KeyEquivalent {
        KeyEquivalent(Character(key.lowercased()))
    }

    var eventModifiers: SwiftUI.EventModifiers {
        var eventModifiers = SwiftUI.EventModifiers()

        if modifiers.contains(.command) {
            eventModifiers.insert(.command)
        }

        if modifiers.contains(.option) {
            eventModifiers.insert(.option)
        }

        if modifiers.contains(.control) {
            eventModifiers.insert(.control)
        }

        if modifiers.contains(.shift) {
            eventModifiers.insert(.shift)
        }

        return eventModifiers
    }

    var serializedValue: String {
        "\(keyCode)|\(modifiers.shortcutRawValue)|\(key)"
    }

    init(keyCode: UInt16, key: String, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.key = key.uppercased()
        self.modifiers = modifiers.shortcutFlags
    }

    init?(serializedValue: String) {
        let parts = serializedValue.split(separator: "|", maxSplits: 2).map(String.init)
        guard parts.count == 3,
              let keyCode = UInt16(parts[0]),
              let rawModifiers = UInt(parts[1]),
              !parts[2].isEmpty else {
            return nil
        }

        self.init(
            keyCode: keyCode,
            key: parts[2],
            modifiers: NSEvent.ModifierFlags(rawValue: rawModifiers)
        )
    }

    init?(event: NSEvent) {
        guard let character = event.charactersIgnoringModifiers?.first else {
            return nil
        }

        let key = String(character).uppercased()
        guard key.count == 1, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let modifiers = event.modifierFlags.shortcutFlags
        guard modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) else {
            return nil
        }

        self.init(keyCode: event.keyCode, key: key, modifiers: modifiers)
    }

    static func == (lhs: AppKeyboardShortcut, rhs: AppKeyboardShortcut) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.modifiers.shortcutRawValue == rhs.modifiers.shortcutRawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers.shortcutRawValue)
    }

    private var modifierDisplayText: String {
        var text = ""

        if modifiers.contains(.control) {
            text += "⌃"
        }

        if modifiers.contains(.option) {
            text += "⌥"
        }

        if modifiers.contains(.shift) {
            text += "⇧"
        }

        if modifiers.contains(.command) {
            text += "⌘"
        }

        return text
    }
}

private extension NSEvent.ModifierFlags {
    var shortcutFlags: NSEvent.ModifierFlags {
        intersection([.command, .option, .control, .shift])
    }

    var shortcutRawValue: UInt {
        shortcutFlags.rawValue
    }
}
