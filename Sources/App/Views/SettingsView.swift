import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var launchAtLoginState = LaunchAtLoginController().state
    @State private var launchAtLoginError: String?
    @State private var shortcutWarning: String?
    @State private var showsNewDisplayDefaults = false

    private let launchAtLoginController = LaunchAtLoginController()

    var body: some View {
        Form {
            Section("settings.section.brightness") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("settings.full_level", systemImage: "sun.max.fill")

                        Spacer()

                        Text(L10n.string("brightness.percent_format", model.targetBrightnessPercent))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: targetBrightnessSliderBinding,
                        in: Double(BrightnessPreferences.targetBrightnessPercentRange.lowerBound)...Double(BrightnessPreferences.targetBrightnessPercentRange.upperBound)
                    )
                }
            }

            Section("settings.section.arrangement") {
                Toggle(isOn: $model.autoFitEnabled) {
                    Label("arrangement.auto_fit_on_connect", systemImage: "wand.and.stars")
                }

                DisclosureGroup(isExpanded: $showsNewDisplayDefaults) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $model.promptForNewDisplays) {
                            Label("arrangement.prompt_for_new_displays", systemImage: "questionmark.bubble")
                        }
                        .disabled(model.defaultNewDisplayPlacementRule != nil)

                        NewDisplayDefaultPlacementPicker(model: model)

                        Text("settings.arrangement.new_display_defaults.help")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                } label: {
                    Label("settings.arrangement.new_display_defaults", systemImage: "display.badge.plus")
                }
            }

            Section("settings.section.general") {
                Toggle(isOn: launchAtLoginBinding) {
                    Label("settings.launch_at_login", systemImage: "power")
                }

                if launchAtLoginState == .requiresApproval {
                    Label("settings.launch_at_login.requires_approval", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }

                if let launchAtLoginError {
                    Label(L10n.string("settings.error_format", launchAtLoginError), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("settings.section.shortcuts") {
                ForEach(ShortcutAction.allCases) { action in
                    HStack(spacing: 12) {
                        Label(L10n.string(action.titleKey), systemImage: action.systemImage)

                        Spacer()

                        KeyboardShortcutRecorder(
                            shortcut: model.shortcut(for: action),
                            onRecord: { shortcut in
                                setShortcut(shortcut, for: action)
                            },
                            onInvalidShortcut: {
                                shortcutWarning = L10n.string("settings.shortcut.invalid")
                            }
                        )

                        Button {
                            model.resetShortcut(for: action)
                            shortcutWarning = nil
                        } label: {
                            Label("settings.shortcut.reset", systemImage: "arrow.counterclockwise")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help(L10n.string("settings.shortcut.reset"))
                    }
                }

                if let shortcutWarning {
                    Label(shortcutWarning, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
        .onAppear {
            refreshLaunchAtLoginState()
        }
    }

    private var targetBrightnessSliderBinding: Binding<Double> {
        Binding {
            Double(model.targetBrightnessPercent)
        } set: { newValue in
            model.targetBrightnessPercent = Int(newValue.rounded())
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            launchAtLoginState == .enabled
        } set: { isEnabled in
            setLaunchAtLoginEnabled(isEnabled)
        }
    }

    private func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            try launchAtLoginController.setEnabled(isEnabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }

        refreshLaunchAtLoginState()
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginState = launchAtLoginController.state
    }

    private func setShortcut(_ shortcut: AppKeyboardShortcut, for action: ShortcutAction) {
        switch model.setShortcut(shortcut, for: action) {
        case .saved:
            shortcutWarning = nil
        case .duplicate(let duplicateAction):
            shortcutWarning = L10n.string("settings.shortcut.duplicate_format", L10n.string(duplicateAction.titleKey))
        case .reserved:
            shortcutWarning = L10n.string("settings.shortcut.reserved")
        }
    }
}
