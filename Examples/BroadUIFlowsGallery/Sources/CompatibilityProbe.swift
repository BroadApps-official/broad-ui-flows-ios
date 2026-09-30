import BroadCore
import BroadMonetization
import BroadUIFlows
import Foundation
import SwiftUI

/// Compile-only consumers of legacy APIs. These functions are never called by the Gallery.
@MainActor
enum CompatibilityProbe {
    static func products() {
        let makePlans: (String, String, String) -> BroadPaywallCopy.Products = BroadPaywallCopy.Products.init
        let makeTokens: (String, String, String) -> BroadTokenPaywallCopy.Products = BroadTokenPaywallCopy.Products.init
        _ = makePlans("Тариф", "Недоступно", "Выбрано")
        _ = makeTokens("Пакет", "Недоступно", "Выбрано")
        _ = BroadPaywallCopy.Products(fallbackTitle: "Тариф", unavailablePriceTitle: "Недоступно", selectedAccessibilityValue: "Выбрано")
        _ = BroadTokenPaywallCopy.Products(
            fallbackTitle: "Пакет", unavailablePriceTitle: "Недоступно", selectedAccessibilityValue: "Выбрано"
        )
    }

    static func plans(id: ProductPresentationID, period: SubscriptionPeriod) {
        let make: (
            ProductPresentationID, String?, SubscriptionPeriod, String?, String?, String?, Int?, Bool, Bool, Bool
        ) -> BroadPaywallPlan = BroadPaywallPlan.init
        let makeCompared: (
            ProductPresentationID, String?, SubscriptionPeriod, String?, String?, String?, String?, Int?, Int?, Bool, Bool, Bool
        ) -> BroadPaywallPlan = BroadPaywallPlan.init
        _ = make(id, nil, period, nil, nil, nil, nil, false, false, false)
        _ = makeCompared(id, nil, period, nil, nil, nil, nil, nil, nil, false, false, false)
        _ = BroadPaywallPlan(
            id: id, title: nil, period: period, periodText: nil, price: nil, weeklyPrice: nil,
            savingsPercent: nil, isBestValue: false, isSelected: false, isAvailable: false
        )
        _ = BroadPaywallPlan(
            id: id, title: nil, period: period, periodText: nil, price: nil, weeklyPrice: nil,
            regularPrice: nil, discountPercent: nil, savingsPercent: nil,
            isBestValue: false, isSelected: false, isAvailable: false
        )
    }

    static func packages(id: ProductPresentationID, productID: ProductID) {
        let make: (
            ProductPresentationID, ProductID, String?, String?, String?, Int?, Bool, Bool
        ) -> BroadTokenPackage = BroadTokenPackage.init
        let makeCompared: (
            ProductPresentationID, ProductID, String?, String?, String?, Money?, Int?, Int?, Bool, Bool, Bool
        ) -> BroadTokenPackage = BroadTokenPackage.init
        _ = make(id, productID, nil, nil, nil, nil, false, false)
        _ = makeCompared(id, productID, nil, nil, nil, nil, nil, nil, false, false, false)
        _ = BroadTokenPackage(
            id: id, productID: productID, title: nil, subtitle: nil, price: nil,
            tokens: nil, isSelected: false, isAvailable: false
        )
        _ = BroadTokenPackage(
            id: id, productID: productID, title: nil, subtitle: nil, price: nil, priceAmount: nil,
            tokens: nil, savingsPercent: nil, isBestValue: false, isSelected: false, isAvailable: false
        )
    }

    static func tokenViewModel(configuration: BroadTokenPaywallConfiguration, dependencies: BroadTokenPaywallViewModelDependencies) {
        let make: @MainActor (
            BroadTokenPaywallConfiguration, BroadTokenPaywallViewModelDependencies
        ) -> BroadTokenPaywallViewModel = BroadTokenPaywallViewModel.init
        _ = make(configuration, dependencies)
        _ = BroadTokenPaywallViewModel(configuration: configuration, dependencies: dependencies)
    }

