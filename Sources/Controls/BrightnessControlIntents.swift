import AppIntents

struct SetAllDisplaysToMaximumIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.set_all.title"
    static let description = IntentDescription("intent.set_all.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await BrightnessIntentAction.setAllDisplaysToMaximum()
        return .result(dialog: "\(L10n.string("intent.set_all.dialog"))")
    }
}

struct SetAutoMaxBrightnessIntent: SetValueIntent {
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
        await BrightnessIntentAction.setAutoMaxBrightness(value)
        return .result()
    }
}

struct EnableAutoMaxBrightnessIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.auto.enable.title"
    static let description = IntentDescription("intent.auto.enable.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await BrightnessIntentAction.setAutoMaxBrightness(true)
        return .result(dialog: "\(L10n.string("intent.auto.enable.dialog"))")
    }
}

struct DisableAutoMaxBrightnessIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.auto.disable.title"
    static let description = IntentDescription("intent.auto.disable.description")
    static let supportedModes: IntentModes = .foreground(.immediate)
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await BrightnessIntentAction.setAutoMaxBrightness(false)
        return .result(dialog: "\(L10n.string("intent.auto.disable.dialog"))")
    }
}

private enum BrightnessIntentAction {
    static func setAllDisplaysToMaximum() async {
        _ = await DisplayBrightnessClient.shared.setAllDisplaysToMaximum()
        ControlCenterReloader.reloadBrightnessControls()
    }

    static func setAutoMaxBrightness(_ isEnabled: Bool) async {
        let preferences = BrightnessPreferences()
        preferences.autoMaxEnabled = isEnabled

        if isEnabled {
            _ = await DisplayBrightnessClient.shared.setAllDisplaysToMaximum()
        }

        ControlCenterReloader.reloadBrightnessControls()
    }
}
