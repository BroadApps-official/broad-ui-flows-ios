import BroadMonetization
import Foundation

@main
enum ProductNamesProbe {
    @MainActor
    static func main() {
        do {
            try checkPlans()
            try checkTokens()
        } catch {
            print("FAIL: product names: \(error)")
            exit(1)
        }
    }

    static func checkPlans() throws {
        let periods: [SubscriptionPeriod] = [.week(), .month(), .year(), .month(3)]
        for (copy, expected, language) in [
            (BroadPaywallCopy.standard, ["Weekly", "Monthly", "Yearly", "3 Months"], "standard EN"),
            (.english, ["Weekly", "Monthly", "Yearly", "3 Months"], "EN"),
            (.russian, ["Неделя", "Месяц", "Год", "3 месяца"], "RU")
        ] {
            let names = periods.map { copy.products.name(for: $0, title: "Store title") }
            try require(names == expected, "built-in subscription names / \(language): \(names)")
            try require(copy.products.name(for: .unknown, title: "Store title") == copy.products.fallbackTitle, "unknown period fallback")
            try require(copy.products.name(for: .custom(unit: "fixture-period"), title: nil) == copy.products.fallbackTitle, "custom period fallback")
            pass("subscription names / \(language): \(names.joined(separator: ", ")); unknown/custom fallback")
        }
        let legacy = BroadPaywallCopy.Products(
            fallbackTitle: "Свой тариф", unavailablePriceTitle: "Нет цены", selectedAccessibilityValue: "Выбран"
        )
        let disabled = BroadPaywallCopy.Products(
            fallbackTitle: legacy.fallbackTitle, unavailablePriceTitle: legacy.unavailablePriceTitle,
            selectedAccessibilityValue: legacy.selectedAccessibilityValue, planNames: nil
        )
        try require(legacy.planNames == nil && legacy == disabled, "legacy copy equivalence")
        for period in periods + [.unknown] {
            try require(legacy.name(for: period, title: "Старое название") == "Старое название", "legacy title")
            try require(legacy.name(for: period, title: nil) == "Свой тариф", "legacy fallback")
        }
        let russian = BroadPaywallCopy.russian.products
        let localized = BroadPaywallCopy.Products(
            fallbackTitle: legacy.fallbackTitle, unavailablePriceTitle: legacy.unavailablePriceTitle,
            selectedAccessibilityValue: legacy.selectedAccessibilityValue, planNames: .russian
        )
        try require(localized.name(for: .week(), title: nil) == "Неделя", "custom localized opt-in")
        let sameOldFields = BroadPaywallCopy.Products(
            fallbackTitle: russian.fallbackTitle, unavailablePriceTitle: russian.unavailablePriceTitle,
            selectedAccessibilityValue: russian.selectedAccessibilityValue
        )
        try require(russian != sameOldFields, "enabled built-in differs from legacy copy")
        pass("legacy three-argument subscription copy: title ?? fallbackTitle; explicit nil; localized opt-in; Equatable")
    }

