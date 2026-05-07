import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

struct DisplayBrightnessController: Sendable {
    private struct ControlTarget {
        let displayID: CGDirectDisplayID
        let device: DisplayDevice
        let ioDisplayService: DisplayServiceMatch?
        let appleSiliconService: AppleSiliconDDCServiceMatch?
    }

    private let appleNativeBrightnessController = AppleNativeBrightnessController()
    private let appleSiliconDDCController = AppleSiliconDDCController()
    private let ddcBrightnessController = DDCBrightnessController()

    func displays() -> [DisplayDevice] {
        withControlTargets { targets in
            targets.map(\.device)
        }
    }

    @discardableResult
    func setAllDisplaysToMaximum() -> BrightnessRunResult {
        withControlTargets { targets in
            let adjustableTargets = targets.filter(\.device.isBrightnessAdjustable)
            var succeededCount = 0
            var failedDisplays: [String] = []

            for target in adjustableTargets {
                guard setMaximumBrightness(using: target) else {
                    failedDisplays.append(target.device.name)
                    continue
                }

                succeededCount += 1
            }

            return BrightnessRunResult(
                attemptedCount: adjustableTargets.count,
                succeededCount: succeededCount,
                failedDisplays: failedDisplays,
                completedAt: Date()
            )
        }
    }

    private func readBrightness(service: io_service_t) -> Float? {
        var value: Float = 0
        let result = IODisplayGetFloatParameter(service, IOOptionBits(0), kIODisplayBrightnessKey as CFString, &value)
        guard result == kIOReturnSuccess else { return nil }
        return min(max(value, 0), 1)
    }

    @discardableResult
    private func setBrightness(_ value: Float, service: io_service_t) -> Bool {
        let clampedValue = min(max(value, 0), 1)
        let result = IODisplaySetFloatParameter(service, IOOptionBits(0), kIODisplayBrightnessKey as CFString, clampedValue)
        guard result == kIOReturnSuccess else { return false }
        _ = IODisplayCommitParameters(service, IOOptionBits(0))
        return true
    }

    private func withControlTargets<T>(_ body: ([ControlTarget]) throws -> T) rethrows -> T {
        let displayIDs = onlineDisplayIDs()

        return try DisplayServiceMatcher.withConnectedServices { services in
            var targets = displayIDs.map { displayID in
                makeControlTarget(
                    displayID: displayID,
                    ioDisplayService: DisplayServiceMatcher.service(for: displayID, in: services),
                    appleSiliconService: nil,
                    includesDDCBackends: false
                )
            }

            let ddcCandidateIDs = targets
                .filter { !$0.device.isBuiltin && !$0.device.isBrightnessAdjustable }
                .map(\.displayID)

            if !ddcCandidateIDs.isEmpty {
                let ddcCandidateIDSet = Set(ddcCandidateIDs)
                let fastTargetsByID = Dictionary(uniqueKeysWithValues: targets.map { ($0.displayID, $0) })
                let appleSiliconServices = appleSiliconDDCController.serviceMatches(for: ddcCandidateIDs)

                targets = displayIDs.compactMap { displayID in
                    guard ddcCandidateIDSet.contains(displayID) else {
                        return fastTargetsByID[displayID]
                    }

                    return makeControlTarget(
                        displayID: displayID,
                        ioDisplayService: DisplayServiceMatcher.service(for: displayID, in: services),
                        appleSiliconService: appleSiliconServices[displayID],
                        includesDDCBackends: true
                    )
                }
            }

            return try body(targets)
        }
    }

    private func onlineDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        var displayIDs = Array(repeating: CGDirectDisplayID(0), count: 32)
        let result = CGGetOnlineDisplayList(UInt32(displayIDs.count), &displayIDs, &count)
        guard result == .success else { return [] }

