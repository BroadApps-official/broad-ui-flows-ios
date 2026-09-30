import BroadCore
import BroadMonetization
import Foundation

@main
enum TokenCatalogProbe {
    @MainActor
    static func main() async {
        do {
            try await run()
        } catch {
            print("FAIL: token catalog: \(error)")
            exit(1)
        }
    }

    @MainActor
    static func run() async throws {
        let a = ContractFixtures.product("fixture-a")
        let b = ContractFixtures.product("fixture-b", sku: "fixture-other-sku")
        let duplicate = ContractFixtures.product("fixture-duplicate")
        let subscription = ContractFixtures.product("fixture-subscription", kind: .autoRenewableSubscription, period: .year())
        let nonConsumable = ContractFixtures.product("fixture-non-consumable", kind: .nonConsumable)
        let noPrice = ContractFixtures.product("fixture-no-price", price: nil)
        let catalogs: [(String, [MonetizationProduct])] = [
            ("empty", []), ("one", [a]), ("N", [b, a, duplicate]),
            ("duplicate SKU", [a, duplicate]),
            ("mixed", [subscription, a, nonConsumable, duplicate, noPrice]),
            ("only non-consumable", [nonConsumable]), ("consumable without numeric price", [noPrice])
        ]
        for (name, products) in catalogs {
            try await checkPaths(ContractFixtures.payload(products), accepted: true, label: name)
        }

        // This production predicate also accepts legacy origins that modern
        // BroadMonetization cannot construct (fallback flag without a reason).
        for (name, products) in catalogs {
            let expected = products.allSatisfy { $0.kind == .consumable }
            try require(BroadTokenPaywallPayloadValidator.accepts(
                requestedPlacementID: .tokens, resolvedPlacementID: .main,
                usedFallback: true, products: products
            ) == expected, "main fallback acceptance: \(name)")
            try require(!BroadTokenPaywallPayloadValidator.accepts(
                requestedPlacementID: .tokens, resolvedPlacementID: .main,
                usedFallback: false, products: products
            ), "main without fallback must be rejected")
            try await checkPaths(
                ContractFixtures.payload(products, resolved: .main), accepted: expected, label: "main fallback / \(name)"
            )
        }
        pass("legacy main fallback: flag required, no fallbackReason input; consumables only, including empty/no-price")

        let placements: [PlacementID] = [.main, .settings, .proIcon, .specialOffer, PlacementID(rawValue: "fixture-other")]
        for requested in placements {
            try await checkPaths(ContractFixtures.payload([a], requested: requested), accepted: false, label: "wrong requested / \(requested.rawValue)")
            for resolved in [.tokens] + placements {
                for fallback in [false, true] {
                    try require(!BroadTokenPaywallPayloadValidator.accepts(
                        requestedPlacementID: requested, resolvedPlacementID: resolved,
                        usedFallback: fallback, products: [a]
                    ), "non-token request must be rejected for every resolved placement and fallback flag")
                }
            }
        }
        for resolved in placements where resolved != .main {
            try await checkPaths(ContractFixtures.payload([a], resolved: resolved), accepted: false, label: "wrong resolved / \(resolved.rawValue)")
        }
        pass("other origins: every non-token request/resolved combination is rejected with either fallback flag")
        try await checkPurchases([subscription, nonConsumable, noPrice, a, duplicate])
        try await checkPreloaderLifetime([a])
    }

