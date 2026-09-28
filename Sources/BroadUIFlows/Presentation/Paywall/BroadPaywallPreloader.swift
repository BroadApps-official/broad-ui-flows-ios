import BroadMonetization
import Foundation

/// Keeps a regular paywall ready while its presenting screen is visible.
/// Loading does not report a paywall impression. Pass a payload from ``take(_:)``
/// to ``PaywallViewModel/init(configuration:dependencies:initialPayload:)``.
@MainActor
public final class BroadPaywallPreloader {
    private struct Prepared {
        let payload: PaywallPayload
        let loadedAt: ContinuousClock.Instant
    }

    private struct PendingLoad {
        let id: UUID
        let task: Task<Void, Never>
    }

    private let loadPaywall: any LoadPaywallUseCaseProtocol
    private let presentationLifecycle: any PaywallPresentationLifecycleProtocol
    private let lifetime: Duration
    private var prepared: [PlacementID: Prepared] = [:]
    private var inFlight: [PlacementID: PendingLoad] = [:]

    /// Creates a preloader with a ten-minute freshness window by default.
    public init(
        loadPaywall: any LoadPaywallUseCaseProtocol,
        presentationLifecycle: any PaywallPresentationLifecycleProtocol,
        lifetime: Duration = .seconds(600)
    ) {
        self.loadPaywall = loadPaywall
        self.presentationLifecycle = presentationLifecycle
        self.lifetime = lifetime
    }

    /// Uses the same loader and lifecycle as the paywall view model.
    public convenience init(
        dependencies: PaywallViewModelDependencies,
        lifetime: Duration = .seconds(600)
    ) {
        self.init(
            loadPaywall: dependencies.loadPaywall,
            presentationLifecycle: dependencies.presentationLifecycle,
            lifetime: lifetime
        )
    }

    /// Starts at most one load for a placement without reporting it as shown.
    public func preload(_ placementID: PlacementID) {
        if let cached = prepared[placementID] {
            guard ContinuousClock.now - cached.loadedAt >= lifetime else {
                return
            }
            prepared[placementID] = nil
            release(cached.payload)
        }

        guard inFlight[placementID] == nil else {
            return
        }

        let id = UUID()
        let loadPaywall = loadPaywall
        let presentationLifecycle = presentationLifecycle
        let task = Task { @MainActor [weak self, loadPaywall, presentationLifecycle] in
            let outcome = await loadPaywall(PaywallLoadRequest(placementID: placementID))
            guard let self, !Task.isCancelled, inFlight[placementID]?.id == id else {
                if case let .loaded(payload) = outcome {
                    await presentationLifecycle.presentationDidEnd(
                        PaywallAnalyticsContext(paywall: payload)
                    )
                }
                return
            }

            inFlight[placementID] = nil
            guard case let .loaded(payload) = outcome else {
                return
            }
            guard payload.origin.requestedPlacementID == placementID else {
                release(payload)
                return
            }
            if let previous = prepared.updateValue(
                Prepared(payload: payload, loadedAt: .now),
                forKey: placementID
            ) {
                release(previous.payload)
            }
        }
        inFlight[placementID] = PendingLoad(id: id, task: task)
    }

    /// Transfers a fresh payload to its caller. An in-flight load returns `nil`.
    public func take(_ placementID: PlacementID) -> PaywallPayload? {
        guard let cached = prepared.removeValue(forKey: placementID) else {
            return nil
        }
        guard ContinuousClock.now - cached.loadedAt < lifetime else {
            release(cached.payload)
            return nil
        }
        return cached.payload
    }

    /// Cancels pending loads and releases every payload that was not taken.
    public func discardAll() {
        for pending in inFlight.values {
            pending.task.cancel()
        }
        inFlight.removeAll()

        for cached in prepared.values {
            release(cached.payload)
        }
        prepared.removeAll()
    }

    deinit {
        for pending in inFlight.values {
            pending.task.cancel()
        }
        let presentationLifecycle = self.presentationLifecycle
        for cached in prepared.values {
            let payload = cached.payload
            Task {
                await presentationLifecycle.presentationDidEnd(
                    PaywallAnalyticsContext(paywall: payload)
                )
            }
        }
    }

    private func release(_ payload: PaywallPayload) {
        let presentationLifecycle = presentationLifecycle
        Task {
            await presentationLifecycle.presentationDidEnd(
                PaywallAnalyticsContext(paywall: payload)
            )
        }
    }
}
