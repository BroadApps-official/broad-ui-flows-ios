import BroadCore
import BroadMonetization
import Combine
import Foundation

public struct PaywallViewModelDependencies: Sendable {
    let loadPaywall: any LoadPaywallUseCaseProtocol
    let selectProduct: any SelectProductUseCaseProtocol
    let checkoutProduct: any CheckoutSelectedProductUseCaseProtocol
    let restorePurchases: any RestorePurchasesUseCaseProtocol
    let resolveCheckoutMethods: any ResolveCheckoutMethodsUseCaseProtocol
    let trackEvent: any TrackPaywallEventUseCaseProtocol
    let presentationLifecycle: any PaywallPresentationLifecycleProtocol
    let operationGate: MonetizationOperationGate

    public init(
        loadPaywall: any LoadPaywallUseCaseProtocol,
        selectProduct: any SelectProductUseCaseProtocol,
        checkoutProduct: any CheckoutSelectedProductUseCaseProtocol,
        restorePurchases: any RestorePurchasesUseCaseProtocol,
        resolveCheckoutMethods: any ResolveCheckoutMethodsUseCaseProtocol,
        trackEvent: any TrackPaywallEventUseCaseProtocol,
        presentationLifecycle: any PaywallPresentationLifecycleProtocol,
        operationGate: MonetizationOperationGate
    ) {
        self.loadPaywall = loadPaywall
        self.selectProduct = selectProduct
        self.checkoutProduct = checkoutProduct
        self.restorePurchases = restorePurchases
        self.resolveCheckoutMethods = resolveCheckoutMethods
        self.trackEvent = trackEvent
        self.presentationLifecycle = presentationLifecycle
        self.operationGate = operationGate
    }

    /// Source-compatible Apple-only convenience. Hosts with external providers should inject
    /// `CheckoutSelectedProductUseCaseProtocol` from their provider composition.
    public init(
        loadPaywall: any LoadPaywallUseCaseProtocol,
        selectProduct: any SelectProductUseCaseProtocol,
        purchaseProduct: any PurchaseSelectedProductUseCaseProtocol,
        restorePurchases: any RestorePurchasesUseCaseProtocol,
        resolveCheckoutMethods: any ResolveCheckoutMethodsUseCaseProtocol,
        trackEvent: any TrackPaywallEventUseCaseProtocol,
        presentationLifecycle: any PaywallPresentationLifecycleProtocol,
        operationGate: MonetizationOperationGate
    ) {
        self.init(
            loadPaywall: loadPaywall,
            selectProduct: selectProduct,
            checkoutProduct: CheckoutSelectedProductUseCase(
                applePurchase: purchaseProduct
            ),
            restorePurchases: restorePurchases,
            resolveCheckoutMethods: resolveCheckoutMethods,
            trackEvent: trackEvent,
            presentationLifecycle: presentationLifecycle,
            operationGate: operationGate
        )
    }
}

@MainActor
public final class PaywallViewModel: ObservableObject {
    @Published public internal(set) var state: BroadPaywallViewState = .idle
    @Published public internal(set) var selectedProductPresentationID: ProductPresentationID?
    @Published public internal(set) var inlineFeedback: BroadPaywallInlineFeedback?
    /// Typed form of ``inlineFeedback`` for custom screens.
    @Published public internal(set) var notice: BroadPaywallNotice?
    @Published public internal(set) var checkoutMethods: [CheckoutMethod] = []
    @Published public internal(set) var checkoutResolution: CheckoutMethodsResolution?
    @Published public internal(set) var completionEvent: BroadPaywallCompletionEvent?
    @Published public internal(set) var isCloseAvailable: Bool
    @Published public internal(set) var isResolvingCheckoutMethods = false
    @Published public internal(set) var isPurchaseInFlight = false
    @Published public internal(set) var isRestoreInFlight = false
    /// Unknown gate state is blocked until the durable stores have been read.
    @Published public internal(set) var isFinancialOperationPending = true

    public let configuration: BroadPaywallConfiguration

    let dependencies: PaywallViewModelDependencies

    var selectedSelection: ProductSelection?
    var loadTask: Task<Void, Never>?
    var checkoutTask: Task<Void, Never>?
    var purchaseTask: Task<Void, Never>?
    var restoreTask: Task<Void, Never>?
    var closeAvailabilityTask: Task<Void, Never>?
    var eventTask: Task<Void, Never>?
    var financialStatusTask: Task<Void, Never>?
    var financialStatusObservationTask: Task<Void, Never>?
    var loadGeneration: UInt64 = 0
    var lastShownPresentationID: PaywallPresentationID?
    var lastClosedPresentationID: PaywallPresentationID?
    var preparedInitialPayload: PaywallPayload?

    public init(
        configuration: BroadPaywallConfiguration,
        dependencies: PaywallViewModelDependencies,
        initialPayload: PaywallPayload? = nil
    ) {
        precondition(
            initialPayload?.origin.requestedPlacementID == configuration.request.placementID
                || initialPayload == nil,
            "Initial paywall payload must belong to the configured placement"
        )
        self.configuration = configuration
        self.dependencies = dependencies
        preparedInitialPayload = initialPayload
        isCloseAvailable = configuration.access.defaultPolicy == .soft
    }

