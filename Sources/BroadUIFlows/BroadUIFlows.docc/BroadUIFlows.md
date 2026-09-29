# ``BroadUIFlows``

Version 6.2.0 adds BroadTokenPaywallHost, BroadSettingsHost and the App Store update alert, so token, settings and main-tab screens from Figma are layout only. Version 6.1.0 adds BroadPaywallHost: a custom paywall screen gets ready plans, the purchase activity and typed notices and only lays them out. Version 6.0.0 shows subscriptions from the longest period to the shortest and selects the longest one on open. Version 5.0.1 removed the Bundle line from the support email. Version 5.0.0 added token paywall visibility analytics and optional support diagnostics.
It requires BroadCore 3.0.0 and BroadMonetization 5.0.0.
Update package constraints together. Temporary token fulfillment failures retain
the existing purchase for safe retry. Host exhaustive switches handle the new
`BroadLogEvent.host` and `TokenFulfillmentOutcome.rejected` cases.

Connect the token paywall's optional `trackEvent` dependency to the existing
paywall tracker. The standard view reports shown/closed events in order, once
per presentation; custom views call `viewDidAppear()` and `viewDidDisappear()`.
Use a new view model for a new presentation.

To show token packages as soon as the screen opens, preload `.tokens` with
``BroadPaywallPreloader`` and pass `take(.tokens)` to
``BroadTokenPaywallViewModel/init(configuration:dependencies:initialPayload:)``.
The payload is validated using the same placement and consumable rules as a
regular load; an invalid payload triggers a regular load. See
<doc:PreloadingAPaywall> and the Gallery's preloaded token paywall.

Support email accepts a confirmed token balance only for apps using tokens.
Omit unknown balances. Supply all available current-account IDs, especially the
identifier used to credit tokens, through `additionalIdentifiers`. Empty optional
fields are omitted and embedded newlines are flattened. Base email sections remain.
AI consent placement/copy and Rate Us rules belong to the host application.

Optional billing UI lives in the separate BroadRUBillingUI product. The base paywall accepts an optional checkout-content builder; the Apple-only app uses its normal initializer.

Reusable SwiftUI flows and presentation boundaries for BroadApps iPhone applications.

Custom paywall screens can dismiss a typed notice through
``BroadPaywallScreen/dismissNotice()``. For a Special Offer, pass the closed
regular paywall's products as `BroadPaywallConfiguration.referenceProducts`;
matching period and currency yield `BroadPaywallPlan.regularPrice` and
`discountPercent` only when the regular price is higher. Token hosts expose
verified `BroadTokenPackage.priceAmount`, per-token `savingsPercent`, and one
`isBestValue` badge when every displayed package can be compared. Set
`BroadAppFlowView(transition:)` to ``BroadAppFlowTransition/slide`` for route
movement; Reduce Motion uses a fade, while the default keeps immediate changes.

### Token paywall copy and close delay

Use ``BroadTokenPaywallCopy/english`` or ``BroadTokenPaywallCopy/standard``
for the English token store; ``BroadTokenPaywallCopy/russian`` remains available.
Set ``BroadTokenPaywallConfiguration/closeDelay`` when the close button should
appear after the token paywall opens:

```swift
let configuration = BroadTokenPaywallConfiguration(
    copy: .english,
    closeDelay: 3
)
```

The default delay is zero. Both ``BroadTokenPaywallHost`` and
``BroadTokenPaywallView`` enforce the delay; a custom screen draws its close
action only when ``BroadTokenPaywallScreen/canClose`` is true. The delay starts
on appearance, is cancelled on disappearance, and starts again on a later
appearance. Purchases and checks still block closing. Reduce Motion does not
change this timer. Automatic balance recovery updates the confirmed balance
without a notice; an explicit refresh can show the recovered or failed notice.
For an English fixture notice, use
`BroadTokenPaywallScreen.preview(.pending, copy: .english)`.

### Custom Special Offer screen

The `special_offer` placement should contain one product. Draw
``BroadPaywallScreen/specialOfferPlan`` as one card without a plan selector.
If a provider returns additional products, ``BroadPaywallScreen/plans`` keeps
them, while `specialOfferPlan` remains the first plan in display order and is
the plan selected for purchase. Read both the discount heading and the crossed
regular price from that same plan so the layout does not shift with selection:

```swift
if let plan = screen.specialOfferPlan {
    if let discount = plan.discountPercent {
        Text("\(discount)% OFF")
    }
    OfferCard(price: plan.price, regularPrice: plan.regularPrice)
}
```

Use ``BroadPaywallScreen/preview(_:formatter:)`` with `.specialOffer` and
``BroadPaywallScreen/previewSpecialOfferWithTwoProducts(formatter:)`` to inspect
both catalogs; each draws one card.

The settings host supplies gated actions and a typed restore result to an app-owned
layout. The update checker compares numeric version components and offers an App
Store update from the main tab after a successful lookup.

## Topics

### Application flow

- ``AppFlowCoordinator``
- ``BroadAppFlowView``
- ``BroadAppFlowTransition``
- ``AppFlowConfiguration``

### Onboarding

- ``BroadOnboardingView``
- ``BroadOnboardingFlowHost``
- ``OnboardingConfiguration``
- ``OnboardingViewModel``

### Loadable states

- ``BroadLoadableView``
- ``BroadLoaderView``
- ``BroadErrorView``
- ``BroadEmptyView``
- ``BroadStaleBanner``

### Custom screens

A screen drawn from a Figma frame sits inside a host and only lays out the
ready screen model.

- ``BroadPaywallHost``
- ``BroadPaywallScreen``
- ``BroadPaywallPlan``
- ``BroadPaywallNotice``
- ``BroadTokenPaywallHost``
- ``BroadTokenPaywallScreen``
- ``BroadTokenPackage``

### Monetization UI

- ``BroadPaywallView``
- ``PaywallViewModel``
- ``BroadPaywallPreloader``
- <doc:PreloadingAPaywall>
- ``BroadTokenPaywallView``
- ``BroadTokenPaywallViewModel``
- ``BroadTokenPaywallConfiguration``
- ``BroadTokenPaywallCopy``

### Support email

- ``BroadSupportEmailConfiguration``
- ``BroadSupportEmailIdentifier``
- ``BroadSupportEmailRequestBuilder``
- ``BroadSupportEmailComposer``

### Settings and updates

- ``BroadSettingsConfiguration``
- ``BroadSettingsHost``
- ``BroadSettingsScreen``
- ``BroadSettingsRestoreResult``
- ``BroadAppVersion``
- ``BroadAppUpdateChecker``
- ``BroadAppStoreLookupProtocol``
- ``BroadAppVersionBaselineStoreProtocol``

### Composition

- ``BroadUIFlowsAssembly``
