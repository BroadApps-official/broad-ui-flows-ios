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
}

struct BroadPaywallSafariDestination: Identifiable {
    let id = UUID()
    let url: URL
}
