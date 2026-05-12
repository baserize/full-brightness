import SwiftUI

struct NewDisplayDefaultPlacementPicker: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
                placementButton(rule: nil)

                Divider()

                ForEach(DisplayPlacementRule.allCases) { rule in
                    placementButton(rule: rule)
                }
            } label: {
                Label(currentPlacementTitle, systemImage: currentPlacementSystemImage)
            }

            if model.defaultNewDisplayPlacementRule != nil {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        offsetStepper(
                            titleKey: "arrangement.default_new_display_offset.horizontal",
                            value: horizontalOffsetBinding
                        )

                        offsetStepper(
                            titleKey: "arrangement.default_new_display_offset.vertical",
                            value: verticalOffsetBinding
                        )

                        Button {
                            model.defaultNewDisplayPlacementOffset = .zero
                        } label: {
                            Label("arrangement.default_new_display_offset.reset", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderless)
                        .disabled(model.defaultNewDisplayPlacementOffset == .zero)
                    }
                    .padding(.top, 8)
                } label: {
                    Label("arrangement.default_new_display_offset.details", systemImage: "slider.horizontal.3")
                }
            }
        }
    }

    private var currentPlacementTitle: String {
        guard let rule = model.defaultNewDisplayPlacementRule else {
            return L10n.string("arrangement.default_new_display_position.prompt")
        }

        return L10n.string(rule.titleKey)
    }

    private var currentPlacementSystemImage: String {
        model.defaultNewDisplayPlacementRule?.systemImage ?? "questionmark.bubble"
    }

    private func placementButton(rule: DisplayPlacementRule?) -> some View {
        Button {
            model.defaultNewDisplayPlacementRule = rule
            if rule == nil {
                model.promptForNewDisplays = true
            }
        } label: {
            Label(placementTitle(for: rule), systemImage: placementSystemImage(for: rule))
        }
    }

    private func placementTitle(for rule: DisplayPlacementRule?) -> String {
        guard let rule else {
            return L10n.string("arrangement.default_new_display_position.prompt")
        }

        return L10n.string(rule.titleKey)
    }

    private func placementSystemImage(for rule: DisplayPlacementRule?) -> String {
        rule?.systemImage ?? "questionmark.bubble"
    }

    private var horizontalOffsetBinding: Binding<Int> {
        Binding {
            model.defaultNewDisplayPlacementOffset.horizontal
        } set: { newValue in
            model.defaultNewDisplayPlacementOffset = model.defaultNewDisplayPlacementOffset.updating(horizontal: newValue)
        }
    }

    private var verticalOffsetBinding: Binding<Int> {
        Binding {
            model.defaultNewDisplayPlacementOffset.vertical
        } set: { newValue in
            model.defaultNewDisplayPlacementOffset = model.defaultNewDisplayPlacementOffset.updating(vertical: newValue)
        }
    }

    private func offsetStepper(titleKey: String, value: Binding<Int>) -> some View {
        Stepper(value: value, in: DisplayPlacementOffset.range, step: 10) {
            LabeledContent {
                Text(L10n.string("arrangement.default_new_display_offset.value_format", value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            } label: {
                Text(L10n.string(titleKey))
            }
        }
    }
}