    static func tokenView(viewModel: BroadTokenPaywallViewModel) {
        let make: @MainActor (
            BroadTokenPaywallViewModel, BroadPaywallTheme, BroadPaywallProductFormatter, @escaping @MainActor () -> Void
        ) -> BroadTokenPaywallView = BroadTokenPaywallView.init
        _ = make(viewModel, .standard, BroadPaywallProductFormatter()) {}
        _ = BroadTokenPaywallView(viewModel: viewModel, theme: .standard, onClose: {})
        _ = BroadTokenPaywallView(viewModel: viewModel, theme: .standard) {}
        _ = BroadTokenPaywallView(viewModel: viewModel, theme: .standard, productFormatter: BroadPaywallProductFormatter()) {}
        let tokenAmount: @MainActor (MonetizationProduct) -> Int? = { _ in nil }
        _ = BroadTokenPaywallView(viewModel: viewModel, theme: .standard, tokenAmount: tokenAmount) {}
    }

    static func settings(configuration: BroadSettingsConfiguration, restore: any RestorePurchasesUseCaseProtocol) {
        let showPaywall: @MainActor () -> Void = {}
        let onRestored: @MainActor (EntitlementSnapshot) -> Void = { _ in }
        _ = BroadSettingsHost(configuration: configuration, showPaywall: showPaywall, restorePurchases: restore) { screen in
            Text(screen.userID)
        }
        _ = BroadSettingsHost(
            configuration: configuration, showPaywall: showPaywall, restorePurchases: restore, onRestored: onRestored
        ) { screen in
            Text(screen.userID)
        }
    }

    static func historicalSettings(url: URL, support: BroadSupportEmailConfiguration?) {
        let makeInferredCopy = BroadSettingsCopy.init
        _ = makeInferredCopy("Restored", "Nothing found")
        let makeCopy: (String, String) -> BroadSettingsCopy = BroadSettingsCopy.init
        _ = makeCopy("Restored", "Nothing found")
        _ = BroadSettingsCopy(restoredMessage: "Restored", nothingToRestoreMessage: "Nothing found")
        let makeInferredConfiguration = BroadSettingsConfiguration.init
        _ = makeInferredConfiguration("fixture", url, url, url, support, nil, nil, .russian)
        let makeConfiguration: (
            String, URL, URL, URL, BroadSupportEmailConfiguration?, String?, String?, BroadSettingsCopy
        ) -> BroadSettingsConfiguration = BroadSettingsConfiguration.init
        let configuration = makeConfiguration("fixture", url, url, url, support, nil, nil, .russian)
        let legacyURL: URL = configuration.appStoreURL
        _ = legacyURL
        _ = BroadSettingsConfiguration(userID: "fixture", appStoreURL: url, privacyPolicyURL: url, termsURL: url)
        let makeInferredScreen = BroadSettingsScreen.init
        _ = makeInferredScreen("fixture", "1", "1", false, nil, nil, false, false)
        let makeScreen: @MainActor (
            String, String, String, Bool, BroadSettingsRestoreResult?, String?, Bool, Bool
        ) -> BroadSettingsScreen = BroadSettingsScreen.init
        let screen = makeScreen("fixture", "1", "1", false, nil, nil, false, false)
        _ = BroadSettingsScreen(userID: "fixture", version: "1", build: "1")
        _ = BroadSettingsScreen.preview()
        screen.shareApp()
        screen.rateApp()
        screen.contactSupport()
    }

    static func historicalSettingsHost(configuration: BroadSettingsConfiguration, restore: any RestorePurchasesUseCaseProtocol) {
        let makeInferred = BroadSettingsHost<Text>.init
        _ = makeInferred(configuration, {}, restore, { _ in }, { Text($0.userID) })
        let make: @MainActor (
            BroadSettingsConfiguration, @escaping @MainActor () -> Void,
            any RestorePurchasesUseCaseProtocol, @escaping @MainActor (EntitlementSnapshot) -> Void,
            @escaping @MainActor (BroadSettingsScreen) -> Text
        ) -> BroadSettingsHost<Text> = BroadSettingsHost<Text>.init
        _ = make(configuration, {}, restore, { _ in }, { Text($0.userID) })
    }

