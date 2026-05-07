import SwiftUI

struct MenuBarControlView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("app.title", systemImage: "sun.max.fill")
                    .font(.headline)

                Spacer()

                Button {
                    model.refreshDisplays()
                } label: {
                    Label("action.refresh", systemImage: "arrow.clockwise")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }

            Button {
                model.setAllDisplaysToMaximum()
            } label: {
                Label("action.set_all.all_displays", systemImage: "sun.max.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Toggle(isOn: $model.autoMaxEnabled) {
                Label("action.auto_on_connect", systemImage: "arrow.triangle.2.circlepath")
            }
            .toggleStyle(.switch)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.displays.prefix(6)) { display in
                    HStack {
                        Image(systemName: display.isBrightnessAdjustable ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(display.isBrightnessAdjustable ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(display.name)
                                .lineLimit(1)

                            Text(L10n.string("display.menu_resolution_format", display.resolutionText, display.hiDPIText))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(display.brightnessPercentText)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .font(.callout)
                    .accessibilityElement(children: .combine)
                }

                if model.displays.isEmpty {
                    Text("displays.empty.menubar")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Button("action.open_app") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }

            Button("action.quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}
