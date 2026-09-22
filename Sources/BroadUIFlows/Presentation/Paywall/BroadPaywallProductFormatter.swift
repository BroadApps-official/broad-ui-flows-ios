import BroadMonetization
import Foundation

public struct BroadPaywallPeriodCopy: Equatable, Sendable {
    public struct UnitCopy: Equatable, Sendable {
        public let singular: String
        public let plural: String

        public init(
            singular: String,
            plural: String
        ) {
            self.singular = singular
            self.plural = plural
        }
    }

    public let perPrefix: String
    public let everyPrefix: String
    public let day: UnitCopy
    public let week: UnitCopy
    public let month: UnitCopy
    public let year: UnitCopy
    public let unknownTitle: String?

    public init(
        perPrefix: String,
        everyPrefix: String,
        day: UnitCopy,
        week: UnitCopy,
        month: UnitCopy,
        year: UnitCopy,
        unknownTitle: String? = nil
    ) {
        self.perPrefix = perPrefix
        self.everyPrefix = everyPrefix
        self.day = day
        self.week = week
        self.month = month
        self.year = year
        self.unknownTitle = unknownTitle
    }

    public static let english = BroadPaywallPeriodCopy(
        perPrefix: "per",
        everyPrefix: "every",
        day: UnitCopy(singular: "day", plural: "days"),
        week: UnitCopy(singular: "week", plural: "weeks"),
        month: UnitCopy(singular: "month", plural: "months"),
        year: UnitCopy(singular: "year", plural: "years")
    )
}

public struct BroadPaywallProductFormatter: Sendable {
    public let locale: Locale
    public let periodCopy: BroadPaywallPeriodCopy

    public init(
        locale: Locale = .autoupdatingCurrent,
        periodCopy: BroadPaywallPeriodCopy = .english
    ) {
        self.locale = locale
        self.periodCopy = periodCopy
    }

    public func price(for product: MonetizationProduct) -> String? {
        // A localized provider string is presentation metadata, not proof that
        // the underlying amount/currency was decoded safely. Without Money the
        // row must use the app's explicit unavailable copy.
        guard let money = product.price else {
            return nil
        }

        if let displayPrice = product.displayPrice {
            return displayPrice
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        return formatter.string(from: money.amount as NSDecimalNumber)
    }

    /// A derived amount — a weekly equivalent, a crossed-out price — styled like
    /// the product's own store price.
    ///
    /// Formatting by the device locale is wrong here: with a Russian device and
    /// a US storefront one card would mix the store's dollar sign and decimal
    /// point with a locale-styled "US" prefix and decimal comma from the app.
    /// The store's `displayPrice` is the template:
    /// the text before and after the number, the decimal separator and whether
    /// the currency has a fractional part at all (yen does not). Without a
    /// display price the amount is formatted as a currency of the product.
    ///
    /// - Parameters:
    ///   - amount: The derived amount in the product's currency.
    ///   - product: The product whose store price is the style template.
    /// - Returns: The styled amount, or `nil` when the product has no price.
    public func price(_ amount: Decimal, styledLike product: MonetizationProduct) -> String? {
        guard let money = product.price else {
            return nil
        }
        guard let template = product.displayPrice,
              let range = template.range(
                  of: #"[0-9][0-9.,\u{00A0}\u{202F} ]*[0-9]|[0-9]"#,
                  options: .regularExpression
              )
        else {
            return currency(amount, code: money.currencyCode)
        }

        let prefix = String(template[template.startIndex ..< range.lowerBound])
        let suffix = String(template[range.upperBound...])
        let numeric = template[range].trimmingCharacters(in: .whitespaces)

        // The decimal separator is the last "." or "," followed by one or two
        // digits; otherwise it groups thousands ("¥1,200" has no fraction).
        var separator: String?
        if let last = numeric.lastIndex(where: { character in character == "." || character == "," }) {
            let tail = numeric[numeric.index(after: last)...]
            if (1 ... 2).contains(tail.count), tail.allSatisfy(\.isNumber) {
                separator = String(numeric[last])
            }
        }

        var rounded = Decimal()
        var raw = amount
        NSDecimalRound(&rounded, &raw, separator == nil ? 0 : 2, .plain)

        var digits = "\(rounded)"
        if let separator {
            var parts = digits.components(separatedBy: ".")
            if parts.count == 1 {
                parts.append("")
            }
            while parts[1].count < 2 {
                parts[1] += "0"
            }
            digits = parts[0] + separator + parts[1].prefix(2)
        }
        return prefix + digits + suffix
    }

    private func currency(_ amount: Decimal, code: String) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: amount as NSDecimalNumber)
    }

    public func period(for product: MonetizationProduct) -> String? {
        period(product.subscriptionPeriod)
    }

    public func period(_ period: SubscriptionPeriod) -> String? {
        switch period.unit {
        case .day:
            formattedKnownPeriod(count: period.count, copy: periodCopy.day)
        case .week:
            formattedKnownPeriod(count: period.count, copy: periodCopy.week)
        case .month:
            formattedKnownPeriod(count: period.count, copy: periodCopy.month)
        case .year:
            formattedKnownPeriod(count: period.count, copy: periodCopy.year)
        case let .custom(unit):
            formattedCustomPeriod(count: period.count, unit: unit)
        case .unknown:
            periodCopy.unknownTitle
        }
    }

    private func formattedKnownPeriod(
        count: Int?,
        copy: BroadPaywallPeriodCopy.UnitCopy
    ) -> String? {
        guard let count else {
            return nil
        }

        if count == 1 {
            return "\(periodCopy.perPrefix) \(copy.singular)"
        }

        return "\(periodCopy.everyPrefix) \(count) \(copy.plural)"
    }

    private func formattedCustomPeriod(
        count: Int?,
        unit: String
    ) -> String {
        guard let count else {
            return unit
        }

        if count == 1 {
            return "\(periodCopy.perPrefix) \(unit)"
        }

        return "\(periodCopy.everyPrefix) \(count) \(unit)"
    }
}
