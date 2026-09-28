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
    /// The amount actually charged for one billing period, formatted by the store.
    /// App Review requires this amount and its period to be prominent on the right;
    /// a weekly equivalent must never replace it as the main price.
    public let price: String?
    /// A weekly equivalent, shown only as a smaller hint below the plan title;
    /// `nil` when it cannot be computed. It must not be the main charged price.
    public let weeklyPrice: String?
    /// Price of the cheapest higher-priced regular plan with the same period and currency.
    public let regularPrice: String?
    /// Whole-percent Special Offer discount against ``regularPrice``.
    public let discountPercent: Int?
    /// Saving against the most expensive plan per week, in whole percent.
    public let savingsPercent: Int?
    /// The single plan with the largest saving.
    public let isBestValue: Bool
    public let isSelected: Bool
    /// Whether the plan can be bought on this device.
    public let isAvailable: Bool

    /// Creates a plan without Special Offer comparison data.
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
        self.init(
            id: id, title: title, period: period, periodText: periodText,
            price: price, weeklyPrice: weeklyPrice, regularPrice: nil,
            discountPercent: nil, savingsPercent: savingsPercent,
            isBestValue: isBestValue, isSelected: isSelected, isAvailable: isAvailable
        )
    }

    /// Creates a plan with optional Special Offer comparison data.
    public init(
        id: ProductPresentationID,
        title: String?,
        period: SubscriptionPeriod,
        periodText: String?,
        price: String?,
        weeklyPrice: String?,
        regularPrice: String?,
        discountPercent: Int?,
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
        self.regularPrice = regularPrice
        self.discountPercent = discountPercent
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

    /// Hides the current notice without changing the purchase state.
    public func dismissNotice() {
        actions.dismissNotice()
    }

    /// Closes the paywall when closing is allowed.
    public func close() {
        actions.close()
    }

    /// Opens Privacy Policy or Terms inside the app.
    public func open(_ link: BroadPaywallLegalLink) {
        actions.open(link)
    }

    /// Creates a screen without a notice-dismiss action.
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
        self.init(
            content: content, plans: plans, activity: activity, notice: notice,
            noticeMessage: noticeMessage, canPurchase: canPurchase, canClose: canClose,
            legalLinks: legalLinks, specialOfferEndsAt: specialOfferEndsAt,
            select: select, purchase: purchase, restore: restore, retry: retry,
            dismissNotice: {}, close: close, open: open
        )
    }

    /// Creates a screen with a notice-dismiss action supplied by its host.
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
        dismissNotice: @escaping @MainActor () -> Void,
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
            dismissNotice: dismissNotice,
            close: close,
            open: open
        )
    }

    struct Actions {
        let select: @MainActor (ProductPresentationID) -> Void
        let purchase: @MainActor () -> Void
        let restore: @MainActor () -> Void
        let retry: @MainActor () -> Void
        let dismissNotice: @MainActor () -> Void
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
            dismissNotice: { [weak self] in self?.dismissNotice() },
            close: close,
            open: open
        )
    }

    func plans(formatter: BroadPaywallProductFormatter) -> [BroadPaywallPlan] {
        let products = displayedProducts
        let presentations = ProductPricePresenter().presentations(for: products)
        return zip(products, presentations).map { product, presentation in
            let offerPricing = configuration.specialOfferAuthorization.flatMap { _ in
                BroadSpecialOfferPricing.make(
                    offer: product,
                    reference: configuration.referenceProducts,
                    formatter: formatter
                )
            }
            return BroadPaywallPlan(
                id: product.presentationID,
                title: product.title,
                period: product.subscriptionPeriod,
                periodText: formatter.period(for: product),
                price: formatter.price(for: product),
                weeklyPrice: presentation.weeklyPrice.flatMap(formatter.amount),
                regularPrice: offerPricing?.regularPrice,
                discountPercent: offerPricing?.discountPercent,
                savingsPercent: presentation.savingsPercent,
                isBestValue: presentation.isBestValue,
                isSelected: product.presentationID == selectedProductPresentationID,
                isAvailable: product.isEligibleForGenericPurchase
            )
        }
    }
}