    @MainActor
    static func checkTokens() throws {
        let product = ContractFixtures.product("fixture-named-token", sku: "50_Tokens_9.99")
        let legacyProducts = BroadTokenPaywallCopy.Products(
            fallbackTitle: "Свой пакет", unavailablePriceTitle: "Нет цены", selectedAccessibilityValue: "Выбран"
        )
        let legacy = replacingProducts(legacyProducts)
        let disabledProducts = BroadTokenPaywallCopy.Products(
            fallbackTitle: legacyProducts.fallbackTitle, unavailablePriceTitle: legacyProducts.unavailablePriceTitle,
            selectedAccessibilityValue: legacyProducts.selectedAccessibilityValue, tokenName: nil
        )
        try require(legacyProducts.tokenName == nil && legacyProducts == disabledProducts, "legacy token copy equivalence")

        for (copy, language, backendName, idName) in [
            (BroadTokenPaywallCopy.standard, "standard EN", "2000 Tokens", "50 Tokens"),
            (.english, "EN", "2000 Tokens", "50 Tokens"),
            (.russian, "RU", "2000 токенов", "50 токенов")
        ] {
            let backend = try package(product, backend: 2000, copy: copy)
            try require(backend.name == backendName && backend.tokens == 2000 && backend.displayTokenCount == 2000, "backend quantity wins / \(language)")
            let idOnly = try package(product, backend: nil, copy: copy)
            try require(idOnly.name == idName && idOnly.tokens == nil && idOnly.displayTokenCount == 50, "ID count is display-only / \(language)")
            try require(idOnly.savingsPercent == nil && !idOnly.isBestValue, "ID count must not derive value badges")
            let zero = try package(product, backend: 0, copy: copy)
            try require(zero.name == copy.products.fallbackTitle && zero.tokens == 0 && zero.displayTokenCount == 0, "backend zero prevents ID fallback / \(language)")
            let unknown = try package(ContractFixtures.product("fixture-unknown-name", sku: "fixture-no-leading-count"), backend: nil, copy: copy)
            try require(unknown.name == copy.products.fallbackTitle && unknown.displayTokenCount == nil && unknown.tokens == nil, "unknown quantity fallback")
            pass("token names / \(language): backend 2000 wins; ID 50 display-only; zero/unknown fallback")
        }
        let old = try package(product, backend: nil, copy: legacy)
        let explicitlyDisabled = try package(product, backend: nil, copy: replacingProducts(disabledProducts))
        try require(old.name == product.title && old.tokens == nil && old.displayTokenCount == nil, "disabled names preserve title, no ID quantity")
        try require(old == explicitlyDisabled, "legacy and explicit nil packages are equal")
        let noTitle = try package(ContractFixtures.product("fixture-no-title", sku: "50_Tokens_9.99", title: nil), backend: nil, copy: legacy)
        try require(noTitle.name == legacyProducts.fallbackTitle && noTitle.displayTokenCount == nil, "legacy title nil fallback")
        let enabled = try package(product, backend: nil, copy: .english)
        try require(enabled.id == old.id && enabled.productID == old.productID && enabled.priceAmount == old.priceAmount,
                    "names must not change identity or numeric price")
        try require(enabled.price == old.price && enabled.isSelected == old.isSelected && enabled.isAvailable == old.isAvailable,
                    "names must not change display price, selection or availability")
        try require(enabled != old, "different display names participate in Equatable")
        pass("legacy token copy: title ?? fallbackTitle, displayTokenCount nil; explicit nil; Equatable and unchanged ID/price")

        for (count, expected) in [(1, "1 токен"), (2, "2 токена"), (5, "5 токенов"), (11, "11 токенов"), (21, "21 токен")] {
            let value = try package(product, backend: count, copy: .russian)
            try require(value.name == expected && value.tokens == count, "Russian noun forms / \(count)")
        }
        pass("Russian tokens: 1 токен, 2 токена, 5 токенов, 11 токенов, 21 токен")

        let products = [product, ContractFixtures.product("fixture-named-token-2", sku: "100_Tokens_19.99")]
        let payload = ContractFixtures.payload(products)
        let model = tokenModel(loader: ContractLoader(payload), initialPayload: payload)
        let screen = model.screen(formatter: BroadPaywallProductFormatter(), tokenAmount: nil, close: {})
        try require(screen.packages.map(\.displayTokenCount) == [50, 100], "ID counts display correctly")
        try require(screen.packages.allSatisfy { $0.tokens == nil && $0.savingsPercent == nil && !$0.isBestValue }, "ID counts never used in backend quantity/value comparisons")
        pass("ID-derived names for multiple packages never create backend tokens or savings/best-value")
    }

    @MainActor
    static func package(_ product: MonetizationProduct, backend: Int?, copy: BroadTokenPaywallCopy) throws -> BroadTokenPackage {
        let payload = ContractFixtures.payload([product])
        let model = tokenModel(loader: ContractLoader(payload), initialPayload: payload, copy: copy)
        let screen = model.screen(formatter: BroadPaywallProductFormatter(), tokenAmount: { _ in backend }, close: {})
        guard let package = screen.packages.first else { throw ContractFailure(description: "Missing package") }
        return package
    }

    static func replacingProducts(_ products: BroadTokenPaywallCopy.Products) -> BroadTokenPaywallCopy {
        let base = BroadTokenPaywallCopy.english
        return BroadTokenPaywallCopy(header: base.header, products: products, actions: base.actions, states: base.states, analytics: base.analytics)
    }
}
