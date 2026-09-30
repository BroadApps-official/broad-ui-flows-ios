import BroadMonetization

/// Names for subscription periods shown on a paywall.
public struct BroadPaywallPlanNameCopy: Equatable, Sendable {
    public let daily: String
    public let weekly: String
    public let monthly: String
    public let yearly: String
    public let days: BroadCountedNameCopy
    public let weeks: BroadCountedNameCopy
    public let months: BroadCountedNameCopy
    public let years: BroadCountedNameCopy

    public init(
        daily: String,
        weekly: String,
        monthly: String,
        yearly: String,
        days: BroadCountedNameCopy,
        weeks: BroadCountedNameCopy,
        months: BroadCountedNameCopy,
        years: BroadCountedNameCopy
    ) {
        self.daily = daily
        self.weekly = weekly
        self.monthly = monthly
        self.yearly = yearly
        self.days = days
        self.weeks = weeks
        self.months = months
        self.years = years
    }

    public static let english = BroadPaywallPlanNameCopy(
        daily: "Daily", weekly: "Weekly", monthly: "Monthly", yearly: "Yearly",
        days: BroadCountedNameCopy(one: "Day", few: "Days", many: "Days"),
        weeks: BroadCountedNameCopy(one: "Week", few: "Weeks", many: "Weeks"),
        months: BroadCountedNameCopy(one: "Month", few: "Months", many: "Months"),
        years: BroadCountedNameCopy(one: "Year", few: "Years", many: "Years")
    )

    public static let russian = BroadPaywallPlanNameCopy(
        daily: "День", weekly: "Неделя", monthly: "Месяц", yearly: "Год",
        days: BroadCountedNameCopy(one: "день", few: "дня", many: "дней", usesRussianPluralRules: true),
        weeks: BroadCountedNameCopy(one: "неделя", few: "недели", many: "недель", usesRussianPluralRules: true),
        months: BroadCountedNameCopy(one: "месяц", few: "месяца", many: "месяцев", usesRussianPluralRules: true),
        years: BroadCountedNameCopy(one: "год", few: "года", many: "лет", usesRussianPluralRules: true)
    )

    func name(for period: SubscriptionPeriod, fallback: String) -> String {
        guard let count = period.count, count > 0 else { return fallback }
        return switch period.unit {
        case .day: count == 1 ? daily : days.name(for: count)
        case .week: count == 1 ? weekly : weeks.name(for: count)
        case .month: count == 1 ? monthly : months.name(for: count)
        case .year: count == 1 ? yearly : years.name(for: count)
        case .custom, .unknown: fallback
        }
    }
}
