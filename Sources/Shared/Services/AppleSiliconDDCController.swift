import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

struct AppleSiliconDDCServiceMatch {
    let displayID: CGDirectDisplayID
    let service: IOAVService?
    let serviceLocation: Int
    let productName: String?
}

struct AppleSiliconDDCController: Sendable {
    private struct IORegDisplayService {
        var productName: String?
        var legacyManufacturerID: UInt32 = 0
        var productID: UInt32 = 0
        var serialNumber: UInt32 = 0
        var location: String?
        var service: IOAVService?
        var serviceLocation: Int = 0
    }

    private let ddcAddress: UInt8 = 0x37
    private let dataAddress: UInt8 = 0x51
    private let brightnessCommand: UInt8 = 0x10

    func serviceMatches(for displayIDs: [CGDirectDisplayID]) -> [CGDirectDisplayID: AppleSiliconDDCServiceMatch] {
        let ioregServices = ioregServicesForMatching()
        guard !ioregServices.isEmpty else { return [:] }

        var candidatesByScore: [Int: [AppleSiliconDDCServiceMatch]] = [:]

        for displayID in displayIDs where CGDisplayIsBuiltin(displayID) == 0 {
            for ioregService in ioregServices {
                let score = matchScore(displayID: displayID, ioregService: ioregService)
                guard score > 0 else { continue }

                let match = AppleSiliconDDCServiceMatch(
                    displayID: displayID,
                    service: ioregService.service,
                    serviceLocation: ioregService.serviceLocation,
                    productName: ioregService.productName
                )
                candidatesByScore[score, default: []].append(match)
            }
        }

        var usedDisplayIDs = Set<CGDirectDisplayID>()
        var usedServiceLocations = Set<Int>()
        var matches: [CGDirectDisplayID: AppleSiliconDDCServiceMatch] = [:]

        for score in candidatesByScore.keys.sorted(by: >) {
            for candidate in candidatesByScore[score, default: []] {
                guard !usedDisplayIDs.contains(candidate.displayID),
                      !usedServiceLocations.contains(candidate.serviceLocation) else {
                    continue
                }

                usedDisplayIDs.insert(candidate.displayID)
                usedServiceLocations.insert(candidate.serviceLocation)
                matches[candidate.displayID] = candidate
            }
        }

        return matches
    }

    func readBrightness(service: IOAVService?) -> DDCBrightnessController.BrightnessValue? {
        var send: [UInt8] = [brightnessCommand]
        var reply = [UInt8](repeating: 0, count: 11)

        guard performDDCCommunication(service: service, send: &send, reply: &reply) else {
            return nil
        }

        let maximum = UInt16(reply[6]) << 8 | UInt16(reply[7])
        let current = UInt16(reply[8]) << 8 | UInt16(reply[9])
        guard maximum > 0 else { return nil }

        return DDCBrightnessController.BrightnessValue(current: current, maximum: maximum)
    }

    @discardableResult
    func setBrightnessToMaximum(service: IOAVService?) -> Bool {
        let maximum = readBrightness(service: service)?.maximum ?? 100
        return setBrightness(maximum, service: service)
    }

    @discardableResult
    func setBrightness(_ value: UInt16, service: IOAVService?) -> Bool {
        let high = UInt8((value >> 8) & 0xff)
        let low = UInt8(value & 0xff)
        var send: [UInt8] = [brightnessCommand, high, low]
        var reply: [UInt8] = []

        return performDDCCommunication(service: service, send: &send, reply: &reply)
    }

    private func performDDCCommunication(
        service: IOAVService?,
        send: inout [UInt8],
        reply: inout [UInt8],
        writeSleepTime: UInt32 = 10_000,
        readSleepTime: UInt32 = 50_000,
        retrySleepTime: UInt32 = 20_000,
        retryAttempts: Int = 4
    ) -> Bool {
        guard let service else { return false }

        var packet = [UInt8(0x80 | (send.count + 1)), UInt8(send.count)] + send + [0]
        let checksumSeed = send.count == 1 ? ddcAddress << 1 : (ddcAddress << 1) ^ dataAddress
        packet[packet.count - 1] = checksum(seed: checksumSeed, data: packet, start: 0, end: packet.count - 2)

        for _ in 0...retryAttempts {
            var writeSucceeded = false

            for _ in 0..<2 {
                usleep(writeSleepTime)
                let packetCount = UInt32(packet.count)
                writeSucceeded = packet.withUnsafeMutableBytes { buffer in
                    guard let baseAddress = buffer.baseAddress else { return false }
                    return IOAVServiceWriteI2C(
                        service,
                        UInt32(ddcAddress),
                        UInt32(dataAddress),
                        baseAddress,
                        packetCount
                    ) == 0
                }
            }

            guard writeSucceeded else {
                usleep(retrySleepTime)
                continue
            }

            guard !reply.isEmpty else { return true }

            usleep(readSleepTime)
            if readReply(service: service, reply: &reply) {
                return true
            }

            usleep(retrySleepTime)
        }

        return false
    }

    private func readReply(service: IOAVService, reply: inout [UInt8]) -> Bool {
        for offset in [dataAddress, UInt8(0)] {
            let replyCount = UInt32(reply.count)
            let result = reply.withUnsafeMutableBytes { buffer in
                guard let baseAddress = buffer.baseAddress else { return kIOReturnBadArgument }
                return IOAVServiceReadI2C(
                    service,
                    UInt32(ddcAddress),
                    UInt32(offset),
                    baseAddress,
                    replyCount
                )
            }

            guard result == 0, reply.count >= 2 else { continue }
            let expectedChecksum = checksum(seed: 0x50, data: reply, start: 0, end: reply.count - 2)
            if expectedChecksum == reply[reply.count - 1] {
                return true
            }
        }

        return false
    }

