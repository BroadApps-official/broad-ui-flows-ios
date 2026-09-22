import BroadMonetization
import SwiftUI

@MainActor
public struct BroadPaywallView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject var viewModel: PaywallViewModel
    @State var safariDestination: BroadPaywallSafariDestination?

    let theme: BroadPaywallTheme
    let productFormatter: BroadPaywallProductFormatter
    let checkoutContent: (@MainActor (PaywallViewModel) -> AnyView)?
    let onClose: @MainActor () -> Void
    let onCompleted: @MainActor (BroadPaywallCompletion) -> Void

    public init(
        viewModel: PaywallViewModel,
        theme: BroadPaywallTheme,
        productFormatter: BroadPaywallProductFormatter,
        checkoutContent: (@MainActor (PaywallViewModel) -> AnyView)? = nil,
        onClose: @escaping @MainActor () -> Void,
        onCompleted: @escaping @MainActor (BroadPaywallCompletion) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.theme = theme
        self.productFormatter = productFormatter
        self.checkoutContent = checkoutContent
        self.onClose = onClose
        self.onCompleted = onCompleted
    }

    public init(
        viewModel: PaywallViewModel,
        checkoutContent: (@MainActor (PaywallViewModel) -> AnyView)? = nil,
        onClose: @escaping @MainActor () -> Void,
        onCompleted: @escaping @MainActor (BroadPaywallCompletion) -> Void
    ) {
        self.init(
            viewModel: viewModel,
            theme: .standard,
            productFormatter: BroadPaywallProductFormatter(),
            checkoutContent: checkoutContent,
            onClose: onClose,
            onCompleted: onCompleted
        )
    }

    public var body: some View {
        ZStack {
            theme.palette.background
                .ignoresSafeArea()

            HStack(spacing: 0) {
                Spacer(minLength: 0)

                paywallLayout
                    .frame(
                        maxWidth: theme.metrics.sizing.maximumContentWidth,
                        maxHeight: .infinity
                    )

                Spacer(minLength: 0)
            }
        }
        .allowsHitTesting(!viewModel.isPurchaseInFlight)
        .onAppear {
            viewModel.viewDidAppear()
        }
        .onDisappear {
            viewModel.viewDidDisappear()
        }
        .onChange(of: viewModel.completionEvent) { _, event in
            handleCompletionEvent(event)
        }
        .task(
            id: viewModel.configuration.specialOfferAuthorization?
                .paywallPresentationID
        ) {
            await closeSpecialOfferAtWindowEnd()
        }
        .sheet(item: $safariDestination) { destination in
            BroadInAppSafariView(url: destination.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: checkoutSheetBinding) {
            if let checkoutContent {
                checkoutContent(viewModel)
            } else {
                VStack(spacing: 20) {
                    Text(viewModel.configuration.copy.states.checkoutUnavailableMessage)
                    Button(viewModel.configuration.copy.actions.cancelTitle) {
                        viewModel.cancelCheckoutMethodSelection()
                    }
                    .frame(minHeight: 44)
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var paywallLayout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                VStack(spacing: 0) {
                    closeHeader
                    stateBodyContent
                    stickyFooter
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            VStack(spacing: 0) {
                closeHeader
                stateContent
                stickyFooter
            }
        }
    }

    var checkoutSheetBinding: Binding<Bool> {
        Binding(
            get: { !viewModel.checkoutMethods.isEmpty },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelCheckoutMethodSelection()
                }
            }
        )
    }

    func handleCompletionEvent(_ event: BroadPaywallCompletionEvent?) {
        guard let event else {
            return
        }

        viewModel.consumeCompletionEvent(id: event.id)
        onCompleted(event.completion)
    }

    func closeSpecialOfferAtWindowEnd() async {
        guard let countdown = viewModel.configuration
            .specialOfferAuthorization?.countdown
        else {
            return
        }
        do {
            try await countdown.sleepUntilExpiration()
        } catch {
            return
        }

        while !Task.isCancelled {
            if viewModel.requestSpecialOfferExpirationClose() {
                onClose()
                return
            }
            if viewModel.completionEvent != nil {
                return
            }
            do {
                try await ContinuousClock().sleep(for: .milliseconds(250))
            } catch {
                return
            }
        }
    }
}

struct BroadPaywallSafariDestination: Identifiable {
    let id = UUID()
    let url: URL
}