        return Array(displayIDs.prefix(Int(count)))
    }

    private func makeControlTarget(
        displayID: CGDirectDisplayID,
        ioDisplayService: DisplayServiceMatch?,
        appleSiliconService: AppleSiliconDDCServiceMatch?,
        includesDDCBackends: Bool
    ) -> ControlTarget {
        let backend: DisplayDevice.BrightnessBackend
        let brightness: Float?

        if let appleNativeBrightness = appleNativeBrightnessController.readBrightness(displayID: displayID) {
            backend = .appleNative
            brightness = appleNativeBrightness
        } else if let ioDisplayBrightness = ioDisplayService.flatMap({ readBrightness(service: $0.service) }) {
            backend = .ioDisplay
            brightness = ioDisplayBrightness
        } else if includesDDCBackends, appleSiliconService?.service != nil {
            backend = .appleSiliconDDC
            brightness = appleSiliconService.flatMap {
                appleSiliconDDCController.readBrightness(service: $0.service)?.normalized
            }
        } else if includesDDCBackends, let ddcBrightness = ioDisplayService?.framebuffer.flatMap({
            ddcBrightnessController.readBrightness(framebuffer: $0)?.normalized
        }) {
            backend = .ddcCI
            brightness = ddcBrightness
        } else {
            backend = .none
            brightness = nil
        }

        let device = DisplayDevice(
            id: displayID,
            name: displayName(
                displayID: displayID,
                ioDisplayService: ioDisplayService,
                appleSiliconService: appleSiliconService
            ),
            vendorID: CGDisplayVendorNumber(displayID),
            productID: CGDisplayModelNumber(displayID),
            serialNumber: CGDisplaySerialNumber(displayID),
            isBuiltin: CGDisplayIsBuiltin(displayID) != 0,
            resolution: displayResolution(displayID: displayID),
            brightness: brightness,
            brightnessBackend: backend
        )

        return ControlTarget(
            displayID: displayID,
            device: device,
            ioDisplayService: ioDisplayService,
            appleSiliconService: appleSiliconService
        )
    }

    private func setMaximumBrightness(using target: ControlTarget) -> Bool {
        if target.device.brightnessBackend == .appleNative,
           appleNativeBrightnessController.setBrightness(1.0, displayID: target.displayID) {
            return true
        }

        if let ioDisplayService = target.ioDisplayService,
           target.device.brightnessBackend == .ioDisplay,
           setBrightness(1.0, service: ioDisplayService.service) {
            return true
        }

        if target.device.brightnessBackend == .appleSiliconDDC,
           appleSiliconDDCController.setBrightnessToMaximum(service: target.appleSiliconService?.service) {
            return true
        }

        if target.device.brightnessBackend == .ddcCI,
           let framebuffer = target.ioDisplayService?.framebuffer,
           ddcBrightnessController.setBrightnessToMaximum(framebuffer: framebuffer) {
            return true
        }

        return setMaximumBrightnessUsingFallbacks(target)
    }

    private func setMaximumBrightnessUsingFallbacks(_ target: ControlTarget) -> Bool {
        if appleNativeBrightnessController.setBrightness(1.0, displayID: target.displayID) {
            return true
        }

        if let service = target.ioDisplayService?.service,
           setBrightness(1.0, service: service) {
            return true
        }

        let appleSiliconService = target.appleSiliconService
            ?? appleSiliconDDCController.serviceMatches(for: [target.displayID])[target.displayID]

        if appleSiliconDDCController.setBrightnessToMaximum(service: appleSiliconService?.service) {
            return true
        }

        guard let framebuffer = target.ioDisplayService?.framebuffer else {
            return false
        }

        return ddcBrightnessController.setBrightnessToMaximum(framebuffer: framebuffer)
    }

    private func displayName(
        displayID: CGDirectDisplayID,
        ioDisplayService: DisplayServiceMatch?,
        appleSiliconService: AppleSiliconDDCServiceMatch?
    ) -> String {
        if let name = ioDisplayService?.name, !name.isEmpty {
            return name
        }

        if CGDisplayIsBuiltin(displayID) != 0 {
            return L10n.string("display.name.builtin")
        }

        if let name = coreDisplayName(displayID: displayID), !name.isEmpty {
            return name
        }

        if let name = appleSiliconService?.productName, !name.isEmpty {
            return name
        }

        let vendorID = CGDisplayVendorNumber(displayID)
        let productID = CGDisplayModelNumber(displayID)
        return L10n.string("display.name.fallback_format", vendorID, productID)
    }

    private func coreDisplayName(displayID: CGDirectDisplayID) -> String? {
        guard let info = CoreDisplay_DisplayCreateInfoDictionary(displayID)?.takeRetainedValue() as? NSDictionary,
              let names = info["DisplayProductName"] as? [String: String] else {
            return nil
        }

        return LocalizedDisplayName.preferred(from: names)
    }

    private func displayResolution(displayID: CGDirectDisplayID) -> DisplayDevice.Resolution {
        if let mode = CGDisplayCopyDisplayMode(displayID) {
            let logicalWidth = mode.width
            let logicalHeight = mode.height

            return DisplayDevice.Resolution(
                logicalWidth: logicalWidth,
                logicalHeight: logicalHeight,
                backingPixelWidth: mode.pixelWidth > 0 ? mode.pixelWidth : logicalWidth,
                backingPixelHeight: mode.pixelHeight > 0 ? mode.pixelHeight : logicalHeight,
                refreshRate: mode.refreshRate > 0 ? mode.refreshRate : nil
            )
        }

        let width = CGDisplayPixelsWide(displayID)
        let height = CGDisplayPixelsHigh(displayID)

        return DisplayDevice.Resolution(
            logicalWidth: width,
            logicalHeight: height,
            backingPixelWidth: width,
            backingPixelHeight: height,
            refreshRate: nil
        )
    }
}
