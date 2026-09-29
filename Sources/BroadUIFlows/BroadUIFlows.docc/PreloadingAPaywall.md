# Preloading a paywall

Preload a subscription or token paywall when an action opens it in a sheet or
full-screen cover. A paywall whose layout depends on the number of products can
otherwise change height while the cover animates in.

Keep one ``BroadPaywallPreloader`` with the app flow. Call ``BroadPaywallPreloader/preload(_:)``
when the main screen appears and again after a paywall closes without a purchase.
At the button tap, transfer the prepared payload into a new ``PaywallViewModel``:

```swift
let preloader = BroadPaywallPreloader(dependencies: dependencies)
preloader.preload(.proIcon)
let viewModel = PaywallViewModel(
    configuration: configuration,
    dependencies: dependencies,
    initialPayload: preloader.take(.proIcon)
)
```

If loading is still in flight, `take` returns `nil` and the view model loads on
appearance. A completed load remains available for the next presentation.
Prepared payloads remain fresh for ten minutes by default. A stale or unused
payload is released through `PaywallPresentationLifecycleProtocol.presentationDidEnd(_:)`.
Once `take` returns a payload, the receiving presentation owns its lifecycle.
Preloading never reports a paywall as shown; the view model does that only when
its screen appears.

For a token store, use the token placement and pass its payload to the token
view model before presenting ``BroadTokenPaywallHost`` or
``BroadTokenPaywallView``:

```swift
let preloader = BroadPaywallPreloader(
    loadPaywall: loadPaywall,
    presentationLifecycle: presentationLifecycle
)
// On the presenting screen:
preloader.preload(.tokens)

// Later, when opening the token paywall:
let viewModel = BroadTokenPaywallViewModel(
    configuration: tokenConfiguration,
    dependencies: tokenDependencies,
    initialPayload: preloader.take(.tokens)
)
```

The token view model accepts only a payload requested for `.tokens` with
consumable products. A `.main` fallback also needs a typed fallback origin;
other payloads trigger a regular load. A valid payload supplies packages before
the screen opens. Use the same `loadPaywall` instance in `tokenDependencies`.
The token view is reported as shown only on appearance.

Call ``BroadPaywallPreloader/discardAll()`` after a confirmed purchase or
restore. Special Offer uses its own `prepare` flow in BroadMonetization;
do not routinely preload `special_offer`.
