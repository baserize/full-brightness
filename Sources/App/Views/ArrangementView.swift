import SwiftUI

struct ArrangementView: View {
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ArrangementHeaderView()
                ArrangementActionPanel(model: model)
                DisplayArrangementCanvas(snapshot: model.arrangementSnapshot)
                SavedLayoutProfilePanel(model: model)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("arrangement.title")
        .toolbar(id: "arrangement-toolbar") {
            ToolbarItem(id: "save-layout") {
                Button {
                    model.saveCurrentDisplayLayout()
                } label: {
                    Label("arrangement.action.save", systemImage: "square.and.arrow.down")
                }
            }

            ToolbarItem(id: "apply-layout") {
                Button {
                    model.applyActiveDisplayLayout()
                } label: {
                    Label("arrangement.action.apply", systemImage: "rectangle.3.group")
                }
            }
            ToolbarSpacer(.fixed)

            ToolbarItem(id: "refresh") {
                Button {
                    model.refreshDisplays()
                } label: {
                    Label("action.refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

private struct ArrangementHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("arrangement.title")
                .font(.largeTitle.weight(.semibold))

            Text("arrangement.subtitle")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ArrangementActionPanel: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    Button {
                        model.saveCurrentDisplayLayout()
                    } label: {
                        Label("arrangement.action.save_current", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        model.applyActiveDisplayLayout()
                    } label: {
                        Label("arrangement.action.apply_saved", systemImage: "rectangle.3.group")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(model.activeDisplayLayoutProfile == nil)
                }
            }

            Toggle(isOn: $model.autoFitEnabled) {
                Label("arrangement.auto_fit_on_connect", systemImage: "wand.and.stars")
            }
            .toggleStyle(.switch)

            Toggle(isOn: $model.promptForNewDisplays) {
                Label("arrangement.prompt_for_new_displays", systemImage: "questionmark.bubble")
            }
            .toggleStyle(.switch)
            .disabled(model.defaultNewDisplayPlacementRule != nil)

            NewDisplayDefaultPlacementPicker(model: model)

            if let result = model.lastArrangementResult {
                Label(result.summaryText, systemImage: result.isWarning ? "exclamationmark.triangle" : "checkmark.circle")
                    .font(.callout)
                    .foregroundStyle(result.isWarning ? Color.orange : Color.secondary)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

private struct DisplayArrangementCanvas: View {
    let snapshot: DisplayArrangementSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("arrangement.current_layout")
                    .font(.title3.weight(.semibold))

                Spacer()

                Text("\(snapshot.displayCount)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if snapshot.isEmpty {
                ContentUnavailableView("displays.empty.title", systemImage: "display.trianglebadge.exclamationmark")
                    .frame(maxWidth: .infinity, minHeight: 280)
            } else {
                GeometryReader { proxy in
                    GlassEffectContainer(spacing: 18) {
                        ZStack {
                            ForEach(snapshot.placements) { placement in
                                let rect = displayRect(for: placement, in: proxy.size)

                                DisplayArrangementTile(placement: placement)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                            }
                        }
                    }
                }
                .frame(minHeight: 300)
                .padding(16)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func displayRect(for placement: DisplayPlacement, in size: CGSize) -> CGRect {
        let bounds = contentBounds
        let horizontalPadding: CGFloat = 28
        let verticalPadding: CGFloat = 28
        let availableWidth = max(size.width - horizontalPadding * 2, 1)
        let availableHeight = max(size.height - verticalPadding * 2, 1)
        let scale = min(availableWidth / CGFloat(bounds.width), availableHeight / CGFloat(bounds.height))
        let scaledContentWidth = CGFloat(bounds.width) * scale
        let scaledContentHeight = CGFloat(bounds.height) * scale
        let originX = horizontalPadding + (availableWidth - scaledContentWidth) / 2
        let originY = verticalPadding + (availableHeight - scaledContentHeight) / 2

        return CGRect(
            x: originX + CGFloat(placement.frame.originX - bounds.originX) * scale,
            y: originY + CGFloat(placement.frame.originY - bounds.originY) * scale,
            width: max(CGFloat(placement.frame.width) * scale, 92),
            height: max(CGFloat(placement.frame.height) * scale, 58)
        )
    }

    private var contentBounds: DisplayFrame {
        let frames = snapshot.placements.map(\.frame)
        let minX = frames.map(\.originX).min() ?? 0
        let minY = frames.map(\.originY).min() ?? 0
        let maxX = frames.map(\.maxX).max() ?? 1
        let maxY = frames.map(\.maxY).max() ?? 1

        return DisplayFrame(originX: minX, originY: minY, width: maxX - minX, height: maxY - minY)
    }
}

private struct DisplayArrangementTile: View {
    let placement: DisplayPlacement

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: placement.isBuiltin ? "macbook" : "display")
                .font(.title2)
                .symbolVariant(placement.isMain ? .fill : .none)

            Text(placement.displayName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(placement.frame.originText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            if placement.isMain {
                Text("arrangement.main_display")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct SavedLayoutProfilePanel: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("arrangement.saved_profiles")
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    model.deleteSelectedDisplayLayoutProfile()
                } label: {
                    Label("arrangement.action.delete", systemImage: "trash")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .disabled(model.activeDisplayLayoutProfile == nil)
                .help("arrangement.action.delete")
            }

            Picker("arrangement.profile_picker", selection: selectedProfileBinding) {
                Text("arrangement.profile.none")
                    .tag(Optional<UUID>.none)

                ForEach(model.displayLayoutProfiles) { profile in
                    Text(profile.name)
                        .tag(Optional(profile.id))
                }
            }

            if let profile = model.activeDisplayLayoutProfile {
                LabeledContent("arrangement.profile.display_count") {
                    Text("\(profile.displayCount)")
                        .monospacedDigit()
                }

                LabeledContent("arrangement.profile.updated") {
                    Text(profile.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
            } else {
                ContentUnavailableView("arrangement.profile.empty", systemImage: "rectangle.3.group")
                    .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
    }

    private var selectedProfileBinding: Binding<UUID?> {
        Binding {
            model.selectedDisplayLayoutProfileID
        } set: { newValue in
            model.selectDisplayLayoutProfile(newValue)
        }
    }
}
