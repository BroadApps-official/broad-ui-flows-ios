import BroadMonetization

extension MonetizationProduct {
    var isTokenPackage: Bool {
        kind == .consumable && price != nil
    }
}
