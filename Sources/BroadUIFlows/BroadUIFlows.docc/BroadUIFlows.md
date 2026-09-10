# ``BroadUIFlows``

Version 3.0.0 requires BroadMonetization 3.0.0 and supports its RU account-policy
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

### Composition

- ``BroadUIFlowsAssembly``
