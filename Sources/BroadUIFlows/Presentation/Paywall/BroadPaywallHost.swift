import SwiftUI

/// Runs a subscription paywall or Special Offer for a screen drawn by the app.
///
/// The host owns loading, plan order and default selection, the close delay,
/// purchase and restore, completion events, the Special Offer window, legal
/// links and the checkout sheet. The content closure receives a
/// ``BroadPaywallScreen`` and only lays it out:
///
/// ```swift
/// BroadPaywallHost(viewModel: viewModel, onClose: close, onCompleted: finish) { screen in
///     MyPaywall(screen: screen)
/// }
/// ```
@MainActor
public struct BroadPaywallHost<Content: View>: View {
    @StateObject private var viewModel: PaywallViewModel
    @State private var safariDestination: BroadPaywallSafariDestination?

    private let productFormatter: BroadPaywallProductFormatter
    private let checkoutContent: (@MainActor (PaywallViewModel) -> AnyView)?
    private let onClose: @MainActor () -> Void
    private let onCompleted: @MainActor (BroadPaywallCompletion) -> Void
    private let content: @MainActor (BroadPaywallScreen) -> Content

    public init(
        viewModel: PaywallViewModel,
        productFormatter: BroadPaywallProductFormatter = BroadPaywallProductFormatter(),
        checkoutContent: (@MainActor (PaywallViewModel) -> AnyView)? = nil,
        onClose: @escaping @MainActor () -> Void,
        onCompleted: @escaping @MainActor (BroadPaywallCompletion) -> Void,
        @ViewBuilder content: @escaping @MainActor (BroadPaywallScreen) -> Content
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.productFormatter = productFormatter
        self.checkoutContent = checkoutContent
        self.onClose = onClose
        self.onCompleted = onCompleted
        self.content = content
    }

    public var body: some View {
        content(screen)
            .modifier(
                BroadPaywallLifecycle(
                    viewModel: viewModel,
                    safariDestination: $safariDestination,
                    checkoutContent: checkoutContent,
                    onClose: onClose,
                    onCompleted: onCompleted
                )
            )
    }

    private var screen: BroadPaywallScreen {
        viewModel.screen(
            formatter: productFormatter,
            close: {
                if viewModel.requestClose() {
                    onClose()
                }
            },
            open: { link in
                safariDestination = BroadPaywallSafariDestination(url: link.url)
            }
        )
    }
}
