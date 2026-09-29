import BroadCore
import BroadMonetization
import Foundation

/// One token package, ready to draw.
public struct BroadTokenPackage: Identifiable, Equatable, Sendable {
    public let id: ProductPresentationID
    /// Store product identifier, for mapping to app assets or copy.
    public let productID: ProductID
    public let title: String?
    public let subtitle: String?
    /// Price as the store formats it.
    public let price: String?
    /// Verified numeric store price, if available.
    public let priceAmount: Money?
    /// Tokens the package adds, from the host's `tokenAmount`; `nil` when unknown.
    public let tokens: Int?
    /// Whole-percent saving per token against the most expensive package per token.
    public let savingsPercent: Int?
    /// The single package with the largest positive per-token saving.
    public let isBestValue: Bool
    public let isSelected: Bool
    /// Whether the package can be bought on this device.
    public let isAvailable: Bool

    /// Creates a package without numeric price comparison data.
    public init(
        id: ProductPresentationID,
        productID: ProductID,
        title: String?,
        subtitle: String?,
        price: String?,
        tokens: Int?,
        isSelected: Bool,
        isAvailable: Bool
    ) {
        self.init(
            id: id, productID: productID, title: title, subtitle: subtitle,
            price: price, priceAmount: nil, tokens: tokens, savingsPercent: nil,
            isBestValue: false, isSelected: isSelected, isAvailable: isAvailable
        )
    }

    /// Creates a package with verified price and derived comparison data.
    public init(
        id: ProductPresentationID,
        productID: ProductID,
        title: String?,
        subtitle: String?,
        price: String?,
        priceAmount: Money?,
        tokens: Int?,
        savingsPercent: Int?,
        isBestValue: Bool,
        isSelected: Bool,
        isAvailable: Bool
    ) {
        self.id = id
        self.productID = productID
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.priceAmount = priceAmount
        self.tokens = tokens
        self.savingsPercent = savingsPercent
        self.isBestValue = isBestValue
        self.isSelected = isSelected
        self.isAvailable = isAvailable
    }
}

/// Everything a custom token paywall draws, plus its actions. Built by
/// ``BroadTokenPaywallHost``; the screen holds no purchase logic.
@MainActor
public struct BroadTokenPaywallScreen {
    public enum Content: Equatable, Sendable {
        case loading
        case packages
        case empty
        case failed(AppError)
    }

    public enum Activity: Equatable, Sendable {
        case idle
        /// The store purchase or its server credit is running.
        case purchasing
        /// A saved purchase is being checked; nothing is charged again.
        case confirming
        /// The balance is being read from the server.
        case refreshingBalance
    }

    public let content: Content
    /// Packages in the placement order.
    public let packages: [BroadTokenPackage]
    public let activity: Activity
    /// Last balance the server confirmed; `nil` until the first answer.
    public let balance: Decimal?
    /// ``balance`` as a locale number without a unit; the screen adds its own.
    public let balanceText: String?
    public let notice: BroadTokenPaywallFeedback?
    /// Text for ``notice`` from the configured copy.
    public let noticeMessage: String?
    /// A purchase waits for the server credit: show ``confirm()`` as the main
    /// action instead of ``purchase()``.
    public let needsConfirmation: Bool
    public let canPurchase: Bool
    /// Closing is blocked until the configured delay ends and while busy.
    public let canClose: Bool

    let actions: Actions

    public var selectedPackage: BroadTokenPackage? {
        packages.first(where: \.isSelected)
    }

    public var isBusy: Bool {
        activity != .idle
    }

    public func select(_ package: BroadTokenPackage) {
        actions.select(package.id)
    }

    /// Buys the selected package once; repeated taps are ignored.
    public func purchase() {
        actions.purchase()
    }

    /// Checks a saved purchase with the server. Never charges again.
    public func confirm() {
        actions.confirm()
    }

    /// Reads the balance from the server again.
    public func refreshBalance() {
        actions.refreshBalance()
    }

    /// Loads the packages again after an error or an empty answer.
    public func retry() {
        actions.retry()
    }

    public func close() {
        actions.close()
    }

    public func dismissNotice() {
        actions.dismissNotice()
    }

