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
            CurrentDisplayFitStatus(model: model)

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

private struct CurrentDisplayFitStatus: View {
    let model: AppModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: statusSystemImage)
                .font(.title3)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.currentDisplaySetName)
                    .font(.headline)
                    .lineLimit(2)

                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var statusSystemImage: String {
        if model.isCurrentDisplayLayoutDifferentFromSaved {
            return "exclamationmark.triangle.fill"
        }

        return model.isCurrentDisplayLayoutSaved ? "checkmark.circle.fill" : "display.badge.plus"
    }

    private var statusColor: Color {
        if model.isCurrentDisplayLayoutDifferentFromSaved {
            return .orange
        }

        return model.isCurrentDisplayLayoutSaved ? .green : .secondary
    }

    private var statusText: String {
        if model.isCurrentDisplayLayoutDifferentFromSaved {
            return L10n.string("arrangement.current_fit.changed")
        }

        return L10n.string(model.isCurrentDisplayLayoutSaved ? "arrangement.current_fit.saved" : "arrangement.current_fit.unsaved")
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
                    let rectsByPlacementID = displayRects(in: proxy.size)

                    GlassEffectContainer(spacing: 18) {
                        ZStack {
                            ForEach(snapshot.placements) { placement in
                                let rect = rectsByPlacementID[placement.id] ?? .zero

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

    private func displayRects(in size: CGSize) -> [String: CGRect] {
        let frames = snapshot.placements.map(\.frame)
        let bounds = contentBounds(for: frames)
        let horizontalPadding: CGFloat = 28
        let verticalPadding: CGFloat = 28
        let visualGap: CGFloat = 10
        let availableWidth = max(size.width - horizontalPadding * 2, 1)
        let availableHeight = max(size.height - verticalPadding * 2, 1)
        let maxHorizontalGapRank = frames.map { horizontalGapRank(for: $0, in: frames) }.max() ?? 0
        let maxVerticalGapRank = frames.map { verticalGapRank(for: $0, in: frames) }.max() ?? 0
        let totalHorizontalGap = CGFloat(maxHorizontalGapRank) * visualGap
        let totalVerticalGap = CGFloat(maxVerticalGapRank) * visualGap
        let scale = min(
            max(availableWidth - totalHorizontalGap, 1) / CGFloat(bounds.width),
            max(availableHeight - totalVerticalGap, 1) / CGFloat(bounds.height)
        )
        let scaledContentWidth = CGFloat(bounds.width) * scale + totalHorizontalGap
        let scaledContentHeight = CGFloat(bounds.height) * scale + totalVerticalGap
        let originX = horizontalPadding + (availableWidth - scaledContentWidth) / 2
        let originY = verticalPadding + (availableHeight - scaledContentHeight) / 2

        var rectsByPlacementID: [String: CGRect] = [:]

        for placement in snapshot.placements {
            let horizontalGap = CGFloat(horizontalGapRank(for: placement.frame, in: frames)) * visualGap
            let verticalGap = CGFloat(verticalGapRank(for: placement.frame, in: frames)) * visualGap
            rectsByPlacementID[placement.id] = CGRect(
                x: originX + CGFloat(placement.frame.originX - bounds.originX) * scale + horizontalGap,
                y: originY + CGFloat(placement.frame.originY - bounds.originY) * scale + verticalGap,
                width: max(CGFloat(placement.frame.width) * scale, 92),
                height: max(CGFloat(placement.frame.height) * scale, 58)
            )
        }

        return rectsByPlacementID
    }

    private func horizontalGapRank(for frame: DisplayFrame, in frames: [DisplayFrame]) -> Int {
        Set(frames.map(\.maxX)).filter { $0 <= frame.originX }.count
    }

    private func verticalGapRank(for frame: DisplayFrame, in frames: [DisplayFrame]) -> Int {
        Set(frames.map(\.maxY)).filter { $0 <= frame.originY }.count
    }

    private func contentBounds(for frames: [DisplayFrame]) -> DisplayFrame {
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
    @State private var showsProfileManagement = false

    var body: some View {
        DisclosureGroup(isExpanded: $showsProfileManagement) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("arrangement.profile_picker", selection: selectedProfileBinding) {
                    Text("arrangement.profile.none")
                        .tag(Optional<UUID>.none)

                    ForEach(model.displayLayoutProfiles) { profile in
                        Text(profile.name)
                            .tag(Optional(profile.id))
                    }
                }

                if let profile = model.activeDisplayLayoutProfile {
                    LabeledContent("arrangement.profile.devices") {
                        Text(profile.deviceNamesText)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("arrangement.profile.display_count") {
                        Text("\(profile.displayCount)")
                            .monospacedDigit()
                    }

                    LabeledContent("arrangement.profile.updated") {
                        Text(profile.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }

                    Button(role: .destructive) {
                        model.deleteSelectedDisplayLayoutProfile()
                    } label: {
                        Label("arrangement.action.delete", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                } else {
                    ContentUnavailableView("arrangement.profile.empty", systemImage: "rectangle.3.group")
                        .frame(maxWidth: .infinity, minHeight: 110)
                }
            }
            .padding(.top, 8)
        } label: {
            Label(
                L10n.string("arrangement.manage_saved_profiles_format", model.displayLayoutProfiles.count),
                systemImage: "rectangle.3.group"
            )
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
