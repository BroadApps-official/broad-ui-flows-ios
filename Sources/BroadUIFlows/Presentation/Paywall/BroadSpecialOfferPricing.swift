import BroadMonetization
import Foundation

/// Crossed-out price and discount derived from products shown on the regular paywall.
struct BroadSpecialOfferPricing {
    let regularPrice: String
    let discountPercent: Int

    static func make(
        offer: MonetizationProduct,
        reference: [MonetizationProduct],
        formatter: BroadPaywallProductFormatter
    ) -> BroadSpecialOfferPricing? {
        guard let offerPrice = offer.price else { return nil }
        let regular = reference
            .filter { candidate in
                guard let price = candidate.price else { return false }
                return candidate.subscriptionPeriod == offer.subscriptionPeriod
                    && price.currencyCode == offerPrice.currencyCode
                    && price.amount > offerPrice.amount
            }
            .min { lhs, rhs in
                (lhs.price?.amount ?? 0) < (rhs.price?.amount ?? 0)
            }
        guard let regular,
              let regularPrice = regular.price,
              let regularText = formatter.price(for: regular)
        else { return nil }

        guard let percent = discountPercent(offer: offerPrice, regular: regularPrice) else { return nil }
        return BroadSpecialOfferPricing(regularPrice: regularText, discountPercent: percent)
    }

    static func discountPercent(offer: Money, regular: Money) -> Int? {
        guard offer.currencyCode == regular.currencyCode, regular.amount > offer.amount else { return nil }
        let ratio = NSDecimalNumber(decimal: offer.amount / regular.amount).doubleValue
        let percent = Int(((1 - ratio) * 100).rounded())
        return (1 ... 99).contains(percent) ? percent : nil
    }
}
