import AppIntents

struct DisplayFitAppShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetDisplaysToFullLevelIntent(),
            phrases: [
                "Set displays to full brightness with \(.applicationName)",
                "Make monitors full brightness with \(.applicationName)",
                "\(.applicationName)로 모니터 Full 밝기",
            ],
            shortTitle: "intent.shortcut.set_all.short_title",
            systemImageName: "sun.max.fill"
        )

        AppShortcut(
            intent: EnableAutoFullLevelIntent(),
            phrases: [
                "Turn on auto brightness with \(.applicationName)",
                "Auto full brightness with \(.applicationName)",
                "\(.applicationName)로 연결 시 Full 밝기 켜기",
            ],
            shortTitle: "intent.shortcut.auto_enable.short_title",
            systemImageName: "sun.max.circle.fill"
        )

        AppShortcut(
            intent: DisableAutoFullLevelIntent(),
            phrases: [
                "Turn off auto brightness with \(.applicationName)",
                "Stop auto full brightness with \(.applicationName)",
                "\(.applicationName)로 연결 시 Full 밝기 끄기",
            ],
            shortTitle: "intent.shortcut.auto_disable.short_title",
            systemImageName: "sun.max.circle"
        )
    }
}
