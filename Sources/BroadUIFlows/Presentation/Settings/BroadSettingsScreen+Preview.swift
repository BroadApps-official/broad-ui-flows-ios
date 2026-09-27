import BroadCore
import Foundation

public extension BroadSettingsScreen {
    /// Network-free fixture states for Xcode previews and Gallery.
    enum PreviewState: CaseIterable, Sendable {
        case ready
        case restoring
        case restored
        case nothingToRestore
        case failed
    }

    /// A settings fixture whose actions do nothing.
    static func preview(_ state: PreviewState = .ready) -> BroadSettingsScreen {
        let result: BroadSettingsRestoreResult?
        let message: String?
        switch state {
        case .ready, .restoring:
            result = nil
            message = nil
        case .restored:
            result = .restored
            message = "Purchases restored."
        case .nothingToRestore:
            result = .nothingToRestore
            message = "No purchases were found to restore."
        case .failed:
            result = .failed(AppError(
                kind: .unavailable,
                userMessage: "Restore is unavailable. Try again.",
                diagnosticCode: "ui-flows.settings.preview",
                isRetryable: true
            ))
            message = "Restore is unavailable. Try again."
        }
        return BroadSettingsScreen(
            userID: "fixture-user",
            version: "1.0.0",
            build: "1",
            isRestoring: state == .restoring,
            restoreResult: result,
            restoreMessage: message,
            canContactSupport: true
        )
    }
}
