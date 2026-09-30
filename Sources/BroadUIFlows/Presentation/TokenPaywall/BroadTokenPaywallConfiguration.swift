import BroadMonetization
import Foundation

public struct BroadTokenPaywallCopy: Equatable, Sendable {
    public struct Header: Equatable, Sendable {
        public let title: String
        public let subtitle: String
        public let balanceTitle: String

        public init(
            title: String,
            subtitle: String,
            balanceTitle: String
        ) {
            self.title = title
            self.subtitle = subtitle
            self.balanceTitle = balanceTitle
        }
    }

    public struct Products: Equatable, Sendable {
        public let fallbackTitle: String
        public let unavailablePriceTitle: String
        public let selectedAccessibilityValue: String
        /// Localized token noun forms; `nil` preserves the store title and fallback from older copy.
        public let tokenName: BroadCountedNameCopy?

        /// Preserves the title-based presentation of custom copy from 6.5.0 and earlier.
        public init(
            fallbackTitle: String,
            unavailablePriceTitle: String,
            selectedAccessibilityValue: String
        ) {
            self.init(
                fallbackTitle: fallbackTitle, unavailablePriceTitle: unavailablePriceTitle,
                selectedAccessibilityValue: selectedAccessibilityValue, tokenName: nil
            )
        }

        /// Enables localized quantity names when `tokenName` is non-nil.
        public init(
            fallbackTitle: String,
            unavailablePriceTitle: String,
            selectedAccessibilityValue: String,
            tokenName: BroadCountedNameCopy?
        ) {
            self.fallbackTitle = fallbackTitle
            self.unavailablePriceTitle = unavailablePriceTitle
            self.selectedAccessibilityValue = selectedAccessibilityValue
            self.tokenName = tokenName
        }
    }

    public struct Actions: Equatable, Sendable {
        public let purchaseTitle: String
        public let purchasingTitle: String
        public let retryTitle: String
        public let retryingTitle: String
        public let recoverBalanceTitle: String
        public let recoveringBalanceTitle: String
        public let closeAccessibilityLabel: String
        /// Main action while a saved purchase waits for its credit.
        public let confirmTitle: String
        public let confirmingTitle: String

        /// Preserves the initializer from releases before pending-purchase confirmation copy.
        public init(
            purchaseTitle: String,
            purchasingTitle: String,
            retryTitle: String,
            retryingTitle: String,
            recoverBalanceTitle: String,
            recoveringBalanceTitle: String,
            closeAccessibilityLabel: String
        ) {
            self.init(
                purchaseTitle: purchaseTitle, purchasingTitle: purchasingTitle,
                retryTitle: retryTitle, retryingTitle: retryingTitle,
                recoverBalanceTitle: recoverBalanceTitle, recoveringBalanceTitle: recoveringBalanceTitle,
                closeAccessibilityLabel: closeAccessibilityLabel,
                confirmTitle: "Проверить покупку"
            )
        }

        /// Allows overriding only the progress text, as the original defaulted initializer did.
        public init(
            purchaseTitle: String,
            purchasingTitle: String,
            retryTitle: String,
            retryingTitle: String,
            recoverBalanceTitle: String,
            recoveringBalanceTitle: String,
            closeAccessibilityLabel: String,
            confirmingTitle: String
        ) {
            self.init(
                purchaseTitle: purchaseTitle, purchasingTitle: purchasingTitle,
                retryTitle: retryTitle, retryingTitle: retryingTitle,
                recoverBalanceTitle: recoverBalanceTitle, recoveringBalanceTitle: recoveringBalanceTitle,
                closeAccessibilityLabel: closeAccessibilityLabel,
                confirmTitle: "Проверить покупку", confirmingTitle: confirmingTitle
            )
        }

        /// `retryTitle` reloads the packages after an error; `confirmTitle` checks a
        /// saved purchase and never charges again.
        public init(
            purchaseTitle: String,
            purchasingTitle: String,
            retryTitle: String,
            retryingTitle: String,
            recoverBalanceTitle: String,
            recoveringBalanceTitle: String,
            closeAccessibilityLabel: String,
            confirmTitle: String,
            confirmingTitle: String = "Проверяем покупку…"
        ) {
            self.purchaseTitle = purchaseTitle
            self.purchasingTitle = purchasingTitle
            self.retryTitle = retryTitle
            self.retryingTitle = retryingTitle
            self.recoverBalanceTitle = recoverBalanceTitle
            self.recoveringBalanceTitle = recoveringBalanceTitle
            self.closeAccessibilityLabel = closeAccessibilityLabel
            self.confirmTitle = confirmTitle
            self.confirmingTitle = confirmingTitle
        }
    }

    public struct States: Equatable, Sendable {
        public let loadingTitle: String
        public let emptyTitle: String
        public let emptyMessage: String
        public let errorTitle: String
        public let pendingMessage: String
        public let cancelledMessage: String
        public let creditedMessage: String
        public let recoveredMessage: String

        public init(
            loadingTitle: String,
            emptyTitle: String,
            emptyMessage: String,
            errorTitle: String,
            pendingMessage: String,
            cancelledMessage: String,
            creditedMessage: String,
            recoveredMessage: String
        ) {
            self.loadingTitle = loadingTitle
            self.emptyTitle = emptyTitle
            self.emptyMessage = emptyMessage
            self.errorTitle = errorTitle
            self.pendingMessage = pendingMessage
            self.cancelledMessage = cancelledMessage
            self.creditedMessage = creditedMessage
            self.recoveredMessage = recoveredMessage
        }
    }

