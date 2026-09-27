import BroadMonetization
import Foundation

/// Display order of paywall products. The provider payload itself is never changed.
public enum BroadPaywallProductOrder: Equatable, Sendable {
    /// Longest subscription period first. Equal periods and products without a known
    /// period keep the provider order; products without a known period go last.
    case longestPeriodFirst
    /// The order the provider returned.
    case provider

    public func arrange(_ products: [MonetizationProduct]) -> [MonetizationProduct] {
        switch self {
        case .provider:
            products
        case .longestPeriodFirst:
            products.enumerated()
                .sorted { lhs, rhs in
                    Self.precedes(lhs, rhs)
                }
                .map(\.element)
        }
    }

    private static func precedes(
        _ lhs: EnumeratedSequence<[MonetizationProduct]>.Element,
        _ rhs: EnumeratedSequence<[MonetizationProduct]>.Element
    ) -> Bool {
        switch (approximateDays(lhs.element.subscriptionPeriod), approximateDays(rhs.element.subscriptionPeriod)) {
        case let (left?, right?) where left != right:
            left > right
        case (.some, nil):
            true
        case (nil, .some):
            false
        default:
            lhs.offset < rhs.offset
        }
    }

    private static func approximateDays(_ period: SubscriptionPeriod) -> Int? {
        guard let count = period.count else { return nil }
        switch period.unit {
        case .day:
            return count
        case .week:
            return count * 7
        case .month:
            return count * 30
        case .year:
            return count * 365
        case .custom, .unknown:
            return nil
        }
    }
}
