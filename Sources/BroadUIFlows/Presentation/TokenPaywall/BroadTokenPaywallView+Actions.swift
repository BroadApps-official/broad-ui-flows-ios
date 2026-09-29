import BroadMonetization
import Foundation
import SwiftUI

extension BroadTokenPaywallView {
    var primaryActionTitle: String {
        if viewModel.isRetrySuggested {
            return viewModel.isRecoveringPendingPurchase
                ? copy.actions.confirmingTitle
                : copy.actions.confirmTitle
        }
        return viewModel.isPurchaseInFlight
            ? copy.actions.purchasingTitle
            : copy.actions.purchaseTitle
    }

    var primaryActionIsEnabled: Bool {
        viewModel.isRetrySuggested
            ? !viewModel.isBusy
            : viewModel.canPurchase
    }

    func primaryAction() {
        if viewModel.isRetrySuggested {
            viewModel.retrySafely()
        } else {
            viewModel.purchaseSelectedProduct()
        }
    }

    /// The confirmed balance as a locale number without a unit, so no plural
    /// form of "tokens" is hard-coded.
    var balanceText: String {
        BroadTokenPaywallScreen.balanceText(
            viewModel.balanceSnapshot?.balance,
            locale: productFormatter.locale
        ) ?? "—"
    }
}

extension BroadTokenPaywallFeedback {
    var systemImage: String {
        switch self {
        case .credited, .recovered:
            "checkmark.seal.fill"
        case .pending:
            "clock.badge.exclamationmark"
        case .cancelled:
            "xmark.circle"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    @MainActor
    func tint(theme: BroadPaywallTheme) -> Color {
        switch self {
        case .credited, .recovered:
            theme.palette.accent
        case .pending, .cancelled, .failed:
            theme.palette.secondaryText
        }
    }
}
