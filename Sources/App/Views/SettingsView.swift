import SwiftUI

struct SettingsView: View {
    @State private var launchAtLoginState = LaunchAtLoginController().state
    @State private var launchAtLoginError: String?

    private let launchAtLoginController = LaunchAtLoginController()

    var body: some View {
        Form {
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
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
        .onAppear {
            refreshLaunchAtLoginState()
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
}
