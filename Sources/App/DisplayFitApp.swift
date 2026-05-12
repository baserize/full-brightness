import AppKit
import SwiftUI

@main
struct DisplayFitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("app.title", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultSize(width: 860, height: 620)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(L10n.string("action.set_all.all_displays_format", model.targetBrightnessPercent)) {
                    model.setDisplaysToFullLevel()
                }
                .keyboardShortcut(
                    model.shortcut(for: .setFullLevel).keyEquivalent,
                    modifiers: model.shortcut(for: .setFullLevel).eventModifiers
                )

                Button("action.refresh") {
                    model.refreshDisplays()
                }
                .keyboardShortcut(
                    model.shortcut(for: .refreshDisplays).keyEquivalent,
                    modifiers: model.shortcut(for: .refreshDisplays).eventModifiers
                )

                Button("arrangement.action.apply_saved") {
                    model.applyActiveDisplayLayout()
                }
                .disabled(model.activeDisplayLayoutProfile == nil)
            }
        }

        MenuBarExtra("app.title", systemImage: model.autoFullEnabled ? "sun.max.fill" : "sun.max") {
            MenuBarControlView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
