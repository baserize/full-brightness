import AppKit
import SwiftUI

@main
struct FullBrightnessApp: App {
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
                Button("action.set_all.all_displays") {
                    model.setAllDisplaysToMaximum()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("app.title", systemImage: model.autoMaxEnabled ? "sun.max.fill" : "sun.max") {
            MenuBarControlView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
