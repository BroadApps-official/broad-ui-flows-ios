# ``BroadUIFlows``

Version 2.0.0 requires BroadMonetization 2.0.0. Paywall configuration comes
from the selected `main` variant for every screen, while products and variation
remain attached to the screen's placement. Move shared flags and RU experiment
codes to main before upgrading. Special Offer authorization carries the latest
main configuration obtained while loading the offer's own products.

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
