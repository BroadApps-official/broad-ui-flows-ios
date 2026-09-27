import BroadCore
import BroadMonetization
import Foundation

/// One subscription plan, ready to draw: strings are formatted, the badge and the
/// selection are decided. A custom screen only lays these values out.
public struct BroadPaywallPlan: Identifiable, Equatable, Sendable {
    public let id: ProductPresentationID
    /// Product title from the provider.
    public let title: String?
    public let period: SubscriptionPeriod
    /// Billing period text, for example "per year".
    public let periodText: String?
    /// Price of one billing period as the store formats it.
    public let price: String?
    /// Price brought to one week; `nil` when it cannot be computed.
    public let weeklyPrice: String?
    /// Saving against the most expensive plan per week, in whole percent.
    public let savingsPercent: Int?
    /// The single plan with the largest saving.
    public let isBestValue: Bool
    public let isSelected: Bool
    /// Whether the plan can be bought on this device.
    public let isAvailable: Bool

    public init(
        id: ProductPresentationID,
        title: String?,
        period: SubscriptionPeriod,
        periodText: String?,
        price: String?,
        weeklyPrice: String?,
        savingsPercent: Int?,
        isBestValue: Bool,
        isSelected: Bool,
        isAvailable: Bool
    ) {
        self.id = id
        self.title = title
        self.period = period
        self.periodText = periodText
        self.price = price
        self.weeklyPrice = weeklyPrice
        self.savingsPercent = savingsPercent
        self.isBestValue = isBestValue
        self.isSelected = isSelected
        self.isAvailable = isAvailable
    }
}

/// Everything a custom paywall screen draws, plus its actions. Built by
/// ``BroadPaywallHost``; the screen holds no purchase logic.
@MainActor
public struct BroadPaywallScreen {
    public enum Content: Equatable, Sendable {
        case loading
        case plans
        case empty
        case failed(AppError)
    }

    public enum Activity: Equatable, Sendable {
        case idle
        case purchasing
        case restoring
    }

    public let content: Content
    /// Plans in display order: the longest subscription first.
    public let plans: [BroadPaywallPlan]
    public let activity: Activity
    public let notice: BroadPaywallNotice?
    /// Text for ``notice`` from the configured copy.
    public let noticeMessage: String?
    public let canPurchase: Bool
    /// The close button may be shown (after the delay of a hard paywall).
    public let canClose: Bool
    public let legalLinks: [BroadPaywallLegalLink]
    /// End of the Special Offer window for a countdown; `nil` for a regular paywall.
    public let specialOfferEndsAt: Date?

    let actions: Actions

    public var selectedPlan: BroadPaywallPlan? {
        plans.first(where: \.isSelected)
    }

    public var isBusy: Bool {
        activity != .idle
    }

    public func select(_ plan: BroadPaywallPlan) {
        actions.select(plan.id)
    }

    public func purchase() {
        actions.purchase()
    }

    public func restore() {
        actions.restore()
    }

    public func retry() {
        actions.retry()
    }

    /// Closes the paywall when closing is allowed.
    public func close() {
        actions.close()
    }

    /// Opens Privacy Policy or Terms inside the app.
    public func open(_ link: BroadPaywallLegalLink) {
        actions.open(link)
    }

    public init(
        content: Content,
        plans: [BroadPaywallPlan],
        activity: Activity = .idle,
        notice: BroadPaywallNotice? = nil,
        noticeMessage: String? = nil,
        canPurchase: Bool,
        canClose: Bool,
        legalLinks: [BroadPaywallLegalLink] = [],
        specialOfferEndsAt: Date? = nil,
        select: @escaping @MainActor (ProductPresentationID) -> Void = { _ in },
        purchase: @escaping @MainActor () -> Void = {},
        restore: @escaping @MainActor () -> Void = {},
        retry: @escaping @MainActor () -> Void = {},
        close: @escaping @MainActor () -> Void = {},
        open: @escaping @MainActor (BroadPaywallLegalLink) -> Void = { _ in }
    ) {
        self.content = content
        self.plans = plans
        self.activity = activity
        self.notice = notice
        self.noticeMessage = noticeMessage
        self.canPurchase = canPurchase
        self.canClose = canClose
        self.legalLinks = legalLinks
        self.specialOfferEndsAt = specialOfferEndsAt
        actions = Actions(
            select: select,
            purchase: purchase,
            restore: restore,
            retry: retry,
            close: close,
            open: open
        )
    }

    struct Actions {
        let select: @MainActor (ProductPresentationID) -> Void
        let purchase: @MainActor () -> Void
        let restore: @MainActor () -> Void
        let retry: @MainActor () -> Void
        let close: @MainActor () -> Void
        let open: @MainActor (BroadPaywallLegalLink) -> Void
    }
}

extension PaywallViewModel {
    /// Builds the screen model: plans in display order with prices per week and
    /// the best-value badge, the purchase activity and the typed notice.
    func screen(
        formatter: BroadPaywallProductFormatter,
        close: @escaping @MainActor () -> Void,
        open: @escaping @MainActor (BroadPaywallLegalLink) -> Void
    ) -> BroadPaywallScreen {
        let content: BroadPaywallScreen.Content = switch state {
        case .idle, .loading:
            .loading
        case .content:
            .plans
        case .empty:
            .empty
        case let .failure(error):
            .failed(error)
        }
        let activity: BroadPaywallScreen.Activity = if isRestoreInFlight {
            .restoring
        } else if isPurchaseInFlight || isResolvingCheckoutMethods {
            .purchasing
        } else {
            .idle
        }

        return BroadPaywallScreen(
            content: content,
            plans: plans(formatter: formatter),
            activity: activity,
            notice: notice,
            noticeMessage: notice.map(message(for:)),
            canPurchase: canPurchase,
            canClose: isCloseAvailable,
            legalLinks: configuration.legalLinks,
            specialOfferEndsAt: configuration.specialOfferExpiresAt,
            select: { [weak self] id in self?.selectProduct(presentationID: id) },
            purchase: { [weak self] in self?.purchaseButtonTapped() },
            restore: { [weak self] in self?.restorePurchases() },
            retry: { [weak self] in self?.retry() },
            close: close,
            open: open
        )
    }

    func plans(formatter: BroadPaywallProductFormatter) -> [BroadPaywallPlan] {
        let products = displayedProducts
        let presentations = ProductPricePresenter().presentations(for: products)
        return zip(products, presentations).map { product, presentation in
            BroadPaywallPlan(
                id: product.presentationID,
                title: product.title,
                period: product.subscriptionPeriod,
                periodText: formatter.period(for: product),
                price: formatter.price(for: product),
                weeklyPrice: presentation.weeklyPrice.flatMap(formatter.amount),
                savingsPercent: presentation.savingsPercent,
                isBestValue: presentation.isBestValue,
                isSelected: product.presentationID == selectedProductPresentationID,
                isAvailable: product.isEligibleForGenericPurchase
            )
        }
    }
}
