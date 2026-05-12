import SwiftUI

struct DisplayDashboardView: View {
    @Environment(\.openSettings) private var openSettings
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DashboardHeaderView()
                DisplayActionPanel(model: model)
                DisplayListView(displays: model.displays)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("brightness.title")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.refreshDisplays()
                } label: {
                    Label("action.refresh", systemImage: "arrow.clockwise")
                }

                Button {
                    model.setDisplaysToFullLevel()
                } label: {
                    Label("action.set_all.short", systemImage: "sun.max.fill")
                }

                Button {
                    openSettings()
                } label: {
                    Label("action.settings", systemImage: "gearshape")
                }
                .help("action.settings")
            }
        }
    }
}

private struct DashboardHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("brightness.title")
                .font(.largeTitle.weight(.semibold))

            Text("brightness.subtitle")
                .foregroundStyle(.secondary)
        }
    }
}

private struct DisplayActionPanel: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    Button {
                        model.setDisplaysToFullLevel()
                    } label: {
                        Label {
                            Text(L10n.string("action.set_all.connected_format", model.targetBrightnessPercent))
                        } icon: {
                            Image(systemName: "sun.max.fill")
                        }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Toggle(isOn: $model.autoFullEnabled) {
                        Label {
                            Text(L10n.string("action.auto_on_connect_format", model.targetBrightnessPercent))
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.quaternary)
            }

            if let result = model.lastRunResult {
                Label(result.summaryText, systemImage: result.failedDisplays.isEmpty ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(result.failedDisplays.isEmpty ? Color.secondary : Color.orange)
            }
        }
    }
}
