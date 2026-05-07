import AppIntents

struct SetDisplaysToFullBrightnessIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.set_all.title"
    static let description = IntentDescription("intent.set_all.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setAllDisplaysToFullBrightness()
        return .result()
    }
}

struct SetAutoFullBrightnessIntent: SetValueIntent {
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
        _ = await BrightnessIntentAction.setAutoFullBrightness(value)
        return .result()
    }
}

struct EnableAutoFullBrightnessIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.auto.enable.title"
    static let description = IntentDescription("intent.auto.enable.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setAutoFullBrightness(true)
        return .result()
    }
}

struct DisableAutoFullBrightnessIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.auto.disable.title"
    static let description = IntentDescription("intent.auto.disable.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        _ = await BrightnessIntentAction.setAutoFullBrightness(false)
        return .result()
    }
}

private enum BrightnessIntentAction {
    static func setAllDisplaysToFullBrightness() async -> BrightnessRunResult {
        let preferences = BrightnessPreferences()
        let result = await DisplayBrightnessClient.shared.setAllDisplays(to: preferences.targetBrightnessValue)
        ControlCenterReloader.reloadBrightnessControls()
        return result
    }

    static func setAutoFullBrightness(_ isEnabled: Bool) async -> Int {
        let preferences = BrightnessPreferences()
        preferences.autoFullEnabled = isEnabled

        if isEnabled {
            _ = await DisplayBrightnessClient.shared.setAllDisplays(to: preferences.targetBrightnessValue)
        }

        ControlCenterReloader.reloadBrightnessControls()
        return preferences.targetBrightnessPercent
    }
}
