# ``BroadUIFlows``

Version 6.1.0 adds BroadPaywallHost: a custom paywall screen gets ready plans, the purchase activity and typed notices and only lays them out. Version 6.0.0 shows subscriptions from the longest period to the shortest and selects the longest one on open. Version 5.0.1 removed the Bundle line from the support email. Version 5.0.0 added token paywall visibility analytics and optional support diagnostics.
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

The settings host supplies gated actions and a typed restore result to an app-owned
layout. The update checker compares numeric version components and offers an App
Store update from the main tab after a successful lookup. These are additive public
APIs intended for the next minor release; this worktree keeps the 6.1.0 version.

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
