import CoreGraphics
import Foundation

struct DisplayArrangementController: Sendable {
    func snapshot(displays: [DisplayDevice]) -> DisplayArrangementSnapshot {
        let mainDisplayID = CGMainDisplayID()
        let placements = displays
            .map { display in
                DisplayPlacement(display: display, isMain: display.id == mainDisplayID)
            }
            .sorted { lhs, rhs in
                if lhs.isMain != rhs.isMain {
                    return lhs.isMain
                }

                if lhs.frame.originY != rhs.frame.originY {
                    return lhs.frame.originY < rhs.frame.originY
                }

                return lhs.frame.originX < rhs.frame.originX
            }

        return DisplayArrangementSnapshot(placements: placements, capturedAt: Date())
    }

    func makeProfile(name: String, displays: [DisplayDevice]) -> DisplayLayoutProfile? {
        let snapshot = snapshot(displays: displays)
        guard !snapshot.isEmpty else { return nil }

        return DisplayLayoutProfile(name: name, placements: snapshot.placements)
    }

    func apply(profile: DisplayLayoutProfile?, to displays: [DisplayDevice]) -> DisplayArrangementResult {
        guard let profile else {
            return DisplayArrangementResult(
                status: .noProfile,
                attemptedCount: 0,
                succeededCount: 0,
                missingDisplayNames: [],
                failedDisplayNames: [],
                completedAt: Date()
            )
        }

        guard !displays.isEmpty else {
            return DisplayArrangementResult(
                status: .noDisplays,
                attemptedCount: 0,
                succeededCount: 0,
                missingDisplayNames: [],
                failedDisplayNames: [],
                completedAt: Date()
            )
        }

        let displaysByFingerprint = Dictionary(
            grouping: displays,
            by: { DisplayFingerprint(display: $0).stableID }
        )
        var matchedTargets: [(display: DisplayDevice, placement: DisplayPlacement)] = []
        var missingDisplayNames: [String] = []

        for placement in profile.placements {
            guard let display = displaysByFingerprint[placement.id]?.first else {
                missingDisplayNames.append(placement.displayName)
                continue
            }

            matchedTargets.append((display, placement))
        }

        guard !matchedTargets.isEmpty else {
            return DisplayArrangementResult(
                status: .noMatches,
                attemptedCount: profile.placements.count,
                succeededCount: 0,
                missingDisplayNames: missingDisplayNames,
                failedDisplayNames: [],
                completedAt: Date()
            )
        }

        var configuration: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&configuration) == .success else {
            return DisplayArrangementResult(
                status: .failed,
                attemptedCount: matchedTargets.count,
                succeededCount: 0,
                missingDisplayNames: missingDisplayNames,
                failedDisplayNames: matchedTargets.map { $0.placement.displayName },
                completedAt: Date()
            )
        }

        var shouldCancelConfiguration = true
        defer {
            if shouldCancelConfiguration {
                CGCancelDisplayConfiguration(configuration)
            }
        }

        var configuredTargets: [(display: DisplayDevice, placement: DisplayPlacement)] = []
        var failedDisplayNames: [String] = []

        for target in matchedTargets {
            let result = CGConfigureDisplayOrigin(
                configuration,
                target.display.id,
                Int32(target.placement.frame.originX),
                Int32(target.placement.frame.originY)
            )

            if result == .success {
                configuredTargets.append(target)
            } else {
                failedDisplayNames.append(target.placement.displayName)
            }
        }

        guard !configuredTargets.isEmpty else {
            return DisplayArrangementResult(
                status: .failed,
                attemptedCount: matchedTargets.count,
                succeededCount: 0,
                missingDisplayNames: missingDisplayNames,
                failedDisplayNames: failedDisplayNames,
                completedAt: Date()
            )
        }

        let completionResult = CGCompleteDisplayConfiguration(configuration, CGConfigureOption(rawValue: 1))
        shouldCancelConfiguration = false

        guard completionResult == .success else {
            return DisplayArrangementResult(
                status: .failed,
                attemptedCount: matchedTargets.count,
                succeededCount: 0,
                missingDisplayNames: missingDisplayNames,
                failedDisplayNames: matchedTargets.map { $0.placement.displayName },
                completedAt: Date()
            )
        }

        let status: DisplayArrangementResult.Status =
            missingDisplayNames.isEmpty && failedDisplayNames.isEmpty && configuredTargets.count == matchedTargets.count
            ? .applied
            : .partial

        return DisplayArrangementResult(
            status: status,
            attemptedCount: matchedTargets.count,
            succeededCount: configuredTargets.count,
            missingDisplayNames: missingDisplayNames,
            failedDisplayNames: failedDisplayNames,
            completedAt: Date()
        )
    }

    func makePlacementProfile(
        rule: DisplayPlacementRule,
        targetPlacementIDs: Set<String>,
        displays: [DisplayDevice]
    ) -> DisplayLayoutProfile? {
        let snapshot = snapshot(displays: displays)
        guard let anchorPlacement = snapshot.mainPlacement else { return nil }

        var runningX = anchorPlacement.frame.originX
        var runningY = anchorPlacement.frame.originY
        var adjustedPlacements: [DisplayPlacement] = []

        for placement in snapshot.placements {
            guard targetPlacementIDs.contains(placement.id) else {
                adjustedPlacements.append(placement)
                continue
            }

            let adjustedFrame: DisplayFrame

            switch rule {
            case .rightOfMain:
                runningX = max(runningX, anchorPlacement.frame.maxX)
                adjustedFrame = placement.frame.moved(
                    toOriginX: runningX,
                    originY: anchorPlacement.frame.centerY - placement.frame.height / 2
                )
                runningX = adjustedFrame.maxX
            case .leftOfMain:
                runningX = min(runningX, anchorPlacement.frame.originX)
                adjustedFrame = placement.frame.moved(
                    toOriginX: runningX - placement.frame.width,
                    originY: anchorPlacement.frame.centerY - placement.frame.height / 2
                )
                runningX = adjustedFrame.originX
            case .aboveMain:
                runningY = min(runningY, anchorPlacement.frame.originY)
                adjustedFrame = placement.frame.moved(
                    toOriginX: anchorPlacement.frame.centerX - placement.frame.width / 2,
                    originY: runningY - placement.frame.height
                )
                runningY = adjustedFrame.originY
            case .belowMain:
                runningY = max(runningY, anchorPlacement.frame.maxY)
                adjustedFrame = placement.frame.moved(
                    toOriginX: anchorPlacement.frame.centerX - placement.frame.width / 2,
                    originY: runningY
                )
                runningY = adjustedFrame.maxY
            }

            adjustedPlacements.append(placement.moved(to: adjustedFrame))
        }

        return DisplayLayoutProfile(
            name: L10n.string("arrangement.profile.temporary_fit"),
            placements: adjustedPlacements
        )
    }
}
