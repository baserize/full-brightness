import SwiftUI
import WidgetKit

@main
struct DisplayFitControlsBundle: WidgetBundle {
    var body: some Widget {
        SetAllDisplaysControl()
        AutoFitBrightnessControl()
    }
}
