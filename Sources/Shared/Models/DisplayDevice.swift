import CoreGraphics
import Foundation

struct DisplayDevice: Identifiable, Equatable, Sendable {
    struct Resolution: Equatable, Sendable {
        let logicalWidth: Int
        let logicalHeight: Int
        let backingPixelWidth: Int
        let backingPixelHeight: Int
        let refreshRate: Double?

        var logicalText: String {
            "\(logicalWidth) x \(logicalHeight)"
        }

        var backingPixelText: String {
            "\(backingPixelWidth) x \(backingPixelHeight)"
        }

        var isHiDPI: Bool {
            backingScale > 1.25
        }

        var hiDPIText: String {
            isHiDPI ? L10n.string("display.hidpi.scale_format", backingScaleText) : L10n.string("display.hidpi.none")
        }

        var refreshRateText: String? {
            guard let refreshRate, refreshRate > 0 else { return nil }
            return "\(Int(refreshRate.rounded()))Hz"
        }

        private var backingScale: Double {
            guard logicalWidth > 0, logicalHeight > 0 else { return 1 }

            let widthScale = Double(backingPixelWidth) / Double(logicalWidth)
            let heightScale = Double(backingPixelHeight) / Double(logicalHeight)
            return (widthScale + heightScale) / 2
        }

        private var backingScaleText: String {
            let roundedScale = backingScale.rounded()

            if abs(backingScale - roundedScale) < 0.05 {
                return "\(Int(roundedScale))x"
            }

            return String(format: "%.1fx", backingScale)
        }
    }

    enum BrightnessBackend: Sendable {
        case none
        case ioDisplay
        case displayServices

        var displayName: String {
            switch self {
            case .none:
                L10n.string("display.backend.unsupported")
            case .ioDisplay:
                L10n.string("display.backend.io_display")
            case .displayServices:
                L10n.string("display.backend.display_services")
            }
        }
    }

    let id: CGDirectDisplayID
    let name: String
    let vendorID: UInt32
    let productID: UInt32
    let serialNumber: UInt32
    let isBuiltin: Bool
    let resolution: Resolution
    let frame: DisplayFrame
    let brightness: Float?
    let brightnessBackend: BrightnessBackend

    var resolutionText: String {
        resolution.logicalText
    }

    var frameText: String {
        "\(frame.sizeText) · \(frame.originText)"
    }

    var hiDPIText: String {
        resolution.hiDPIText
    }

    var brightnessPercentText: String {
        guard let brightness else { return L10n.string("display.brightness_unreadable") }
        return "\(Int((brightness * 100).rounded()))%"
    }

    var connectionText: String {
        isBuiltin ? L10n.string("display.connection.builtin") : L10n.string("display.connection.external")
    }

    var isBrightnessAdjustable: Bool {
        brightnessBackend != .none
    }

    var backendText: String {
        brightnessBackend.displayName
    }
}
