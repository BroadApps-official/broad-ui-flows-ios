import BroadCore
import BroadMonetization
import Foundation

public extension BroadPaywallScreen {
    /// A state to render a custom paywall in Xcode Previews without Adapty.
    enum PreviewState: CaseIterable, Sendable {
        case plans
        case loading
        case purchasing
        case restoring
        case pending
        case nothingToRestore
        case failed
        case empty
        case specialOffer
    }

    /// Fixture screen for Xcode Previews. The Special Offer contains one plan.
    /// Actions do nothing.
    static func preview(
        _ state: PreviewState = .plans,
        formatter: BroadPaywallProductFormatter = BroadPaywallProductFormatter()
    ) -> BroadPaywallScreen {
        let plans = previewPlans(formatter: formatter, specialOffer: state == .specialOffer)
        switch state {
        case .plans:
            return previewScreen(plans: plans)
        case .loading:
            return previewScreen(content: .loading, canPurchase: false, canClose: false)
        case .purchasing:
            return previewScreen(plans: plans, activity: .purchasing, canPurchase: false)
        case .restoring:
            return previewScreen(plans: plans, activity: .restoring, canPurchase: false)
        case .pending:
            return previewScreen(
                plans: plans,
                notice: .purchasePending,
                message: "The payment is waiting for approval.",
                canPurchase: false
            )
        case .nothingToRestore:
            return previewScreen(plans: plans, notice: .nothingToRestore, message: "No purchases to restore.")
        case .failed:
            return previewScreen(content: .failed(previewError), canPurchase: false)
        case .empty:
            return previewScreen(content: .empty, canPurchase: false)
        case .specialOffer:
            return previewScreen(
                plans: Array(plans.prefix(1)),
                specialOfferEndsAt: Date().addingTimeInterval(23 * 3600 + 59 * 60)
            )
        }
    }

    /// Fixture Special Offer with two provider plans and one visible plan.
    static func previewSpecialOfferWithTwoProducts(
        formatter: BroadPaywallProductFormatter = BroadPaywallProductFormatter()
    ) -> BroadPaywallScreen {
        previewScreen(
            plans: Array(previewPlans(formatter: formatter, specialOffer: true).prefix(2)),
            specialOfferEndsAt: Date().addingTimeInterval(23 * 3600 + 59 * 60)
        )
    }
}

private extension BroadPaywallScreen {
    static let previewError = AppError(
        kind: .unavailable,
        userMessage: "Could not reach the App Store. Try again.",
        diagnosticCode: "ui-flows.paywall.preview",
        isRetryable: true
    )

    static func previewScreen(
        content: Content = .plans,
        plans: [BroadPaywallPlan] = [],
        activity: Activity = .idle,
        notice: BroadPaywallNotice? = nil,
        message: String? = nil,
        canPurchase: Bool = true,
        canClose: Bool = true,
        specialOfferEndsAt: Date? = nil
    ) -> BroadPaywallScreen {
        BroadPaywallScreen(
            content: content,
            plans: plans,
            activity: activity,
            notice: notice,
            noticeMessage: message,
            canPurchase: canPurchase,
            canClose: canClose,
            legalLinks: previewLegalLinks,
            specialOfferEndsAt: specialOfferEndsAt
        )
    }

    static func previewPlans(
        formatter: BroadPaywallProductFormatter,
        specialOffer: Bool
    ) -> [BroadPaywallPlan] {
        let currency = formatter.locale.currency?.identifier ?? "XXX"
        func money(_ cents: Int) -> Money {
            Money(amount: Decimal(cents) / 100, currencyCode: currency)
        }
        func plan(
            _ index: Int,
            _ period: SubscriptionPeriod,
            _ cents: Int,
            perWeek: Int?,
            savings: Int?
        ) -> BroadPaywallPlan {
            BroadPaywallPlan(
                id: ProductPresentationID(rawValue: "preview.plan.\(index)"),
                title: nil,
                period: period,
                periodText: formatter.period(period),
                price: formatter.amount(money(cents)),
                weeklyPrice: perWeek.map(money).flatMap(formatter.amount),
                regularPrice: specialOffer && index == 1 ? formatter.amount(money(9999)) : nil,
                discountPercent: specialOffer && index == 1
                    ? BroadSpecialOfferPricing.discountPercent(offer: money(cents), regular: money(9999))
                    : nil,
                savingsPercent: savings,
                isBestValue: index == 1,
                isSelected: index == 1,
                isAvailable: true
            )
        }
        return [
            plan(1, .year(), 5999, perWeek: 115, savings: 88),
            plan(2, .month(), 1999, perWeek: 460, savings: 54),
            plan(3, .week(), 999, perWeek: nil, savings: nil)
        ]
    }

    static var previewLegalLinks: [BroadPaywallLegalLink] {
        guard let privacy = URL(string: "https://example.com/privacy"),
              let terms = URL(string: "https://example.com/terms")
        else {
            return []
        }
        return [
            BroadPaywallLegalLink(id: "privacy", title: "Privacy Policy", url: privacy),
            BroadPaywallLegalLink(id: "terms", title: "Terms of Use", url: terms)
        ]
    }
}
