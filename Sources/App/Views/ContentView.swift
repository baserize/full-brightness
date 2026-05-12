import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel
    @State private var selection: SidebarSection? = .displays

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("sidebar.displays", systemImage: "sun.max")
                    .tag(SidebarSection.displays)

                Label("sidebar.arrangement", systemImage: "rectangle.3.group")
                    .tag(SidebarSection.arrangement)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selection ?? .displays {
            case .displays:
                DisplayDashboardView(model: model)
            case .arrangement:
                ArrangementView(model: model)
            }
        }
        .sheet(item: $model.pendingNewDisplayPrompt) { prompt in
            NewDisplayPromptSheet(prompt: prompt, model: model)
        }
    }
}

private enum SidebarSection: Hashable {
    case displays
    case arrangement
}
