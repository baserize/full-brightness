import CoreGraphics
import Foundation

struct DisplayFrame: Codable, Equatable, Sendable {
    let originX: Int
    let originY: Int
    let width: Int
    let height: Int

    init(originX: Int, originY: Int, width: Int, height: Int) {
        self.originX = originX
        self.originY = originY
        self.width = max(width, 1)
        self.height = max(height, 1)
    }

    init(bounds: CGRect) {
        self.init(
            originX: Int(bounds.origin.x.rounded()),
            originY: Int(bounds.origin.y.rounded()),
            width: Int(bounds.width.rounded()),
            height: Int(bounds.height.rounded())
        )
    }

    var maxX: Int {
        originX + width
    }

    var maxY: Int {
        originY + height
    }

    var centerY: Int {
        originY + height / 2
    }

    var centerX: Int {
        originX + width / 2
    }

    var originText: String {
        "x \(originX), y \(originY)"
    }

    var sizeText: String {
        "\(width) x \(height)"
    }

    func moved(toOriginX originX: Int, originY: Int) -> DisplayFrame {
        DisplayFrame(originX: originX, originY: originY, width: width, height: height)
    }
}

struct DisplayFingerprint: Codable, Hashable, Sendable {
    let vendorID: UInt32
    let productID: UInt32
    let serialNumber: UInt32
    let displayName: String
    let logicalWidth: Int
    let logicalHeight: Int

    init(display: DisplayDevice) {
        vendorID = display.vendorID
        productID = display.productID
        serialNumber = display.serialNumber
        displayName = display.name
        logicalWidth = display.resolution.logicalWidth
        logicalHeight = display.resolution.logicalHeight
    }

    var stableID: String {
        let serialComponent: String

        if serialNumber == 0 {
            serialComponent = "noserial-\(normalizedName)-\(logicalWidth)x\(logicalHeight)"
        } else {
            serialComponent = "serial-\(serialNumber)"
        }

        return "\(vendorID)-\(productID)-\(serialComponent)"
    }

    private var normalizedName: String {
        displayName
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}

struct DisplayPlacement: Codable, Equatable, Identifiable, Sendable {
    var id: String {
        fingerprint.stableID
    }

    let fingerprint: DisplayFingerprint
    let displayName: String
    let frame: DisplayFrame
    let isBuiltin: Bool
    let isMain: Bool

    init(display: DisplayDevice, isMain: Bool) {
        fingerprint = DisplayFingerprint(display: display)
        displayName = display.name
        frame = display.frame
        isBuiltin = display.isBuiltin
        self.isMain = isMain
    }

    init(
        fingerprint: DisplayFingerprint,
        displayName: String,
        frame: DisplayFrame,
        isBuiltin: Bool,
        isMain: Bool
    ) {
        self.fingerprint = fingerprint
        self.displayName = displayName
        self.frame = frame
        self.isBuiltin = isBuiltin
        self.isMain = isMain
    }

    func moved(to frame: DisplayFrame) -> DisplayPlacement {
        DisplayPlacement(
            fingerprint: fingerprint,
            displayName: displayName,
            frame: frame,
            isBuiltin: isBuiltin,
            isMain: isMain
        )
    }
}

struct DisplayArrangementSnapshot: Equatable, Sendable {
    let placements: [DisplayPlacement]
    let capturedAt: Date

    var isEmpty: Bool {
        placements.isEmpty
    }

    var displayCount: Int {
        placements.count
    }

    var mainPlacement: DisplayPlacement? {
        placements.first(where: \.isMain) ?? placements.first
    }
}

struct DisplayLayoutProfile: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var placements: [DisplayPlacement]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        placements: [DisplayPlacement]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.placements = placements
    }

    var displayCount: Int {
        placements.count
    }

    var placementIDs: Set<String> {
        Set(placements.map(\.id))
    }
}

struct NewDisplayPrompt: Identifiable, Equatable, Sendable {
    let id = UUID()
    let displays: [DisplayPlacement]

    var displayNames: String {
        displays.map(\.displayName).joined(separator: ", ")
    }
}

enum DisplayPlacementRule: String, CaseIterable, Codable, Identifiable, Sendable {
    case rightOfMain
    case leftOfMain
    case aboveMain
    case belowMain

    var id: String {
        rawValue
    }

    var titleKey: String {
        switch self {
        case .rightOfMain:
            "arrangement.rule.right"
        case .leftOfMain:
            "arrangement.rule.left"
        case .aboveMain:
            "arrangement.rule.above"
        case .belowMain:
            "arrangement.rule.below"
        }
    }

    var systemImage: String {
        switch self {
        case .rightOfMain:
            "rectangle.leadingthird.inset.filled"
        case .leftOfMain:
            "rectangle.trailingthird.inset.filled"
        case .aboveMain:
            "rectangle.bottomthird.inset.filled"
        case .belowMain:
            "rectangle.topthird.inset.filled"
        }
    }
}

struct DisplayArrangementResult: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case saved
        case applied
        case noDisplays
        case noProfile
        case noMatches
        case failed
        case partial
    }

    let status: Status
    let attemptedCount: Int
    let succeededCount: Int
    let missingDisplayNames: [String]
    let failedDisplayNames: [String]
    let completedAt: Date

    var summaryText: String {
        switch status {
        case .saved:
            L10n.string("arrangement.result.saved_format", succeededCount)
        case .applied:
            L10n.string("arrangement.result.applied_format", succeededCount)
        case .noDisplays:
            L10n.string("arrangement.result.no_displays")
        case .noProfile:
            L10n.string("arrangement.result.no_profile")
        case .noMatches:
            L10n.string("arrangement.result.no_matches")
        case .failed:
            L10n.string("arrangement.result.failed")
        case .partial:
            L10n.string("arrangement.result.partial_format", succeededCount, attemptedCount)
        }
    }

    var isWarning: Bool {
        switch status {
        case .saved, .applied:
            false
        case .noDisplays, .noProfile, .noMatches, .failed, .partial:
            true
        }
    }
}
