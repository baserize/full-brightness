import AppIntents

struct FullBrightnessAppShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetAllDisplaysToMaximumIntent(),
            phrases: [
                "Set displays to 100 percent with \(.applicationName)",
                "Make monitors full brightness with \(.applicationName)",
                "\(.applicationName)로 모니터 100 퍼센트",
            ],
            shortTitle: "intent.shortcut.set_all.short_title",
            systemImageName: "sun.max.fill"
        )

        AppShortcut(
            intent: EnableAutoMaxBrightnessIntent(),
            phrases: [
                "Turn on auto brightness with \(.applicationName)",
                "Auto max brightness with \(.applicationName)",
                "\(.applicationName)로 연결 시 100 퍼센트 켜기",
            ],
            shortTitle: "intent.shortcut.auto_enable.short_title",
            systemImageName: "sun.max.circle.fill"
        )

        AppShortcut(
            intent: DisableAutoMaxBrightnessIntent(),
            phrases: [
                "Turn off auto brightness with \(.applicationName)",
                "Stop auto max brightness with \(.applicationName)",
                "\(.applicationName)로 연결 시 100 퍼센트 끄기",
            ],
            shortTitle: "intent.shortcut.auto_disable.short_title",
            systemImageName: "sun.max.circle"
        )
    }
}
