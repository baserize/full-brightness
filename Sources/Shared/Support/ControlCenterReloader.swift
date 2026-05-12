import WidgetKit

enum ControlCenterReloader {
    static func reloadBrightnessControls() {
        ControlCenter.shared.reloadControls(ofKind: AppConstants.controlKindSetFullLevel)
        ControlCenter.shared.reloadControls(ofKind: AppConstants.controlKindAutoFullMode)
    }
}
