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
        .navigationTitle("app.title")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.refreshDisplays()
                } label: {
                    Label("action.refresh", systemImage: "arrow.clockwise")
                }

                Button {
                    model.setAllDisplaysToMaximum()
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
            Text("app.title")
                .font(.largeTitle.weight(.semibold))

            Text("header.subtitle")
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
                        model.setAllDisplaysToMaximum()
                    } label: {
                        Label("action.set_all.connected", systemImage: "sun.max.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Toggle(isOn: $model.autoMaxEnabled) {
                        Label("action.auto_on_connect", systemImage: "arrow.triangle.2.circlepath")
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