    public init(
        content: Content,
        packages: [BroadTokenPackage],
        activity: Activity = .idle,
        balance: Decimal? = nil,
        balanceText: String? = nil,
        notice: BroadTokenPaywallFeedback? = nil,
        noticeMessage: String? = nil,
        needsConfirmation: Bool = false,
        canPurchase: Bool,
        canClose: Bool = true,
        select: @escaping @MainActor (ProductPresentationID) -> Void = { _ in },
        purchase: @escaping @MainActor () -> Void = {},
        confirm: @escaping @MainActor () -> Void = {},
        refreshBalance: @escaping @MainActor () -> Void = {},
        retry: @escaping @MainActor () -> Void = {},
        close: @escaping @MainActor () -> Void = {},
        dismissNotice: @escaping @MainActor () -> Void = {}
    ) {
        self.content = content
        self.packages = packages
        self.activity = activity
        self.balance = balance
        self.balanceText = balanceText
        self.notice = notice
        self.noticeMessage = noticeMessage
        self.needsConfirmation = needsConfirmation
        self.canPurchase = canPurchase
        self.canClose = canClose
        actions = Actions(
            select: select,
            purchase: purchase,
            confirm: confirm,
            refreshBalance: refreshBalance,
            retry: retry,
            close: close,
            dismissNotice: dismissNotice
        )
    }

    struct Actions {
        let select: @MainActor (ProductPresentationID) -> Void
        let purchase: @MainActor () -> Void
        let confirm: @MainActor () -> Void
        let refreshBalance: @MainActor () -> Void
        let retry: @MainActor () -> Void
        let close: @MainActor () -> Void
        let dismissNotice: @MainActor () -> Void
    }
}

extension BroadTokenPaywallScreen {
    static func balanceText(_ balance: Decimal?, locale: Locale) -> String? {
        guard let balance else {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: balance))
    }
}

extension BroadTokenPaywallViewModel {
    /// Builds the screen model: packages with prices, the purchase phase, the
    /// confirmed balance and the typed notice.
    func screen(
        formatter: BroadPaywallProductFormatter,
        tokenAmount: (@MainActor (MonetizationProduct) -> Int?)?,
        close: @escaping @MainActor () -> Void
    ) -> BroadTokenPaywallScreen {
        BroadTokenPaywallScreen(
            content: screenContent,
            packages: packages(formatter: formatter, tokenAmount: tokenAmount),
            activity: screenActivity,
            balance: balanceSnapshot?.balance,
            balanceText: BroadTokenPaywallScreen.balanceText(
                balanceSnapshot?.balance,
                locale: formatter.locale
            ),
            notice: feedback,
            noticeMessage: feedback.map(message(for:)),
            needsConfirmation: isRetrySuggested,
            canPurchase: canPurchase,
            canClose: isCloseAvailable && !isBusy,
            select: { [weak self] id in self?.selectProduct(presentationID: id) },
            purchase: { [weak self] in self?.purchaseSelectedProduct() },
            confirm: { [weak self] in self?.retrySafely() },
            refreshBalance: { [weak self] in self?.recoverAccountBalance() },
            retry: { [weak self] in self?.retryLoad() },
            close: close,
            dismissNotice: { [weak self] in self?.dismissFeedback() }
        )
    }

    private var screenContent: BroadTokenPaywallScreen.Content {
        switch state {
        case .idle, .loading:
            .loading
        case .content:
            .packages
        case .empty:
            .empty
        case let .failure(error):
            .failed(error)
        }
    }

    private var screenActivity: BroadTokenPaywallScreen.Activity {
        if isPurchaseInFlight {
            .purchasing
        } else if isRecoveringPendingPurchase {
            .confirming
        } else if isRecoveringAccountBalance {
            .refreshingBalance
        } else {
            .idle
        }
    }

    private func packages(
        formatter: BroadPaywallProductFormatter,
        tokenAmount: (@MainActor (MonetizationProduct) -> Int?)?
    ) -> [BroadTokenPackage] {
        guard case let .content(payload) = state else {
            return []
        }
        let products = payload.products
        let tokenCounts = products.map { tokenAmount?($0) }
        let pricing = BroadTokenPackagePricing.presentations(
            prices: products.map(\.price),
            tokens: tokenCounts
        )
        return products.enumerated().map { index, product in
            BroadTokenPackage(
                id: product.presentationID,
                productID: product.productID,
                title: product.title,
                subtitle: product.subtitle,
                price: formatter.price(for: product),
                priceAmount: product.price,
                tokens: tokenCounts[index],
                savingsPercent: pricing[index].savingsPercent,
                isBestValue: pricing[index].isBestValue,
                isSelected: product.presentationID == selectedProductPresentationID,
                isAvailable: product.isTokenPackage
            )
        }
    }
}
