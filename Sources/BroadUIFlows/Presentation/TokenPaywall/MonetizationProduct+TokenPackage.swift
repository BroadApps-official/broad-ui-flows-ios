import BroadMonetization

extension MonetizationProduct {
    var isTokenPackage: Bool {
        kind == .consumable && price != nil
    }
}

extension PaywallPayload {
    var isValidTokenPaywallPayload: Bool {
        guard origin.requestedPlacementID == .tokens,
              products.allSatisfy({ $0.kind == .consumable })
        else {
            return false
        }

        if origin.resolvedPlacementID == .tokens {
            return true
        }

        return origin.resolvedPlacementID == .main
            && origin.usedFallback
            && origin.fallbackReason != nil
    }
}
