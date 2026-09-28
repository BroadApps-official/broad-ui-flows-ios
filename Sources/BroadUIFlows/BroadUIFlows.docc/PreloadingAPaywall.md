# Preloading a paywall

Preload a regular subscription paywall when a PRO button or settings action
opens it in a sheet or full-screen cover. A paywall whose layout depends on the
number of products can otherwise change height while the cover animates in.

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

Call ``BroadPaywallPreloader/discardAll()`` after a confirmed purchase or
restore. Do not routinely preload `special_offer` or `tokens`: the offer has
its own `prepare` flow in BroadMonetization, and token paywalls have a separate
presentation flow. Only add either placement when the app has a specific reason.
