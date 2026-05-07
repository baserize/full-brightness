import SwiftUI

struct DisplayListView: View {
    let displays: [DisplayDevice]

    private var adjustableDisplayCount: Int {
        displays.filter(\.isBrightnessAdjustable).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("displays.section.title")
                    .font(.title3.weight(.semibold))

                Spacer()

                Text("\(adjustableDisplayCount)/\(displays.count)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            if displays.isEmpty {
                ContentUnavailableView("displays.empty.title", systemImage: "display.trianglebadge.exclamationmark")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(spacing: 10) {
                    ForEach(displays) { display in
                        DisplayRow(display: display)
                    }
                }
            }
        }
    }
}

private struct DisplayRow: View {
    let display: DisplayDevice

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: display.isBrightnessAdjustable ? "sun.max.fill" : "display")
                .font(.title3)
                .foregroundStyle(display.isBrightnessAdjustable ? .yellow : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(display.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(L10n.string("display.logical_resolution_format", display.connectionText, display.resolutionText))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(resolutionDetailText(for: display))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(display.brightnessPercentText)
                    .font(.headline.monospacedDigit())
                    .contentTransition(.numericText())

                Text(displayStatusText)
                    .font(.caption)
                    .foregroundStyle(display.isBrightnessAdjustable ? .green : .secondary)

                if display.isBrightnessAdjustable {
                    Text(display.backendText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
        .accessibilityElement(children: .combine)
    }

    private func resolutionDetailText(for display: DisplayDevice) -> String {
        let refreshRateSuffix = display.resolution.refreshRateText.map { " · \($0)" } ?? ""
        return L10n.string(
            "display.resolution_detail_format",
            display.hiDPIText,
            display.resolution.backingPixelText,
            refreshRateSuffix
        )
    }

    private var displayStatusText: String {
        display.isBrightnessAdjustable
            ? L10n.string("display.status.adjustable")
            : L10n.string("display.status.unsupported")
    }
}
