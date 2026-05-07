#if DIRECT_DISTRIBUTION
import CoreGraphics
import Darwin
import Foundation

struct PrivateDisplayServicesBrightnessController: Sendable {
    func readBrightness(displayID: CGDirectDisplayID) -> Float? {
        guard let getBrightness = DisplayServicesSymbols.shared.getBrightness else {
            return nil
        }

        var brightness: Float = 0
        guard getBrightness(displayID, &brightness) == 0, brightness.isFinite else {
            return nil
        }

        return clamp(brightness)
    }

    @discardableResult
    func setBrightness(_ value: Float, displayID: CGDirectDisplayID) -> Bool {
        guard let setBrightness = DisplayServicesSymbols.shared.setBrightness else {
            return false
        }

        return setBrightness(displayID, clamp(value)) == 0
    }

    private func clamp(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}

private final class DisplayServicesSymbols: @unchecked Sendable {
    typealias GetBrightnessFunction = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> CInt
    typealias SetBrightnessFunction = @convention(c) (CGDirectDisplayID, Float) -> CInt

    static let shared = DisplayServicesSymbols()

    let getBrightness: GetBrightnessFunction?
    let setBrightness: SetBrightnessFunction?

    private let handle: UnsafeMutableRawPointer?

    private init() {
        handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW | RTLD_LOCAL)
        getBrightness = Self.loadSymbol("DisplayServicesGetBrightness", from: handle)
        setBrightness = Self.loadSymbol("DisplayServicesSetBrightness", from: handle)
    }

    deinit {
        if let handle {
            dlclose(handle)
        }
    }

    private static func loadSymbol<Function>(_ name: String, from handle: UnsafeMutableRawPointer?) -> Function? {
        guard let handle, let symbol = dlsym(handle, name) else {
            return nil
        }

        return unsafeBitCast(symbol, to: Function.self)
    }
}
#endif
