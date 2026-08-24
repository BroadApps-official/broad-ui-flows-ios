import BroadCore
import BroadUIFlows
import SwiftUI

struct LoadableStatesGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BroadLoaderView(
                    content: BroadStateContent(
                        title: "Loading",
                        message: "Fixture content is being prepared."
                    )
                )

                BroadEmptyView(
                    content: BroadStateContent(
                        title: "Nothing here yet",
                        message: "An app may supply its own next action.",
                        systemImageName: "tray"
                    ),
                    action: BroadActionConfiguration(title: "Fixture action") {}
                )

                BroadErrorView(
                    content: BroadStateContent(
                        title: "Unavailable",
                        message: "Typed failure copy without a raw error.",
                        systemImageName: "exclamationmark.triangle"
                    ),
                    retry: BroadActionConfiguration(title: "Retry fixture") {}
                )

                BroadStaleBanner(
                    content: BroadStateContent(
                        title: "Showing saved content",
                        message: "Refresh remains an explicit user action.",
                        systemImageName: "clock.arrow.circlepath"
                    ),
                    retry: BroadActionConfiguration(title: "Refresh fixture") {}
                )
            }
            .padding()
        }
        .navigationTitle("Loadable states")
    }
}

@MainActor
struct FixtureOnboardingScreen: View {
    @StateObject private var viewModel = OnboardingViewModel(
        configuration: OnboardingConfiguration(
            pages: [
                OnboardingPageConfiguration(
                    id: "choose-modules",
                    title: "Choose only what the app needs",
                    subtitle: "Core, Monetization, UIFlows and Extensions are independent packages.",
                    media: OnboardingMediaDescriptor(identifier: "square.stack.3d.up")
                ),
                OnboardingPageConfiguration(
                    id: "review-separately",
                    title: "Review and release separately",
                    subtitle: "This screen is rendered by the public BroadUIFlows API.",
                    media: OnboardingMediaDescriptor(identifier: "checkmark.seal")
                )
            ],
            continueTitle: "Continue",
            completionTitle: "Finish fixture",
            progressAccessibilityLabel: "Fixture onboarding progress",
            footerLinks: [
                OnboardingFooterLinkConfiguration(
                    destination: .privacyPolicy,
                    title: "Privacy fixture"
                )
            ],
            trackingAuthorizationPolicy: .disabled
        ),
        requestTrackingAuthorizationUseCase: FixtureTrackingAuthorization()
    )

    var body: some View {
        BroadOnboardingView(
            viewModel: viewModel
        ) { media in
            Image(systemName: media.identifier)
                .font(.largeTitle)
                .foregroundStyle(.pink)
                .frame(height: 150)
        } onFooterAction: { _ in } onCompleted: {}
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct FixtureTrackingAuthorization: TrackingAuthorizationUseCaseProtocol {
    @MainActor
    func callAsFunction() async -> TrackingAuthorizationStatus {
        .denied
    }
}
