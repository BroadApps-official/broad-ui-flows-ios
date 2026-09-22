import BroadMonetization
import Foundation

public extension BroadTokenPaywallViewModel {
    /// Reports the close of a shown presentation. A catalog that arrives after
    /// the screen disappeared is not a view.
    func viewDidDisappear() {
        isVisible = false
        guard let context = shownContext else {
            return
        }
        shownContext = nil
        guard let trackEvent = dependencies.trackEvent else {
            return
        }
        Task { await trackEvent(.paywallClosed(context, reason: .dismissed)) }
    }
}

extension BroadTokenPaywallViewModel {
    func trackShownIfNeeded(_ paywall: PaywallPayload) {
        guard lastShownPresentationID != paywall.presentationID else {
            return
        }
        lastShownPresentationID = paywall.presentationID
        let context = PaywallAnalyticsContext(paywall: paywall)
        shownContext = context
        guard let trackEvent = dependencies.trackEvent else {
            return
        }
        Task { await trackEvent(.paywallShown(context)) }
    }
}