    @MainActor
    static func checkPaths(_ payload: PaywallPayload, accepted: Bool, label: String) async throws {
        try require(payload.isValidTokenPaywallPayload == accepted, "validator / \(label)")
        let loader = ContractLoader(payload)
        let model = tokenModel(loader: loader)
        model.loadIfNeeded()
        model.loadIfNeeded()
        try await eventually("ordinary load / \(label)") { model.state != .loading }
        let ordinaryCalls = await loader.calls
        try require(ordinaryCalls == 1, "ordinary load must be started once / \(label)")
        if accepted {
            try require(model.state.payload == payload, "ordinary load preserves entire payload / \(label)")
            try require(model.state == (payload.products.isEmpty ? .empty(payload) : .content(payload)), "content phase / \(label)")
            let screen = model.screen(formatter: BroadPaywallProductFormatter(), tokenAmount: nil, close: {})
            try require(screen.packages.map(\.id) == payload.products.map(\.presentationID), "screen preserves order and IDs / \(label)")
            try require(screen.packages.map(\.productID) == payload.products.map(\.productID), "screen preserves duplicate SKUs / \(label)")
        } else {
            guard case .failure = model.state else { throw ContractFailure(description: "ordinary load must fail / \(label)") }
        }

        let preparedLoader = ContractLoader(ContractFixtures.payload([]))
        let tracker = ContractTracker()
        let prepared = tokenModel(loader: preparedLoader, initialPayload: payload, tracker: tracker)
        await prepared.eventTask?.value
        let callsBefore = await preparedLoader.calls
        let shownBefore = await tracker.shown
        try require(callsBefore == 0 && shownBefore.isEmpty, "initialPayload must not load or report shown / \(label)")
        if accepted {
            try require(prepared.state.payload == payload, "initialPayload preserves entire payload / \(label)")
            prepared.loadIfNeeded()
            let callsAfter = await preparedLoader.calls
            try require(callsAfter == 0, "accepted initialPayload must not reload / \(label)")
            prepared.viewDidAppear()
            prepared.viewDidAppear()
            if !payload.products.isEmpty {
                try await eventually("shown after appearance") { await tracker.shown.count == 1 }
                let shown = await tracker.shown
                try require(shown == [payload.presentationID], "impression identity / \(label)")
                prepared.viewDidDisappear()
                try await eventually("close after disappearance") { await tracker.closed.count == 1 }
            } else {
                await prepared.eventTask?.value
                let shown = await tracker.shown
                try require(shown.isEmpty, "empty payload must not report shown")
                prepared.viewDidDisappear()
            }
            let callsAfterAppearance = await preparedLoader.calls
            try require(callsAfterAppearance == 0, "appearance must not reload accepted payload / \(label)")
        } else {
            try require(prepared.state == .idle, "invalid initialPayload must be ignored / \(label)")
            prepared.loadIfNeeded()
            try await eventually("invalid initialPayload regular load") { prepared.state != .loading }
            let calls = await preparedLoader.calls
            try require(calls == 1, "invalid initialPayload must load once / \(label)")
        }

        let preloadLoader = ContractLoader(payload)
        let lifecycle = ContractLifecycle()
        let preloader = BroadPaywallPreloader(loadPaywall: preloadLoader, presentationLifecycle: lifecycle)
        try require(preloader.take(.tokens) == nil, "take before preload must be nil")
        preloader.preload(.tokens)
        preloader.preload(.tokens)
        if accepted {
            var taken: PaywallPayload?
            try await eventually("preload / \(label)") {
                taken = preloader.take(.tokens)
                return taken != nil
            }
            try require(taken == payload, "preloader preserves entire payload / \(label)")
            try require(preloader.take(.tokens) == nil, "take transfers once / \(label)")
            preloader.discardAll()
            let appeared = await lifecycle.appeared
            let ended = await lifecycle.ended
            try require(appeared.isEmpty, "preload must not report presentation appearance")
            try require(ended.isEmpty, "transferred payload must not be released by preloader")
        } else {
            try await eventually("rejected preload release") { await lifecycle.ended.count == 1 }
            try require(preloader.take(.tokens) == nil, "rejected preload must not be transferred")
            let ended = await lifecycle.ended
            try require(ended == [payload.presentationID], "rejected presentation release identity")
        }
        let preloadCalls = await preloadLoader.calls
        try require(preloadCalls == 1, "duplicate preload must load once / \(label)")
        pass("\(label): validator, ordinary load, initialPayload, preload/take; \(accepted ? "accepted" : "rejected")")
    }

