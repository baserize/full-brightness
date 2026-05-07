import Foundation
import IOKit
import IOKit.i2c

struct DDCBrightnessController: Sendable {
    struct BrightnessValue: Sendable {
        let current: UInt16
        let maximum: UInt16

        var normalized: Float? {
            guard maximum > 0 else { return nil }
            return min(max(Float(current) / Float(maximum), 0), 1)
        }
    }

    func readBrightness(framebuffer: io_service_t) -> BrightnessValue? {
        for interface in interfaces(framebuffer: framebuffer) {
            defer { IOObjectRelease(interface) }

            if let value = readBrightness(interface: interface) {
                return value
            }
        }

        return nil
    }

    @discardableResult
    func setBrightnessToMaximum(framebuffer: io_service_t) -> Bool {
        for interface in interfaces(framebuffer: framebuffer) {
            defer { IOObjectRelease(interface) }

            let maximum = readBrightness(interface: interface)?.maximum ?? 100
            if setBrightness(maximum, interface: interface) {
                return true
            }
        }

        return false
    }

    private func interfaces(framebuffer: io_service_t) -> [io_service_t] {
        var count: IOItemCount = 0
        guard IOFBGetI2CInterfaceCount(framebuffer, &count) == kIOReturnSuccess, count > 0 else {
            return []
        }

        var interfaces: [io_service_t] = []

        for bus in 0..<count {
            var interface: io_service_t = 0
            let result = IOFBCopyI2CInterfaceForBus(framebuffer, IOOptionBits(bus), &interface)
            if result == kIOReturnSuccess, interface != 0 {
                interfaces.append(interface)
            }
        }

        return interfaces
    }

    private func readBrightness(interface: io_service_t) -> BrightnessValue? {
        let command = ddcMessage(payload: [0x01, 0x10])
        guard let reply = send(command: command, replyByteCount: 16, interface: interface) else {
            return nil
        }

        return parseBrightnessReply(reply)
    }

    private func setBrightness(_ value: UInt16, interface: io_service_t) -> Bool {
        let high = UInt8((value >> 8) & 0xff)
        let low = UInt8(value & 0xff)
        let command = ddcMessage(payload: [0x03, 0x10, high, low])
        return send(command: command, replyByteCount: 0, interface: interface) != nil
    }

    private func send(command: [UInt8], replyByteCount: Int, interface: io_service_t) -> [UInt8]? {
        var connection: IOI2CConnectRef?
        guard IOI2CInterfaceOpen(interface, IOOptionBits(0), &connection) == kIOReturnSuccess,
              let connection else {
            return nil
        }

        defer {
            IOI2CInterfaceClose(connection, IOOptionBits(0))
        }

        var request = IOI2CRequest()
        request.sendAddress = 0x6e
        request.sendTransactionType = UInt32(kIOI2CSimpleTransactionType)
        request.sendBytes = UInt32(command.count)
        request.minReplyDelay = 40

        if replyByteCount > 0 {
            request.replyAddress = 0x6f
            request.replyTransactionType = UInt32(kIOI2CDDCciReplyTransactionType)
            request.replyBytes = UInt32(replyByteCount)
        }

        var mutableCommand = command
        var reply = Array(repeating: UInt8(0), count: max(replyByteCount, 1))
        let sendResult = mutableCommand.withUnsafeMutableBytes { sendBuffer in
            reply.withUnsafeMutableBytes { replyBuffer in
                guard let sendBaseAddress = sendBuffer.baseAddress,
                      let replyBaseAddress = replyBuffer.baseAddress else {
                    return kIOReturnBadArgument
                }

                request.sendBuffer = vm_address_t(UInt(bitPattern: sendBaseAddress))
                request.replyBuffer = vm_address_t(UInt(bitPattern: replyBaseAddress))
                return IOI2CSendRequest(connection, IOOptionBits(0), &request)
            }
        }

        guard sendResult == kIOReturnSuccess, request.result == kIOReturnSuccess else {
            return nil
        }

        return replyByteCount == 0 ? [] : reply
    }

    private func ddcMessage(payload: [UInt8]) -> [UInt8] {
        var message = [UInt8(0x51), UInt8(0x80 | payload.count)]
        message.append(contentsOf: payload)
        message.append(checksum(address: 0x6e, bytes: message))
        return message
    }

    private func checksum(address: UInt8, bytes: [UInt8]) -> UInt8 {
        bytes.reduce(address) { partial, byte in
            partial ^ byte
        }
    }

    private func parseBrightnessReply(_ reply: [UInt8]) -> BrightnessValue? {
        guard reply.count >= 8 else { return nil }

        for index in 0...(reply.count - 8) {
            guard reply[index] == 0x02, reply[index + 2] == 0x10 else {
                continue
            }

            let maximum = UInt16(reply[index + 4]) << 8 | UInt16(reply[index + 5])
            let current = UInt16(reply[index + 6]) << 8 | UInt16(reply[index + 7])

            guard maximum > 0 else { return nil }
            return BrightnessValue(current: current, maximum: maximum)
        }

        return nil
    }
}
