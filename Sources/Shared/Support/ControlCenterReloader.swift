import WidgetKit

enum ControlCenterReloader {
    static func reloadBrightnessControls() {
        ControlCenter.shared.reloadControls(ofKind: AppConstants.controlKindSetAll)
        ControlCenter.shared.reloadControls(ofKind: AppConstants.controlKindAutoMode)
    }
}
