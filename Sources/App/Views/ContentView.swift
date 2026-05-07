import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel
    @State private var selection: SidebarSection? = .displays

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("sidebar.displays", systemImage: "display.2")
                    .tag(SidebarSection.displays)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            DisplayDashboardView(model: model)
        }
    }
}

private enum SidebarSection: Hashable {
    case displays
}