    private func checksum(seed: UInt8, data: [UInt8], start: Int, end: Int) -> UInt8 {
        guard start <= end else { return seed }
        var value = seed

        for index in start...end {
            value ^= data[index]
        }

        return value
    }

    private func ioregServicesForMatching() -> [IORegDisplayService] {
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        guard root != IO_OBJECT_NULL else { return [] }
        defer { IOObjectRelease(root) }

        var iterator: io_iterator_t = 0
        guard IORegistryEntryCreateIterator(
            root,
            kIOServicePlane,
            IOOptionBits(kIORegistryIterateRecursively),
            &iterator
        ) == kIOReturnSuccess else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        let framebufferNames = ["AppleCLCD2", "IOMobileFramebufferShim"]
        var displayServices: [IORegDisplayService] = []
        var currentDisplayService = IORegDisplayService()
        var serviceLocation = 0

        while let object = nextObject(namedLike: framebufferNames + ["DCPAVServiceProxy"], iterator: &iterator) {
            defer { IOObjectRelease(object.entry) }

            if framebufferNames.contains(where: { object.name.contains($0) }) {
                currentDisplayService = makeDisplayService(framebuffer: object.entry)
                serviceLocation += 1
                currentDisplayService.serviceLocation = serviceLocation
                continue
            }

            guard object.name.contains("DCPAVServiceProxy") else { continue }
            setDCPService(entry: object.entry, displayService: &currentDisplayService)

            if currentDisplayService.location == "External", currentDisplayService.service != nil {
                displayServices.append(currentDisplayService)
            }
        }

        return displayServices
    }

    private func nextObject(
        namedLike names: [String],
        iterator: inout io_iterator_t
    ) -> (name: String, entry: io_service_t)? {
        while true {
            let entry = IOIteratorNext(iterator)
            guard entry != IO_OBJECT_NULL else { return nil }

            var nameBuffer = [CChar](repeating: 0, count: MemoryLayout<io_name_t>.size)
            guard IORegistryEntryGetName(entry, &nameBuffer) == kIOReturnSuccess else {
                IOObjectRelease(entry)
                continue
            }

            let nameBytes = nameBuffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
            let name = String(decoding: nameBytes, as: UTF8.self)
            if names.contains(where: { name.contains($0) }) {
                return (name, entry)
            }

            IOObjectRelease(entry)
        }
    }

    private func makeDisplayService(framebuffer: io_service_t) -> IORegDisplayService {
        var displayService = IORegDisplayService()

        guard let displayAttributes = cfProperty("DisplayAttributes", entry: framebuffer) as? NSDictionary,
              let productAttributes = displayAttributes["ProductAttributes"] as? NSDictionary else {
            return displayService
        }

        displayService.productName = productAttributes["ProductName"] as? String
        displayService.legacyManufacturerID = numberValue(productAttributes["LegacyManufacturerID"])
        displayService.productID = numberValue(productAttributes["ProductID"])
        displayService.serialNumber = numberValue(productAttributes["SerialNumber"])

        return displayService
    }

    private func setDCPService(entry: io_service_t, displayService: inout IORegDisplayService) {
        guard let location = cfProperty("Location", entry: entry) as? String else {
            return
        }

        displayService.location = location
        guard location == "External" else { return }

        displayService.service = IOAVServiceCreateWithService(kCFAllocatorDefault, entry)?.takeRetainedValue()
    }

    private func matchScore(displayID: CGDirectDisplayID, ioregService: IORegDisplayService) -> Int {
        var score = 0

        if ioregService.legacyManufacturerID != 0,
           ioregService.legacyManufacturerID == CGDisplayVendorNumber(displayID) {
            score += 3
        }

        if ioregService.productID != 0,
           ioregService.productID == CGDisplayModelNumber(displayID) {
            score += 3
        }

        if ioregService.serialNumber != 0,
           ioregService.serialNumber == CGDisplaySerialNumber(displayID) {
            score += 4
        }

        if let productName = ioregService.productName,
           !productName.isEmpty,
           displayName(displayID: displayID)?.localizedCaseInsensitiveContains(productName) == true {
            score += 1
        }

        return score
    }

    private func displayName(displayID: CGDirectDisplayID) -> String? {
        guard let info = CoreDisplay_DisplayCreateInfoDictionary(displayID)?.takeRetainedValue() as? NSDictionary,
              let names = info["DisplayProductName"] as? [String: String] else {
            return nil
        }

        return LocalizedDisplayName.preferred(from: names)
    }

    private func cfProperty(_ key: String, entry: io_registry_entry_t) -> Any? {
        IORegistryEntryCreateCFProperty(
            entry,
            key as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively)
        )?.takeRetainedValue()
    }

    private func numberValue(_ value: Any?) -> UInt32 {
        switch value {
        case let value as UInt32:
            value
        case let value as UInt64:
            UInt32(clamping: value)
        case let value as UInt:
            UInt32(clamping: value)
        case let value as Int:
            UInt32(clamping: value)
        case let value as Int64:
            UInt32(clamping: value)
        case let value as NSNumber:
            value.uint32Value
        default:
            0
        }
    }
}
