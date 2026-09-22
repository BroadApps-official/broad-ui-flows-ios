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
        track(.paywallClosed(context, reason: .dismissed))
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
        track(.paywallShown(context))
    }

    func track(_ event: MonetizationAnalyticsEvent) {
        guard let trackEvent = dependencies.trackEvent else {
            return
        }
        let previous = eventTask
        eventTask = Task { [previous, trackEvent] in
            await previous?.value
            await trackEvent(event)
        }
    }
}
