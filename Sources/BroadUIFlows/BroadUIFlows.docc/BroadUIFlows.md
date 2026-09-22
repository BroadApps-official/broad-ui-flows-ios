# ``BroadUIFlows``

Version 5.0.0 includes token paywall visibility analytics and optional support diagnostics.
It requires BroadCore 3.0.0 and BroadMonetization 5.0.0.
Update package constraints together. Temporary token fulfillment failures retain
the existing purchase for safe retry. Host exhaustive switches handle the new
`BroadLogEvent.host` and `TokenFulfillmentOutcome.rejected` cases.

Connect the token paywall's optional `trackEvent` dependency to the existing
paywall tracker. The standard view reports shown/closed events in order, once
per presentation; custom views call `viewDidAppear()` and `viewDidDisappear()`.
Use a new view model for a new presentation.

Support email accepts a confirmed token balance only for apps using tokens.
Omit unknown balances. Supply all available current-account IDs, especially the
identifier used to credit tokens, through `additionalIdentifiers`. Empty optional
fields are omitted and embedded newlines are flattened. Base email sections remain.
AI consent placement/copy and Rate Us rules belong to the host application.

Optional billing UI lives in the separate BroadRUBillingUI product. The base paywall accepts an optional checkout-content builder; the Apple-only app uses its normal initializer.

Reusable SwiftUI flows and presentation boundaries for BroadApps iPhone applications.

## Topics

### Application flow

- ``AppFlowCoordinator``
- ``BroadAppFlowView``
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

### Monetization UI

- ``BroadPaywallView``
- ``PaywallViewModel``
- ``BroadTokenPaywallView``

### Support email

- ``BroadSupportEmailConfiguration``
- ``BroadSupportEmailIdentifier``
- ``BroadSupportEmailRequestBuilder``
- ``BroadSupportEmailComposer``

### Composition

- ``BroadUIFlowsAssembly``
