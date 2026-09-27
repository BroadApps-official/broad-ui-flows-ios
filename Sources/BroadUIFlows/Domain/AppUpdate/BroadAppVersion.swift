import Foundation

/// A dotted app version compared component by component as nonnegative integers.
public struct BroadAppVersion: Comparable, Sendable {
    public let rawValue: String
    private let components: [Int]

    public init?(_ rawValue: String) {
        let parts = rawValue.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty,
                  part.allSatisfy({ $0 >= "0" && $0 <= "9" }),
                  let number = Int(part)
            else { return nil }
            numbers.append(number)
        }
        self.rawValue = rawValue
        components = numbers
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        for index in 0 ..< max(lhs.components.count, rhs.components.count) {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}
