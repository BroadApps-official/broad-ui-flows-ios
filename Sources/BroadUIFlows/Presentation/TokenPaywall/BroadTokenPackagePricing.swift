import BroadMonetization
import Foundation

/// Per-token comparisons for one complete, same-currency package catalog.
enum BroadTokenPackagePricing {
    struct Presentation {
        let savingsPercent: Int?
        let isBestValue: Bool
    }

    static func presentations(prices: [Money?], tokens: [Int?]) -> [Presentation] {
        let empty = Array(repeating: Presentation(savingsPercent: nil, isBestValue: false), count: prices.count)
        guard prices.count == tokens.count, prices.count > 1,
              let currency = prices.first.flatMap({ $0 })?.currencyCode
        else { return empty }

        var rates: [Decimal] = []
        for (price, count) in zip(prices, tokens) {
            guard let price, price.currencyCode == currency, price.amount > 0,
                  let count, count > 0
            else { return empty }
            rates.append(price.amount / Decimal(count))
        }

        guard let reference = rates.max(), reference > 0 else { return empty }
        let savings: [Int?] = rates.map { rate in
            guard rate < reference else { return nil }
            let ratio = (reference - rate) / reference * 100
            let percent = Int(NSDecimalNumber(decimal: ratio).doubleValue.rounded())
            return percent > 0 ? percent : nil
        }
        let bestIndex = savings.indices.reduce(nil as Int?) { best, index in
            guard let percent = savings[index], percent > (best.flatMap { savings[$0] } ?? 0) else {
                return best
            }
            return index
        }
        return savings.enumerated().map { index, percent in
            Presentation(savingsPercent: percent, isBestValue: index == bestIndex)
        }
    }
}