    public struct Analytics: Equatable, Sendable {
        public let title: String
        public let emptyMessage: String

        public init(title: String, emptyMessage: String) {
            self.title = title
            self.emptyMessage = emptyMessage
        }
    }

    public let header: Header
    public let products: Products
    public let actions: Actions
    public let states: States
    public let analytics: Analytics

    public init(
        header: Header,
        products: Products,
        actions: Actions,
        states: States,
        analytics: Analytics
    ) {
        self.header = header
        self.products = products
        self.actions = actions
        self.states = states
        self.analytics = analytics
    }
}

public extension BroadTokenPaywallCopy {
    static let english = BroadTokenPaywallCopy(
        header: Header(
            title: "Get More Tokens",
            subtitle: "Tokens are added to your balance right after the purchase.",
            balanceTitle: "Balance"
        ),
        products: Products(
            fallbackTitle: "Token pack",
            unavailablePriceTitle: "Price unavailable",
            selectedAccessibilityValue: "Selected",
            tokenName: BroadCountedNameCopy(one: "Token", few: "Tokens", many: "Tokens")
        ),
        actions: Actions(
            purchaseTitle: "Continue",
            purchasingTitle: "Processing…",
            retryTitle: "Try Again",
            retryingTitle: "Loading…",
            recoverBalanceTitle: "Refresh Balance",
            recoveringBalanceTitle: "Refreshing…",
            closeAccessibilityLabel: "Close",
            confirmTitle: "Check Purchase",
            confirmingTitle: "Checking…"
        ),
        states: States(
            loadingTitle: "Loading packs…",
            emptyTitle: "No token packs available",
            emptyMessage: "Close this screen or try again later.",
            errorTitle: "Token packs are unavailable",
            pendingMessage: "Your purchase is being confirmed. Tokens will be added once it's done.",
            cancelledMessage: "Purchase cancelled.",
            creditedMessage: "Tokens added to your balance.",
            recoveredMessage: "Your balance is up to date."
        ),
        analytics: Analytics(
            title: "Token events",
            emptyMessage: "No events yet."
        )
    )

    /// The default English copy, matching ``BroadPaywallCopy/standard``.
    static let standard = english

    static let russian = BroadTokenPaywallCopy(
        header: Header(
            title: "Пополнить токены",
            subtitle: "Токены зачисляются на баланс сразу после покупки.",
            balanceTitle: "Баланс"
        ),
        products: Products(
            fallbackTitle: "Пакет токенов",
            unavailablePriceTitle: "Цена недоступна",
            selectedAccessibilityValue: "Выбрано",
            tokenName: BroadCountedNameCopy(
                one: "токен", few: "токена", many: "токенов", usesRussianPluralRules: true
            )
        ),
        actions: Actions(
            purchaseTitle: "Купить",
            purchasingTitle: "Покупаем…",
            retryTitle: "Повторить",
            retryingTitle: "Загружаем…",
            recoverBalanceTitle: "Обновить баланс",
            recoveringBalanceTitle: "Обновляем баланс…",
            closeAccessibilityLabel: "Закрыть",
            confirmTitle: "Проверить покупку",
            confirmingTitle: "Проверяем покупку…"
        ),
        states: States(
            loadingTitle: "Загружаем пакеты…",
            emptyTitle: "Пакеты токенов не найдены",
            emptyMessage: "Закройте экран или повторите загрузку позже.",
            errorTitle: "Покупка токенов недоступна",
            pendingMessage: "Покупка сохранена. Токены придут после подтверждения.",
            cancelledMessage: "Покупка отменена. Баланс не изменился.",
            creditedMessage: "Токены зачислены.",
            recoveredMessage: "Баланс обновлён."
        ),
        analytics: Analytics(
            title: "Token-аналитика этого запуска",
            emptyMessage: "События появятся после загрузки и выбора пакета."
        )
    )
}

public struct BroadTokenPaywallConfiguration: Equatable, Sendable {
    public let copy: BroadTokenPaywallCopy
    public let defaultSelectionIndex: Int
    /// Time after appearance before the close action becomes available.
    public let closeDelay: TimeInterval
    /// Shows the event log panel in ``BroadTokenPaywallView``; for demos only.
    public let showsAnalytics: Bool

    /// Preserves the initializer from releases before the analytics panel.
    public init(copy: BroadTokenPaywallCopy, defaultSelectionIndex: Int = 0) {
        self.init(copy: copy, defaultSelectionIndex: defaultSelectionIndex, showsAnalytics: false)
    }

    /// Preserves the initializer from releases before the close delay.
    public init(
        copy: BroadTokenPaywallCopy,
        defaultSelectionIndex: Int = 0,
        showsAnalytics: Bool
    ) {
        self.init(copy: copy, defaultSelectionIndex: defaultSelectionIndex, closeDelay: 0, showsAnalytics: showsAnalytics)
    }

    public init(
        copy: BroadTokenPaywallCopy,
        defaultSelectionIndex: Int = 0,
        closeDelay: TimeInterval,
        showsAnalytics: Bool = false
    ) {
        precondition(
            defaultSelectionIndex >= 0,
            "Token paywall selection index must be non-negative"
        )
        precondition(
            closeDelay.isFinite && closeDelay >= 0,
            "Token paywall close delay must be finite and non-negative"
        )
        self.copy = copy
        self.defaultSelectionIndex = defaultSelectionIndex
        self.closeDelay = closeDelay
        self.showsAnalytics = showsAnalytics
    }

    public var request: PaywallLoadRequest {
        PaywallLoadRequest(placementID: .tokens)
    }
}
