actor DisplayBrightnessClient {
    static let shared = DisplayBrightnessClient()

    private let controller = DisplayBrightnessController()

    func displays() -> [DisplayDevice] {
        controller.displays()
    }

    func setAllDisplaysToMaximum() -> BrightnessRunResult {
        controller.setAllDisplaysToMaximum()
    }
}
