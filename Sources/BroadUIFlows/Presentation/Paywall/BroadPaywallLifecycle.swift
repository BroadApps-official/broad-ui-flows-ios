import SwiftUI

/// Paywall wiring shared by the ready ``BroadPaywallView`` and ``BroadPaywallHost``:
/// appearance, completion events, the Special Offer window, legal links and the
/// checkout method sheet. A screen that uses it does not repeat this logic.
@MainActor
struct BroadPaywallLifecycle: ViewModifier {
    @ObservedObject var viewModel: PaywallViewModel
    @Binding var safariDestination: BroadPaywallSafariDestination?
    let checkoutContent: (@MainActor (PaywallViewModel) -> AnyView)?
    let onClose: @MainActor () -> Void
    let onCompleted: @MainActor (BroadPaywallCompletion) -> Void

    func body(content: Content) -> some View {
        content
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

    private var checkoutSheetBinding: Binding<Bool> {
        Binding(
            get: { !viewModel.checkoutMethods.isEmpty },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelCheckoutMethodSelection()
                }
            }
        )
    }

    private func handleCompletionEvent(_ event: BroadPaywallCompletionEvent?) {
        guard let event else {
            return
        }

        viewModel.consumeCompletionEvent(id: event.id)
        onCompleted(event.completion)
    }

    private func closeSpecialOfferAtWindowEnd() async {
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
