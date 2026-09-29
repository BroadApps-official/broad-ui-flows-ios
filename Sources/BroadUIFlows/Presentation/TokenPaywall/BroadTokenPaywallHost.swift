import BroadMonetization
import SwiftUI

/// Runs a token paywall for a screen drawn by the app.
///
/// The host owns loading, default selection, the purchase and its server
/// credit, the safe check of a saved purchase, the balance and closing while
/// busy. The content closure receives a ``BroadTokenPaywallScreen`` and only
/// lays it out:
///
/// ```swift
/// BroadTokenPaywallHost(viewModel: viewModel, onClose: close) { screen in
///     MyTokenStore(screen: screen)
/// }
/// ```
@MainActor
public struct BroadTokenPaywallHost<Content: View>: View {
    @StateObject private var viewModel: BroadTokenPaywallViewModel

    private let productFormatter: BroadPaywallProductFormatter
    private let tokenAmount: (@MainActor (MonetizationProduct) -> Int?)?
    private let onClose: @MainActor () -> Void
    private let content: @MainActor (BroadTokenPaywallScreen) -> Content

    /// - Parameters:
    ///   - viewModel: The token paywall of this presentation.
    ///   - productFormatter: Formats package prices and the balance number.
    ///   - tokenAmount: Tokens a package adds, for example from its product ID
    ///     or the backend catalog; `nil` leaves ``BroadTokenPackage/tokens`` empty.
    ///   - onClose: Called when the screen closes; closing waits while busy.
    ///   - content: The app's layout of ``BroadTokenPaywallScreen``.
    public init(
        viewModel: BroadTokenPaywallViewModel,
        productFormatter: BroadPaywallProductFormatter = BroadPaywallProductFormatter(),
        tokenAmount: (@MainActor (MonetizationProduct) -> Int?)? = nil,
        onClose: @escaping @MainActor () -> Void,
        @ViewBuilder content: @escaping @MainActor (BroadTokenPaywallScreen) -> Content
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.productFormatter = productFormatter
        self.tokenAmount = tokenAmount
        self.onClose = onClose
        self.content = content
    }

    public var body: some View {
        content(screen)
            .modifier(BroadTokenPaywallLifecycle(viewModel: viewModel))
    }

    private var screen: BroadTokenPaywallScreen {
        viewModel.screen(
            formatter: productFormatter,
            tokenAmount: tokenAmount,
            close: {
                guard viewModel.isCloseAvailable, !viewModel.isBusy else {
                    return
                }
                onClose()
            }
        )
    }
}

/// Token paywall wiring shared by ``BroadTokenPaywallView`` and
/// ``BroadTokenPaywallHost``: appearance, pending recovery and analytics.
@MainActor
struct BroadTokenPaywallLifecycle: ViewModifier {
    @ObservedObject var viewModel: BroadTokenPaywallViewModel

    func body(content: Content) -> some View {
        content
            .onAppear {
                viewModel.viewDidAppear()
            }
            .onDisappear {
                viewModel.viewDidDisappear()
            }
    }
}
