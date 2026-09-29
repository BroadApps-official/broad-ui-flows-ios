import BroadMonetization
import BroadUIFlows
import SwiftUI

@MainActor
struct FixturePreloadedTokenPaywallGallery: View {
    @State private var preloader: BroadPaywallPreloader
    @State private var viewModel: BroadTokenPaywallViewModel?
    @State private var isPresented = false

    private let payload: PaywallPayload

    init() {
        let payload = FixtureCatalog.tokenPayload()
        self.payload = payload
        _preloader = State(initialValue: BroadPaywallPreloader(
            loadPaywall: FixturePaywallLoader(payload: payload),
            presentationLifecycle: NoOpPaywallPresentationLifecycle()
        ))
    }

    var body: some View {
        Button("Open preloaded token paywall") {
            viewModel = FixtureTokenPaywallScreen.makeViewModel(
                showsAnalytics: true,
                initialPayload: preloader.take(.tokens),
                payload: payload
            )
            isPresented = true
        }
        .frame(minHeight: 44)
        .task {
            preloader.preload(.tokens)
        }
        .fullScreenCover(
            isPresented: $isPresented,
            onDismiss: {
                viewModel = nil
                preloader.preload(.tokens)
            },
            content: {
                if let viewModel {
                    BroadTokenPaywallView(
                        viewModel: viewModel,
                        theme: .standard,
                        onClose: { isPresented = false }
                    )
                }
            }
        )
        .navigationTitle("Preloaded token paywall")
    }
}
