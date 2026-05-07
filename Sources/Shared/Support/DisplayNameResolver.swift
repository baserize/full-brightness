import CoreGraphics
import Foundation

#if canImport(AppKit)
import AppKit
#endif

enum DisplayNameResolver {
    static func name(for displayID: CGDirectDisplayID, ioDisplayName: String?) -> String {
        if let screenName = screenName(for: displayID), !screenName.isEmpty {
            return screenName
        }

        if let ioDisplayName, !ioDisplayName.isEmpty {
            return ioDisplayName
        }

        if CGDisplayIsBuiltin(displayID) != 0 {
            return L10n.string("display.name.builtin")
        }

        let vendorID = CGDisplayVendorNumber(displayID)
        let productID = CGDisplayModelNumber(displayID)
        return L10n.string("display.name.fallback_format", vendorID, productID)
    }

    private static func screenName(for displayID: CGDirectDisplayID) -> String? {
#if canImport(AppKit)
        screenNameSnapshot()[displayID]
#else
        nil
#endif
    }

#if canImport(AppKit)
    private static func screenNameSnapshot() -> [CGDirectDisplayID: String] {
        let collect: @MainActor () -> [CGDirectDisplayID: String] = {
            Dictionary(uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
                guard let displayID = screen.displayID else { return nil }
                return (displayID, screen.localizedName)
            })
        }

        if Thread.isMainThread {
            return MainActor.assumeIsolated(collect)
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated(collect)
        }
    }
#endif
}

#if canImport(AppKit)
private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }

        return number.uint32Value
    }
}
#endif
