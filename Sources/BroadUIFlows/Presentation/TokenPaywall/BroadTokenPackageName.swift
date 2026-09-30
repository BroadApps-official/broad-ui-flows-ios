import BroadCore
import BroadMonetization

enum BroadTokenPackageName {
    static func displayCount(tokens: Int?, productID: ProductID) -> Int? {
        tokens ?? leadingCount(in: productID.rawValue)
    }

    static func name(count: Int?, copy: BroadTokenPaywallCopy.Products) -> String {
        guard let count, count > 0 else { return copy.fallbackTitle }
        return copy.tokenName.name(for: count)
    }

    private static func leadingCount(in id: String) -> Int? {
        let first = id.split(separator: "_", omittingEmptySubsequences: false).first ?? ""
        if !first.isEmpty, first.unicodeScalars.allSatisfy({ isASCIIDigit($0) }) {
            return Int(first)
        }
        let digits = id.unicodeScalars.prefix(while: isASCIIDigit)
        return digits.isEmpty ? nil : Int(String(id.prefix(digits.count)))
    }

    private static func isASCIIDigit(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value >= 48 && scalar.value <= 57
    }
}
