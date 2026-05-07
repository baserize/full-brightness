import Foundation

struct BrightnessRunResult: Equatable, Sendable {
    let attemptedCount: Int
    let succeededCount: Int
    let failedDisplays: [String]
    let completedAt: Date

    var summaryText: String {
        if attemptedCount == 0 {
            return L10n.string("brightness.result.none")
        }

        if failedDisplays.isEmpty {
            return L10n.string("brightness.result.success_format", succeededCount)
        }

        return L10n.string("brightness.result.partial_format", succeededCount, attemptedCount)
    }
}