    @MainActor
    static func checkPurchases(_ products: [MonetizationProduct]) async throws {
        let mixedPayload = ContractFixtures.payload(products)
        let mixed = tokenModel(loader: ContractLoader(mixedPayload), initialPayload: mixedPayload)
        for product in products where product.isTokenPackage {
            mixed.selectProduct(presentationID: product.presentationID)
            try require(mixed.selectedProductPresentationID == product.presentationID, "duplicate occurrence selects its own presentation ID")
            let screen = mixed.screen(formatter: BroadPaywallProductFormatter(), tokenAmount: nil, close: {})
            try require(screen.packages.filter(\.isSelected).map(\.id) == [product.presentationID], "one exact duplicate occurrence is selected")
            for invalid in products where !invalid.isTokenPackage {
                mixed.selectProduct(presentationID: invalid.presentationID)
                try require(mixed.selectedProductPresentationID == product.presentationID, "invalid mixed row cannot replace a valid selection")
            }
        }
        pass("mixed catalog: duplicate occurrences select by presentation ID; unavailable rows cannot change selection")
        for product in products {
            let payload = ContractFixtures.payload([product])
            let repository = ContractPurchaseRepository()
            let model = tokenModel(loader: ContractLoader(payload), initialPayload: payload, repository: repository)
            let eligible = product.kind == .consumable && product.price != nil
            try require(product.isTokenPackage == eligible && model.canPurchase == eligible, "purchase eligibility")
            model.selectProduct(presentationID: product.presentationID)
            try require((model.selectedProduct != nil) == eligible, "selection eligibility")
            model.purchaseSelectedProduct()
            model.purchaseSelectedProduct()
            try require(model.isPurchaseInFlight == eligible, "synchronous repeated-tap guard")
            if eligible {
                try await eventually("fixture purchase cancellation") { !model.isPurchaseInFlight }
            }
            let purchased = await repository.purchasedIDs
            try require(purchased == (eligible ? [product.presentationID] : []), "only eligible occurrence reaches fixture purchase")
        }
        pass("purchase: only consumables with numeric price; display price alone rejected; repeated tap calls fixture once")
    }

    @MainActor
    static func checkPreloaderLifetime(_ products: [MonetizationProduct]) async throws {
        let payload = ContractFixtures.payload(products)
        let lifecycle = ContractLifecycle()
        let loader = ContractLoader(payload)
        let expiring = BroadPaywallPreloader(loadPaywall: loader, presentationLifecycle: lifecycle, lifetime: .zero)
        expiring.preload(.tokens)
        try await eventually("expiry releases presentation") {
            _ = expiring.take(.tokens)
            return await lifecycle.ended.count == 1
        }
        try require(expiring.take(.tokens) == nil, "expired take must be nil")

        let discardedLifecycle = ContractLifecycle()
        let discardedLoader = ContractLoader(payload)
        let discarded = BroadPaywallPreloader(loadPaywall: discardedLoader, presentationLifecycle: discardedLifecycle)
        discarded.preload(.tokens)
        try await eventually("discard fixture load started") { await discardedLoader.calls == 1 }
        // Both completion and cancellation must release an unused presentation.
        discarded.discardAll()
        try await eventually("discard releases presentation") { await discardedLifecycle.ended.count == 1 }
        discarded.discardAll()
        try require(discarded.take(.tokens) == nil, "discarded take must be nil")
        pass("preloader: freshness expiry and discard release unused presentations")

        let unavailable = ContractLoader(outcome: .unavailable(AppError(
            kind: .unavailable, userMessage: "Fixture unavailable", diagnosticCode: "fixture.unavailable", isRetryable: true
        )))
        let unavailablePreloader = BroadPaywallPreloader(loadPaywall: unavailable, presentationLifecycle: ContractLifecycle())
        unavailablePreloader.preload(.tokens)
        try await eventually("unavailable preload") { await unavailable.calls == 1 }
        try require(unavailablePreloader.take(.tokens) == nil, "unavailable preload must not invent payload")
        unavailablePreloader.discardAll()
        let nilLoader = ContractLoader(payload)
        let nilModel = tokenModel(loader: nilLoader, initialPayload: nil)
        try require(nilModel.state == .idle, "nil initialPayload starts idle")
        nilModel.loadIfNeeded()
        try await eventually("nil initialPayload loads") { nilModel.state.payload == payload }
        pass("nil initialPayload loads normally; unavailable preload returns nil")
    }
}
