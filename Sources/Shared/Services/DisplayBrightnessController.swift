import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

struct DisplayBrightnessController: Sendable {
    private struct ControlTarget {
        let device: DisplayDevice
        let ioDisplayService: DisplayServiceMatch?
    }

#if DIRECT_DISTRIBUTION
    private let privateDisplayServicesController = PrivateDisplayServicesBrightnessController()
#endif

    func displays() -> [DisplayDevice] {
        controlTargets().map(\.device)
    }

    @discardableResult
    func setAllDisplays(to targetBrightness: Float) -> BrightnessRunResult {
        let normalizedBrightness = min(max(targetBrightness, 0), 1)
        let targetPercent = Int((normalizedBrightness * 100).rounded())

        let adjustableTargets = controlTargets().filter(\.device.isBrightnessAdjustable)
        var succeededCount = 0
        var failedDisplays: [String] = []

        for target in adjustableTargets {
            guard setBrightness(normalizedBrightness, using: target) else {
                failedDisplays.append(target.device.name)
                continue
            }

            succeededCount += 1
        }

        return BrightnessRunResult(
            attemptedCount: adjustableTargets.count,
            succeededCount: succeededCount,
            failedDisplays: failedDisplays,
            targetPercent: targetPercent,
            completedAt: Date()
        )
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

    private func controlTargets() -> [ControlTarget] {
        let displayIDs = onlineDisplayIDs()

        return DisplayServiceMatcher.withConnectedServices { services in
            displayIDs.map { displayID in
                makeControlTarget(
                    displayID: displayID,
                    ioDisplayService: DisplayServiceMatcher.service(for: displayID, in: services)
                )
            }
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
        ioDisplayService: DisplayServiceMatch?
    ) -> ControlTarget {
        let backend: DisplayDevice.BrightnessBackend
        let brightness: Float?

#if DIRECT_DISTRIBUTION
        if let displayServicesBrightness = privateDisplayServicesController.readBrightness(displayID: displayID) {
            backend = .displayServices
            brightness = displayServicesBrightness
        } else if let ioDisplayBrightness = ioDisplayService.flatMap({ readBrightness(service: $0.service) }) {
            backend = .ioDisplay
            brightness = ioDisplayBrightness
        } else {
            backend = .none
            brightness = nil
        }
#else
        if let ioDisplayBrightness = ioDisplayService.flatMap({ readBrightness(service: $0.service) }) {
            backend = .ioDisplay
            brightness = ioDisplayBrightness
        } else {
            backend = .none
            brightness = nil
        }
#endif

        let device = DisplayDevice(
            id: displayID,
            name: DisplayNameResolver.name(for: displayID, ioDisplayName: ioDisplayService?.name),
            vendorID: CGDisplayVendorNumber(displayID),
            productID: CGDisplayModelNumber(displayID),
            serialNumber: CGDisplaySerialNumber(displayID),
            isBuiltin: CGDisplayIsBuiltin(displayID) != 0,
            resolution: displayResolution(displayID: displayID),
            brightness: brightness,
            brightnessBackend: backend
        )

        return ControlTarget(
            device: device,
            ioDisplayService: ioDisplayService
        )
    }

    private func setBrightness(_ value: Float, using target: ControlTarget) -> Bool {
        switch target.device.brightnessBackend {
        case .ioDisplay:
            guard let ioDisplayService = target.ioDisplayService else { return false }
            return setBrightness(value, service: ioDisplayService.service)
        case .displayServices:
#if DIRECT_DISTRIBUTION
            return privateDisplayServicesController.setBrightness(value, displayID: target.device.id)
#else
            return false
#endif
        case .none:
            return false
        }
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