    static func historicalOnboarding(viewModel: OnboardingViewModel) {
        let makeViewModel = OnboardingViewModel.init
        let makeTypedViewModel: @MainActor (
            OnboardingConfiguration, any TrackingAuthorizationUseCaseProtocol
        ) -> OnboardingViewModel = OnboardingViewModel.init
        _ = makeViewModel
        _ = makeTypedViewModel
        let makeHost = BroadOnboardingFlowHost<Text>.init
        let makeTypedHost: @MainActor (
            OnboardingViewModel, @escaping @MainActor () -> Void,
            @escaping @MainActor (OnboardingViewModel, OnboardingFlowActions) -> Text
        ) -> BroadOnboardingFlowHost<Text> = BroadOnboardingFlowHost<Text>.init
        _ = makeHost(viewModel, {}, { model, _ in Text(model.currentPage?.title ?? "") })
        _ = makeTypedHost(viewModel, {}, { model, _ in Text(model.currentPage?.title ?? "") })
        let policy: (Duration) -> OnboardingTrackingAuthorizationPolicy = OnboardingTrackingAuthorizationPolicy.afterFirstSlide
        _ = policy(.milliseconds(400))
        _ = OnboardingTrackingAuthorizationPolicy.afterFirstSlide()
        let onCompleted: @MainActor () -> Void = {}
        _ = BroadOnboardingFlowHost(viewModel: viewModel, onCompleted: onCompleted) { model, actions in
            Button(model.currentPage?.title ?? "") { actions.advance() }
        }
        _ = BroadOnboardingView(viewModel: viewModel) { media in
            Text(media.identifier)
        } onFooterAction: { _ in } onCompleted: {}
        viewModel.onboardingDidAppear()
        viewModel.firstSlideDidAppear()
        viewModel.firstSlideDidDisappear()
        viewModel.windowVisibilityDidChange(true)
        viewModel.onboardingDidDisappear()
    }

    static func historicalPaywallConfiguration(placementID: PlacementID) {
        let make: (
            PlacementID, BroadPaywallDefaultSelection?, BroadPaywallAccessConfiguration, BroadPaywallCopy,
            [BroadPaywallLegalLink], BroadPaywallSpecialOfferCopy, SpecialOfferPresentationAuthorization?
        ) -> BroadPaywallConfiguration = BroadPaywallConfiguration.init
        let makeOrdered: (
            PlacementID, BroadPaywallDefaultSelection?, BroadPaywallAccessConfiguration, BroadPaywallCopy,
            [BroadPaywallLegalLink], BroadPaywallSpecialOfferCopy, SpecialOfferPresentationAuthorization?, BroadPaywallProductOrder
        ) -> BroadPaywallConfiguration = BroadPaywallConfiguration.init
        _ = make(placementID, nil, BroadPaywallAccessConfiguration(), .standard, [], .english, nil)
        _ = makeOrdered(placementID, nil, BroadPaywallAccessConfiguration(), .standard, [], .english, nil, .longestPeriodFirst)
        _ = BroadPaywallConfiguration(placementID: placementID)
        _ = BroadPaywallConfiguration(placementID: placementID, productOrder: .longestPeriodFirst)
        _ = BroadPaywallConfiguration(placementID: placementID, referenceProducts: [])
    }

