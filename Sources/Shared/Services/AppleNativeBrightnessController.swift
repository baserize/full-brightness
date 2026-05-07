import CoreGraphics
import Foundation

struct AppleNativeBrightnessController: Sendable {
    func readBrightness(displayID: CGDirectDisplayID) -> Float? {
        var brightness: Float = 0
        guard DisplayServicesGetBrightness(displayID, &brightness) == 0 else {
            return nil
        }

        return min(max(brightness, 0), 1)
    }

    @discardableResult
    func setBrightness(_ value: Float, displayID: CGDirectDisplayID) -> Bool {
        let clampedValue = min(max(value, 0), 1)
        return DisplayServicesSetBrightness(displayID, clampedValue) == 0
    }
}
