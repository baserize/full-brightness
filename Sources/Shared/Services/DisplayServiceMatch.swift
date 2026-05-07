import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

struct DisplayServiceMatch: Sendable {
    let service: io_service_t
    let vendorID: UInt32
    let productID: UInt32
    let serialNumber: UInt32
    let name: String?
}

enum DisplayServiceMatcher {
    static func withConnectedServices<T>(_ body: ([DisplayServiceMatch]) throws -> T) rethrows -> T {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
        guard result == kIOReturnSuccess else {
            return try body([])
        }

        defer {
            IOObjectRelease(iterator)
        }

        var matches: [DisplayServiceMatch] = []
        var service = IOIteratorNext(iterator)

        while service != 0 {
            if let match = makeMatch(service: service) {
                matches.append(match)
            } else {
                IOObjectRelease(service)
            }

            service = IOIteratorNext(iterator)
        }

        defer {
            for match in matches {
                IOObjectRelease(match.service)
            }
        }

        return try body(matches)
    }

    static func service(for displayID: CGDirectDisplayID, in services: [DisplayServiceMatch]) -> DisplayServiceMatch? {
        let vendorID = CGDisplayVendorNumber(displayID)
        let productID = CGDisplayModelNumber(displayID)
        let serialNumber = CGDisplaySerialNumber(displayID)

        if serialNumber != 0,
           let exact = services.first(where: {
               $0.vendorID == vendorID && $0.productID == productID && $0.serialNumber == serialNumber
           }) {
            return exact
        }

        return services.first {
            $0.vendorID == vendorID && $0.productID == productID
        }
    }

    private static func makeMatch(service: io_service_t) -> DisplayServiceMatch? {
        guard let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName))?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        let vendorID = numberValue(info[kDisplayVendorID as String])
        let productID = numberValue(info[kDisplayProductID as String])
        let serialNumber = numberValue(info[kDisplaySerialNumber as String])

        return DisplayServiceMatch(
            service: service,
            vendorID: vendorID,
            productID: productID,
            serialNumber: serialNumber,
            name: displayName(from: info)
        )
    }

    private static func numberValue(_ value: Any?) -> UInt32 {
        switch value {
        case let value as UInt32:
            value
        case let value as UInt64:
            UInt32(clamping: value)
        case let value as UInt:
            UInt32(clamping: value)
        case let value as Int64:
            UInt32(clamping: value)
        case let value as Int:
            UInt32(clamping: value)
        case let value as NSNumber:
            value.uint32Value
        default:
            0
        }
    }

    private static func displayName(from info: [String: Any]) -> String? {
        guard let names = info[kDisplayProductName as String] as? [String: String], !names.isEmpty else {
            return nil
        }

        return LocalizedDisplayName.preferred(from: names)
    }
}
