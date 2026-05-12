import SwiftUI
import WidgetKit

struct SetAllDisplaysControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: AppConstants.controlKindSetFullLevel) {
            ControlWidgetButton(action: SetDisplaysToFullLevelIntent()) {
                Label("action.set_all.short", systemImage: "sun.max.fill")
            }
        }
        .displayName("control.set_all.display_name")
        .description("control.set_all.description")
    }
}

struct AutoFitBrightnessControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: AppConstants.controlKindAutoFullMode, provider: AutoModeValueProvider()) { isOn in
            ControlWidgetToggle(isOn: isOn, action: SetAutoFullLevelIntent()) {
                Label("control.auto.label", systemImage: isOn ? "sun.max.fill" : "sun.max")
            } valueLabel: { isOn in
                if isOn {
                    Text("control.state.on")
                } else {
                    Text("control.state.off")
                }
            }
        }
        .displayName("control.auto.display_name")
        .description("control.auto.description")
    }
}

struct AutoModeValueProvider: ControlValueProvider {
    var previewValue: Bool { true }

    func currentValue() async throws -> Bool {
        BrightnessPreferences().autoFullEnabled
    }
}
