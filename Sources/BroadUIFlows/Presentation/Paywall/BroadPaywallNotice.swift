import BroadCore
import Foundation

/// What the paywall has to tell the person after a purchase or restore attempt.
/// A custom screen switches on the case instead of comparing message strings.
public enum BroadPaywallNotice: Equatable, Sendable {
    /// The store finished the purchase; access is still being confirmed.
    case purchaseCompleted
    /// The store finished the purchase, but access could not be verified yet.
    case purchaseUnverified
    /// The payment is waiting for approval (for example Ask to Buy).
    case purchasePending
    /// Restore found no purchase for this account.
    case nothingToRestore
    /// No checkout method is available for the selected plan.
    case checkoutUnavailable(AppError)
    /// Purchase or restore failed.
    case failed(AppError)

    /// Whether the notice reports a failure rather than a neutral state.
    public var isFailure: Bool {
        switch self {
        case .checkoutUnavailable, .failed:
            true
        case .purchaseCompleted, .purchaseUnverified, .purchasePending, .nothingToRestore:
            false
        }
    }
}
