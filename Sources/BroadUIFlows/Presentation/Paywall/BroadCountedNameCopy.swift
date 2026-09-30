/// Localized noun forms used after a visible quantity.
public struct BroadCountedNameCopy: Equatable, Sendable {
    public let one: String
    public let few: String
    public let many: String
    public let usesRussianPluralRules: Bool

    public init(one: String, few: String, many: String, usesRussianPluralRules: Bool = false) {
        self.one = one
        self.few = few
        self.many = many
        self.usesRussianPluralRules = usesRussianPluralRules
    }

    func name(for count: Int) -> String {
        let lastTwo = count % 100
        let last = count % 10
        let noun: String = if count == 1 {
            one
        } else if !usesRussianPluralRules || lastTwo >= 11 && lastTwo <= 14 {
            many
        } else if last == 1 {
            one
        } else if last >= 2, last <= 4 {
            few
        } else {
            many
        }
        return "\(count) \(noun)"
    }
}
