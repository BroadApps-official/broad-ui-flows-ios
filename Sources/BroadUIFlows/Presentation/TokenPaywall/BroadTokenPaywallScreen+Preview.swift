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
    /// locale. `copy` supplies notice text; actions do nothing.
    static func preview(
        _ state: PreviewState = .packages,
        formatter: BroadPaywallProductFormatter = BroadPaywallProductFormatter(),
        copy: BroadTokenPaywallCopy = .russian
    ) -> BroadTokenPaywallScreen {
        let packages = previewPackages(formatter: formatter)
        let states = copy.states
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
                message: states.creditedMessage,
                formatter: formatter
            )
        case .pending:
            return previewScreen(
                packages: packages,
                notice: .pending,
                message: states.pendingMessage,
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
                message: states.cancelledMessage,
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
        let counts = [100, 500, 1500]
        let prices = [499, 1999, 4999].map {
            Money(amount: Decimal($0) / 100, currencyCode: currency)
        }
        let pricing = BroadTokenPackagePricing.presentations(
            prices: prices.map(Optional.some),
            tokens: counts.map(Optional.some)
        )
        return counts.indices.map { offset in
            let index = offset + 1
            let tokens = counts[offset]
            return BroadTokenPackage(
                id: ProductPresentationID(rawValue: "preview.tokens.\(index)"),
                productID: ProductID(rawValue: "preview.tokens.\(tokens)"),
                title: nil,
                subtitle: nil,
                price: formatter.amount(prices[offset]),
                priceAmount: prices[offset],
                tokens: tokens,
                savingsPercent: pricing[offset].savingsPercent,
                isBestValue: pricing[offset].isBestValue,
                isSelected: index == 2,
                isAvailable: true
            )
        }
    }
}
