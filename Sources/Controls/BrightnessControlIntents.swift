import AppIntents

struct SetDisplaysToFullLevelIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.set_all.title"
    static let description = IntentDescription("intent.set_all.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setDisplaysToFullLevel()
        return .result()
    }
}

struct SetAutoFullLevelIntent: SetValueIntent {
    static let title: LocalizedStringResource = "intent.auto.title"
    static let description = IntentDescription("intent.auto.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "intent.auto.parameter.enabled")
    var value: Bool

    init() {
        value = false
    }

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setAutoFullLevel(value)
        return .result()
    }
}

struct EnableAutoFullLevelIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.auto.enable.title"
    static let description = IntentDescription("intent.auto.enable.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setAutoFullLevel(true)
        return .result()
    }
}

struct DisableAutoFullLevelIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.auto.disable.title"
    static let description = IntentDescription("intent.auto.disable.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setAutoFullLevel(false)
        return .result()
    }
}

private enum BrightnessIntentAction {
    static func setDisplaysToFullLevel() async -> BrightnessRunResult {
        let preferences = BrightnessPreferences()
        let result = await DisplayBrightnessClient.shared.setAllDisplays(to: preferences.targetBrightnessValue)
        ControlCenterReloader.reloadBrightnessControls()
        return result
    }

    static func setAutoFullLevel(_ isEnabled: Bool) async -> Int {
        let preferences = BrightnessPreferences()
        preferences.autoFullEnabled = isEnabled

        if isEnabled {
            _ = await DisplayBrightnessClient.shared.setAllDisplays(to: preferences.targetBrightnessValue)
        }

        ControlCenterReloader.reloadBrightnessControls()
        return preferences.targetBrightnessPercent
    }
}
