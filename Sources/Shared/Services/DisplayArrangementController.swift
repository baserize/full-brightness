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
        displays: [DisplayDevice],
        offset: DisplayPlacementOffset = .zero
    ) -> DisplayLayoutProfile? {
        let instructionsByPlacementID = Dictionary(
            uniqueKeysWithValues: targetPlacementIDs.map { placementID in
                (placementID, DisplayPlacementInstruction(rule: rule, offset: offset))
            }
        )

        return makePlacementProfile(instructionsByPlacementID: instructionsByPlacementID, displays: displays)
    }

    func makePlacementProfile(
        instructionsByPlacementID: [String: DisplayPlacementInstruction],
        displays: [DisplayDevice]
    ) -> DisplayLayoutProfile? {
        let snapshot = snapshot(displays: displays)
        guard let anchorPlacement = snapshot.mainPlacement else { return nil }
        guard !instructionsByPlacementID.isEmpty else { return nil }

        var runningRightX = anchorPlacement.frame.maxX
        var runningLeftX = anchorPlacement.frame.originX
        var runningAboveY = anchorPlacement.frame.originY
        var runningBelowY = anchorPlacement.frame.maxY
        var adjustedPlacements: [DisplayPlacement] = []

        for placement in snapshot.placements {
            guard let instruction = instructionsByPlacementID[placement.id] else {
                adjustedPlacements.append(placement)
                continue
            }

            let adjustedFrame: DisplayFrame

            switch instruction.rule {
            case .rightOfMain:
                adjustedFrame = placement.frame.moved(
                    toOriginX: runningRightX,
                    originY: anchorPlacement.frame.centerY - placement.frame.height / 2
                )
                runningRightX = adjustedFrame.maxX
            case .leftOfMain:
                adjustedFrame = placement.frame.moved(
                    toOriginX: runningLeftX - placement.frame.width,
                    originY: anchorPlacement.frame.centerY - placement.frame.height / 2
                )
                runningLeftX = adjustedFrame.originX
            case .aboveMain:
                adjustedFrame = placement.frame.moved(
                    toOriginX: anchorPlacement.frame.centerX - placement.frame.width / 2,
                    originY: runningAboveY - placement.frame.height
                )
                runningAboveY = adjustedFrame.originY
            case .belowMain:
                adjustedFrame = placement.frame.moved(
                    toOriginX: anchorPlacement.frame.centerX - placement.frame.width / 2,
                    originY: runningBelowY
                )
                runningBelowY = adjustedFrame.maxY
            }

            let finalFrame = adjustedFrame.offsetBy(
                horizontal: instruction.offset.horizontal,
                vertical: instruction.offset.vertical
            )
            adjustedPlacements.append(placement.moved(to: finalFrame))
        }

        return DisplayLayoutProfile(
            name: L10n.string("arrangement.profile.temporary_fit"),
            placements: adjustedPlacements
        )
    }
}
