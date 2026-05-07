import CoreGraphics
import Foundation

final class DisplayConnectionMonitor: @unchecked Sendable {
    typealias Handler = @MainActor (CGDirectDisplayID, CGDisplayChangeSummaryFlags) -> Void

    private let handler: Handler

    init(handler: @escaping Handler) {
        self.handler = handler
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }

    fileprivate func handle(displayID: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags) {
        Task { @MainActor in
            handler(displayID, flags)
        }
    }
}

private let displayReconfigurationCallback: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
    guard let userInfo else { return }
    let monitor = Unmanaged<DisplayConnectionMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    monitor.handle(displayID: displayID, flags: flags)
}
