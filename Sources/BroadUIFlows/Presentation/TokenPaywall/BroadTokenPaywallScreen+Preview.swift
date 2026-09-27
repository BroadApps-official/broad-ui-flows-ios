import BroadCore
import BroadMonetization
import Foundation

public extension BroadTokenPaywallScreen {
    /// A state to render a custom token paywall in Xcode Previews without Adapty.
    enum PreviewState: CaseIterable, Sendable {
        case packages
        case loading
        case purchasing
        case credited
        case pending
        case confirming
        case cancelled
        case failed
        case empty
    }

    /// Fixture screen for Xcode Previews: three packages with the middle one
    /// selected and a balance of 120, priced in the currency of the formatter's
    /// locale. Actions do nothing.
    static func preview(
        _ state: PreviewState = .packages,
        formatter: BroadPaywallProductFormatter = BroadPaywallProductFormatter()
    ) -> BroadTokenPaywallScreen {
        let packages = previewPackages(formatter: formatter)
        let copy = BroadTokenPaywallCopy.russian.states
        switch state {
        case .packages:
            return previewScreen(packages: packages, formatter: formatter)
        case .loading:
            return previewScreen(content: .loading, balance: nil, formatter: formatter, canPurchase: false)
        case .purchasing:
            return previewScreen(packages: packages, activity: .purchasing, formatter: formatter, canPurchase: false)
        case .credited:
            return previewScreen(
                packages: packages,
                balance: 620,
                notice: .credited(TokenBalanceSnapshot(balance: 620, updatedAt: Date())),
                message: copy.creditedMessage,
                formatter: formatter
            )
        case .pending:
            return previewScreen(
                packages: packages,
                notice: .pending,
                message: copy.pendingMessage,
                formatter: formatter,
                needsConfirmation: true,
                canPurchase: false
            )
        case .confirming:
            return previewScreen(
                packages: packages,
                activity: .confirming,
                formatter: formatter,
                needsConfirmation: true,
                canPurchase: false
            )
        case .cancelled:
            return previewScreen(
                packages: packages,
                notice: .cancelled,
                message: copy.cancelledMessage,
                formatter: formatter
            )
        case .failed:
            return previewScreen(content: .failed(previewError), formatter: formatter, canPurchase: false)
        case .empty:
            return previewScreen(content: .empty, formatter: formatter, canPurchase: false)
        }
    }
}

private extension BroadTokenPaywallScreen {
    static let previewError = AppError(
        kind: .unavailable,
        userMessage: "Could not reach the App Store. Try again.",
        diagnosticCode: "ui-flows.token-paywall.preview",
        isRetryable: true
    )

    static func previewScreen(
        content: Content = .packages,
        packages: [BroadTokenPackage] = [],
        activity: Activity = .idle,
        balance: Decimal? = 120,
        notice: BroadTokenPaywallFeedback? = nil,
        message: String? = nil,
        formatter: BroadPaywallProductFormatter,
        needsConfirmation: Bool = false,
        canPurchase: Bool = true
    ) -> BroadTokenPaywallScreen {
        BroadTokenPaywallScreen(
            content: content,
            packages: packages,
            activity: activity,
            balance: balance,
            balanceText: balanceText(balance, locale: formatter.locale),
            notice: notice,
            noticeMessage: message,
            needsConfirmation: needsConfirmation,
            canPurchase: canPurchase,
            canClose: activity == .idle
        )
    }

    static func previewPackages(formatter: BroadPaywallProductFormatter) -> [BroadTokenPackage] {
        let currency = formatter.locale.currency?.identifier ?? "XXX"
        func package(_ index: Int, tokens: Int, cents: Int) -> BroadTokenPackage {
            BroadTokenPackage(
                id: ProductPresentationID(rawValue: "preview.tokens.\(index)"),
                productID: ProductID(rawValue: "preview.tokens.\(tokens)"),
                title: nil,
                subtitle: nil,
                price: formatter.amount(Money(amount: Decimal(cents) / 100, currencyCode: currency)),
                tokens: tokens,
                isSelected: index == 2,
                isAvailable: true
            )
        }
        return [
            package(1, tokens: 100, cents: 499),
            package(2, tokens: 500, cents: 1999),
            package(3, tokens: 1500, cents: 4999)
        ]
    }
}
