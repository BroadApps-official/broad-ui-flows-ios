import BroadCore
import BroadMonetization
import Foundation

struct ContractFailure: Error, CustomStringConvertible {
    let description: String
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw ContractFailure(description: message) }
}

func pass(_ message: String) {
    print("PASS: \(message)")
}

@MainActor
func eventually(_ message: String, _ condition: () async -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(3)
    while !(await condition()) {
        guard ContinuousClock.now < deadline else { throw ContractFailure(description: "Timeout: \(message)") }
        try await Task.sleep(for: .milliseconds(5))
    }
}

enum ContractFixtures {
    static func product(
        _ occurrence: String,
        sku: String = "fixture-token-sku",
        kind: MonetizationProductKind = .consumable,
        price: Money? = Money(amount: 9.99, currencyCode: "USD"),
        title: String? = "Store title",
        period: SubscriptionPeriod = .unknown
    ) -> MonetizationProduct {
        MonetizationProduct(
            presentationID: ProductPresentationID(rawValue: occurrence),
            reference: ProductReference(rawValue: "fixture-\(occurrence)"),
            productID: ProductID(rawValue: sku),
            kind: kind,
            title: title,
            price: price,
            displayPrice: "$9.99",
            subscriptionPeriod: period,
            catalogSource: .storeKit
        )
    }

    static func payload(
        _ products: [MonetizationProduct],
        requested: PlacementID = .tokens,
        resolved: PlacementID = .tokens
    ) -> PaywallPayload {
        PaywallPayload(
            presentationID: .generated(),
            paywallReference: PaywallReference(rawValue: "fixture-contract-paywall"),
            origin: PaywallOrigin(
                requestedPlacementID: requested,
                resolvedPlacementID: resolved,
                catalogSource: .storeKit,
                fallbackReason: requested == resolved ? nil : .unavailable
            ),
            products: products,
            fetchedAt: Date()
        )
    }
}

actor ContractLoader: LoadPaywallUseCaseProtocol {
    let outcome: PaywallLoadOutcome
    private(set) var calls = 0

    init(_ payload: PaywallPayload) { outcome = .loaded(payload) }

    init(outcome: PaywallLoadOutcome) { self.outcome = outcome }

    func callAsFunction(_: PaywallLoadRequest) async -> PaywallLoadOutcome {
        calls += 1
        return outcome
    }
}

struct ContractSelector: SelectProductUseCaseProtocol {
    func callAsFunction(productPresentationID: ProductPresentationID, in paywall: PaywallPayload) -> ProductSelection? {
        paywall.products.first { $0.presentationID == productPresentationID }.map {
            ProductSelection(paywall: paywall, product: $0)
        }
    }
}

actor ContractPurchaseRepository: PurchaseRepositoryProtocol {
    private(set) var purchasedIDs: [ProductPresentationID] = []

    func purchase(_ request: PurchaseRequest) async -> PurchaseAttemptOutcome {
        purchasedIDs.append(request.selection.product.presentationID)
        return .cancelled
    }
}

struct ContractEvidence: TokenTransactionEvidenceProviderProtocol {
    func evidence(productID _: ProductID, purchasedAfter _: Date) async -> TokenEvidenceResolution { .notFound }
}

struct ContractFulfillment: TokenFulfillmentRepositoryProtocol {
    func fulfill(_: TokenFulfillmentRequest) async -> TokenFulfillmentOutcome { .pending }
}

actor ContractPendingStore: PendingTokenPurchaseStoreProtocol {
    nonisolated let pendingOperationBlockerKey = PendingOperationBlockerKey(
        kind: .tokenPurchase,
        applicationIdentifier: "broad-ui-contract-probe"
    )
    private var pending: PendingTokenPurchaseIntent?

    func begin(context: PurchaseAnalyticsContext) async -> Bool {
        guard pending == nil else { return false }
        pending = PendingTokenPurchaseIntent(
            analyticsContext: context, startedAt: Date(), evidence: nil, belongsToCurrentSubject: true
        )
        return true
    }

    func state() async -> PendingTokenPurchaseState { pending.map(PendingTokenPurchaseState.pending) ?? .none }

    func save(evidence _: TokenTransactionEvidence, attemptID _: MonetizationAttemptID) async -> Bool { false }

    func clear(attemptID _: MonetizationAttemptID) async -> Bool {
        pending = nil
        return true
    }
}

struct ContractRecovery: RecoverTokenAccountUseCaseProtocol {
    func callAsFunction() async -> TokenAccountRecoveryOutcome {
        .restored(TokenBalanceSnapshot(balance: 250, updatedAt: Date()))
    }
}

actor ContractTracker: TrackPaywallEventUseCaseProtocol {
    private(set) var shown: [PaywallPresentationID] = []
    private(set) var closed: [PaywallPresentationID] = []

    func callAsFunction(_ event: MonetizationAnalyticsEvent) async {
        switch event {
        case let .paywallShown(context): shown.append(context.presentationID)
        case let .paywallClosed(context, _): closed.append(context.presentationID)
        default: break
        }
    }
}

actor ContractLifecycle: PaywallPresentationLifecycleProtocol {
    private(set) var appeared: [PaywallPresentationID] = []
    private(set) var ended: [PaywallPresentationID] = []
    func presentationDidAppear(_ context: PaywallAnalyticsContext) async { appeared.append(context.presentationID) }
    func presentationDidEnd(_ context: PaywallAnalyticsContext) async { ended.append(context.presentationID) }
}

@MainActor
func tokenModel(
    loader: ContractLoader,
    initialPayload: PaywallPayload? = nil,
    copy: BroadTokenPaywallCopy = .english,
    repository: ContractPurchaseRepository = ContractPurchaseRepository(),
    tracker: ContractTracker = ContractTracker()
) -> BroadTokenPaywallViewModel {
    BroadTokenPaywallViewModel(
        configuration: BroadTokenPaywallConfiguration(copy: copy),
        dependencies: BroadTokenPaywallViewModelDependencies(
            loadPaywall: loader,
            selectProduct: ContractSelector(),
            purchaseManager: TokenPurchaseManager(
                purchaseRepository: repository,
                evidenceProvider: ContractEvidence(),
                fulfillmentRepository: ContractFulfillment(),
                pendingStore: ContractPendingStore(),
                operationGate: MonetizationOperationGate()
            ),
            recoverTokenAccount: ContractRecovery(),
            onBalanceConfirmed: { _ in },
            trackEvent: tracker
        ),
        initialPayload: initialPayload
    )
}
