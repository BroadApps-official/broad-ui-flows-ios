import BroadMonetization

extension MonetizationProduct {
    var isTokenPackage: Bool {
        kind == .consumable && price != nil
    }
}

extension PaywallPayload {
    var isValidTokenPaywallPayload: Bool {
        BroadTokenPaywallPayloadValidator.accepts(
            requestedPlacementID: origin.requestedPlacementID,
            resolvedPlacementID: origin.resolvedPlacementID,
            usedFallback: origin.usedFallback,
            products: products
        )
    }
}

/// Keeps the UIFlows acceptance policy independent of origin construction rules.
enum BroadTokenPaywallPayloadValidator {
    static func accepts(
        requestedPlacementID: PlacementID,
        resolvedPlacementID: PlacementID,
        usedFallback: Bool,
        products: [MonetizationProduct]
    ) -> Bool {
        guard requestedPlacementID == .tokens else {
            return false
        }

        if resolvedPlacementID == .tokens {
            return true
        }

        return resolvedPlacementID == .main
            && usedFallback
            && products.allSatisfy { $0.kind == .consumable }
    }
}
