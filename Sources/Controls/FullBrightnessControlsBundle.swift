import SwiftUI
import WidgetKit

@main
struct FullBrightnessControlsBundle: WidgetBundle {
    var body: some Widget {
        SetAllDisplaysControl()
        AutoMaxBrightnessControl()
    }
}