    static func historicalTokenConfiguration() {
        let make: (BroadTokenPaywallCopy, Int) -> BroadTokenPaywallConfiguration = BroadTokenPaywallConfiguration.init
        let makeAnalytics: (BroadTokenPaywallCopy, Int, Bool) -> BroadTokenPaywallConfiguration = BroadTokenPaywallConfiguration.init
        let makeDelayed: (
            BroadTokenPaywallCopy, Int, TimeInterval, Bool
        ) -> BroadTokenPaywallConfiguration = BroadTokenPaywallConfiguration.init
        _ = make(.russian, 0)
        _ = makeAnalytics(.russian, 0, false)
        _ = makeDelayed(.russian, 0, 0, false)
        _ = BroadTokenPaywallConfiguration(copy: .russian)
        _ = BroadTokenPaywallConfiguration(copy: .russian, showsAnalytics: true)
        _ = BroadTokenPaywallConfiguration(copy: .russian, closeDelay: 3)
    }

    static func historicalTokenActions() {
        let make: (
            String, String, String, String, String, String, String
        ) -> BroadTokenPaywallCopy.Actions = BroadTokenPaywallCopy.Actions.init
        let makeConfirming: (
            String, String, String, String, String, String, String, String, String
        ) -> BroadTokenPaywallCopy.Actions = BroadTokenPaywallCopy.Actions.init
        _ = make("Buy", "Buying", "Retry", "Retrying", "Refresh", "Refreshing", "Close")
        _ = makeConfirming("Buy", "Buying", "Retry", "Retrying", "Refresh", "Refreshing", "Close", "Check", "Checking")
        _ = BroadTokenPaywallCopy.Actions(
            purchaseTitle: "Buy", purchasingTitle: "Buying", retryTitle: "Retry", retryingTitle: "Retrying",
            recoverBalanceTitle: "Refresh", recoveringBalanceTitle: "Refreshing", closeAccessibilityLabel: "Close"
        )
        _ = BroadTokenPaywallCopy.Actions(
            purchaseTitle: "Buy", purchasingTitle: "Buying", retryTitle: "Retry", retryingTitle: "Retrying",
            recoverBalanceTitle: "Refresh", recoveringBalanceTitle: "Refreshing",
            closeAccessibilityLabel: "Close", confirmingTitle: "Checking"
        )
        _ = BroadTokenPaywallCopy.Actions(
            purchaseTitle: "Buy", purchasingTitle: "Buying", retryTitle: "Retry", retryingTitle: "Retrying",
            recoverBalanceTitle: "Refresh", recoveringBalanceTitle: "Refreshing", closeAccessibilityLabel: "Close", confirmTitle: "Check"
        )
    }

    static func historicalDiscountCopy() {
        let make: (String, String, String, String) -> BroadPaywallSpecialOfferCopy = BroadPaywallSpecialOfferCopy.init
        let makeDiscount: (String, String, String, String, String) -> BroadPaywallSpecialOfferCopy = BroadPaywallSpecialOfferCopy.init
        _ = make("Previous", "Value", "Remaining", "Ended")
        _ = makeDiscount("Previous", "Value", "Remaining", "Ended", "%d%% OFF")
        _ = BroadPaywallSpecialOfferCopy(
            crossedValueAccessibilityLabel: "Previous", multiplierAccessibilityLabel: "Value", countdownAccessibilityLabel: "Remaining"
        )
    }

    static func historicalTokenPreview() {
        let make: @MainActor (
            BroadTokenPaywallScreen.PreviewState, BroadPaywallProductFormatter
        ) -> BroadTokenPaywallScreen = BroadTokenPaywallScreen.preview
        let makeCopy: @MainActor (
            BroadTokenPaywallScreen.PreviewState, BroadPaywallProductFormatter, BroadTokenPaywallCopy
        ) -> BroadTokenPaywallScreen = BroadTokenPaywallScreen.preview
        _ = make(.packages, BroadPaywallProductFormatter())
        _ = makeCopy(.packages, BroadPaywallProductFormatter(), .english)
        _ = BroadTokenPaywallScreen.preview()
        _ = BroadTokenPaywallScreen.preview(.pending)
        _ = BroadTokenPaywallScreen.preview(.pending, copy: .english)
    }
}
