import BroadCore
import Foundation

public extension BroadTokenPaywallViewModel {
    /// Hides the current notice. A purchase that waits for its credit keeps
    /// ``isRetrySuggested``, so the check stays available.
    func dismissFeedback() {
        feedback = nil
    }

    /// Text for a notice from the configured copy; failures use the safe
    /// `AppError.userMessage`.
    func message(for feedback: BroadTokenPaywallFeedback) -> String {
        let states = configuration.copy.states
        return switch feedback {
        case .credited:
            states.creditedMessage
        case .pending:
            states.pendingMessage
        case .cancelled:
            states.cancelledMessage
        case .recovered:
            states.recoveredMessage
        case let .failed(error):
            error.userMessage
        }
    }
}
