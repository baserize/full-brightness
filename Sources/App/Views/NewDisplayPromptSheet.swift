import SwiftUI

struct NewDisplayPromptSheet: View {
    let prompt: NewDisplayPrompt
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "display.badge.plus")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular, in: .rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {
                    Text("new_display.title")
                        .font(.title2.weight(.semibold))

                    Text(L10n.string("new_display.subtitle_format", prompt.displayNames))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GlassEffectContainer(spacing: 12) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        ForEach([DisplayPlacementRule.leftOfMain, .rightOfMain]) { rule in
                            placementButton(for: rule)
                        }
                    }

                    GridRow {
                        ForEach([DisplayPlacementRule.aboveMain, .belowMain]) { rule in
                            placementButton(for: rule)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    model.dismissPendingNewDisplayPrompt()
                } label: {
                    Text("new_display.action.not_now")
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    model.saveLayoutForPendingDisplays()
                } label: {
                    Label("new_display.action.save_current", systemImage: "square.and.arrow.down")
                }

                Button {
                    model.applyActiveLayoutForPendingDisplays()
                } label: {
                    Label("new_display.action.apply_saved", systemImage: "rectangle.3.group")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.activeDisplayLayoutProfile == nil)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private func placementButton(for rule: DisplayPlacementRule) -> some View {
        Button {
            model.applyPendingDisplays(using: rule)
        } label: {
            Label(L10n.string(rule.titleKey), systemImage: rule.systemImage)
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.plain)
        .padding(10)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
}
