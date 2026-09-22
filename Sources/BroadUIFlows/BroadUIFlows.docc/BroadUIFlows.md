# ``BroadUIFlows``

Version 4.1.0 adds the AI data consent screen and the Rate Us prompt rule.
It requires BroadCore 2.0.0 and BroadMonetization 4.0.0.
Update package constraints together. Temporary token fulfillment failures retain
the existing purchase for safe retry. Host exhaustive switches handle the new
`BroadLogEvent.host` and `TokenFulfillmentOutcome.rejected` cases; UI API is unchanged.

The module supports the RU account-policy
confirmation contract. Handle credited tokens separately from subscription access.
Paywall configuration comes from the current placement; main fills missing keys.
Products and variation remain attached to the screen's placement.

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
- ``BroadRUSubscriptionManagementView``

### AI data consent

- ``BroadAIDataConsentView``
- ``BroadAIDataConsentConfiguration``
- ``BroadAIProviderDisclosure``
- ``BroadAIDataConsentCopy``
- ``BroadAIDataConsentTheme``
- ``BroadAIDataConsentStore``
- ``BroadAIDataConsentDecision``

### Rate Us

- ``BroadRateUsPromptPolicy``
- ``BroadRateUsPromptConfiguration``
- ``BroadRateUsPromptContext``

### Composition

- ``BroadUIFlowsAssembly``
