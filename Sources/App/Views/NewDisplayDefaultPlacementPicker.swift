import SwiftUI

struct NewDisplayDefaultPlacementPicker: View {
    @Bindable var model: AppModel

    var body: some View {
        Picker(selection: defaultPlacementBinding) {
            Text("arrangement.default_new_display_position.prompt")
                .tag(Optional<DisplayPlacementRule>.none)

            ForEach(DisplayPlacementRule.allCases) { rule in
                Label(L10n.string(rule.titleKey), systemImage: rule.systemImage)
                    .tag(Optional(rule))
            }
        } label: {
            Label("arrangement.default_new_display_position", systemImage: "display.badge.plus")
        }
        .pickerStyle(.menu)
    }

    private var defaultPlacementBinding: Binding<DisplayPlacementRule?> {
        Binding {
            model.defaultNewDisplayPlacementRule
        } set: { newValue in
            model.defaultNewDisplayPlacementRule = newValue
            if newValue == nil {
                model.promptForNewDisplays = true
            }
        }
    }
}