    deinit {
        loadTask?.cancel()
        checkoutTask?.cancel()
        closeAvailabilityTask?.cancel()
        financialStatusTask?.cancel()
        financialStatusObservationTask?.cancel()
        // Do not cancel `eventTask`: its final close owns provider cleanup.
    }

    public var selectedProduct: MonetizationProduct? {
        selectedSelection?.product
    }

    public var isBusy: Bool {
        isResolvingCheckoutMethods || isPurchaseInFlight || isRestoreInFlight
    }

    public var canPurchase: Bool {
        guard case .content = state else {
            return false
        }

        return configuration.specialOfferAuthorization?.countdown.isExpired != true
            && selectedSelection?.product.isEligibleForGenericPurchase == true
            && !isBusy
            && !isFinancialOperationPending
    }

    public var canSelectProducts: Bool {
        configuration.specialOfferAuthorization?.countdown.isExpired != true
            && !isBusy && !isFinancialOperationPending
    }

    /// Text for a notice from the configured copy; failures use the error message.
    public func message(for notice: BroadPaywallNotice) -> String {
        switch notice {
        case .purchaseCompleted:
            configuration.copy.states.purchase.completedMessage
        case .purchaseUnverified:
            configuration.copy.states.purchase.completedButUnverifiedMessage
        case .purchasePending:
            configuration.copy.states.purchase.pendingMessage
        case .nothingToRestore:
            configuration.copy.states.nothingToRestoreMessage
        case let .checkoutUnavailable(error), let .failed(error):
            error.userMessage
        }
    }

    func setNotice(_ newNotice: BroadPaywallNotice?) {
        notice = newNotice
        inlineFeedback = newNotice.map { notice in
            switch notice {
            case let .checkoutUnavailable(error), let .failed(error):
                .failure(error)
            case .purchaseCompleted, .purchaseUnverified, .purchasePending, .nothingToRestore:
                .notice(message(for: notice))
            }
        }
    }

    /// Hides the current notice and its legacy inline feedback.
    public func dismissNotice() {
        setNotice(nil)
    }

    /// Products in display order for a custom paywall screen.
    public var displayedProducts: [MonetizationProduct] {
        state.payload.map(displayedProducts(in:)) ?? []
    }

    /// Products of the payload in display order; the payload itself is not changed.
    public func displayedProducts(in payload: PaywallPayload) -> [MonetizationProduct] {
        configuration.productOrder.arrange(payload.products)
    }

    public func viewDidAppear() {
        observeFinancialOperationStatus()
        refreshFinancialOperationStatus()
        if case let .content(payload) = state {
            configureCloseAvailability(for: payload)
        } else {
            loadIfNeeded()
        }
    }

    public func refreshFinancialOperationStatus() {
        financialStatusTask?.cancel()
        checkoutTask?.cancel()
        checkoutTask = nil
        checkoutMethods = []
        checkoutResolution = nil
        isResolvingCheckoutMethods = false
        isFinancialOperationPending = true
        let gate = dependencies.operationGate
        financialStatusTask = Task { @MainActor [weak self, gate] in
            let isBlocked = await gate.isFinancialOperationBlocked()
            guard let self, !Task.isCancelled else {
                return
            }
            financialStatusTask = nil
            isFinancialOperationPending = isBlocked
        }
    }

    func observeFinancialOperationStatus() {
        guard financialStatusObservationTask == nil else {
            return
        }
        let gate = dependencies.operationGate
        financialStatusObservationTask = Task { @MainActor [weak self, gate] in
            let changes = await gate.financialOperationStatusChanges()
            for await _ in changes {
                guard let self, !Task.isCancelled else {
                    return
                }
                // One latest-wins path owns every status write. A newer gate
                // event cancels an older re-entrant read before it can apply.
                refreshFinancialOperationStatus()
            }
        }
    }

    public func viewDidDisappear() {
        let wasLoading = loadTask != nil
        loadGeneration &+= 1

        // Disappearance is the terminal boundary for this presentation when no
        // explicit close/purchase event has already supplied a stronger reason.
        // A later appearance loads a fresh presentation instead of reviving a
        // provider handle that the monetization lifecycle has released.
        trackClose(reason: .navigation)

        loadTask?.cancel()
        checkoutTask?.cancel()
        closeAvailabilityTask?.cancel()
        financialStatusTask?.cancel()
        financialStatusObservationTask?.cancel()

        loadTask = nil
        checkoutTask = nil
        closeAvailabilityTask = nil
        financialStatusTask = nil
        financialStatusObservationTask = nil
        checkoutMethods = []
        checkoutResolution = nil
        isResolvingCheckoutMethods = false

        if wasLoading {
            state = .idle
        } else if state.payload != nil {
            state = .idle
            selectedSelection = nil
            selectedProductPresentationID = nil
            setNotice(nil)
        }
    }
}
