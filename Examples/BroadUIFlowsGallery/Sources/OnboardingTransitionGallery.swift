import BroadCore
import BroadUIFlows
import SwiftUI

/// Exercises the actual onboarding host with a counting use case, never system ATT.
@MainActor
struct OnboardingTransitionGallery: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var recorder = GalleryTrackingRecorder()
    @State private var route: AppFlowRoute = .launch
    @State private var viewModel: OnboardingViewModel?
    @State private var usesStandardRenderer = false
    @State private var slowTransition = false
    @State private var disablesTracking = false

    var body: some View {
        VStack(spacing: 16) {
            Toggle("Standard onboarding view", isOn: $usesStandardRenderer)
            Toggle("Slow transition (1.2 seconds)", isOn: $slowTransition)
            Toggle("ATT disabled", isOn: $disablesTracking)
            HStack {
                Button("Start") { start() }
                    .disabled(route != .launch)
                Button("Reset / leave") {
                    route = .launch
                    viewModel = nil
                }
            }
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
            LabeledContent("ATT fixture calls", value: String(recorder.calls))
            if let elapsed = recorder.elapsed {
                Text(String(format: "ATT fixture at %.2f seconds after Start", elapsed))
            }
            Text("Delay: 0.4 seconds after the transition settles. No system permission is requested.")
                .font(.footnote)

            if slowTransition {
                ZStack {
                    flow(transition: .none)
                        .id(route)
                        .transition(reduceMotion ? .opacity : .move(edge: .trailing))
                }
                .animation(.easeInOut(duration: 1.2), value: route)
            } else {
                flow(transition: .slide)
            }
        }
        .padding()
        .navigationTitle("ATT transition fixture")
    }

    private func flow(transition: BroadAppFlowTransition) -> some View {
        BroadAppFlowView(route: route, transition: transition) {
            Text("Launch fixture — ATT calls must stay at zero")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.gray.opacity(0.2))
        } onboarding: {
            if let viewModel {
                if usesStandardRenderer {
                    BroadOnboardingView(viewModel: viewModel) { media in
                        Image(systemName: media.identifier)
                    } onFooterAction: { _ in } onCompleted: { route = .main }
                } else {
                    BroadOnboardingFlowHost(viewModel: viewModel, onCompleted: finishOnboarding) { model, actions in
                        VStack {
                            Text(model.currentPage?.title ?? "")
                            Button("Continue / leave first slide") { actions.advance() }
                                .frame(minHeight: 44)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.blue.opacity(0.2))
                    }
                }
            }
        } initialPaywall: {
            Text("Paywall fixture")
        } main: {
            Text("Main fixture")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func start() {
        recorder.reset()
        viewModel = OnboardingViewModel(
            configuration: OnboardingConfiguration(
                pages: [
                    OnboardingPageConfiguration(id: "first", title: "First slide", media: .init(identifier: "1.circle")),
                    OnboardingPageConfiguration(id: "second", title: "Second slide", media: .init(identifier: "2.circle"))
                ],
                continueTitle: "Continue",
                completionTitle: "Finish",
                progressAccessibilityLabel: "Fixture progress",
                trackingAuthorizationPolicy: disablesTracking ? .disabled : .afterFirstSlide()
            ),
            requestTrackingAuthorizationUseCase: recorder
        )
        route = .onboarding
    }

    private func finishOnboarding() {
        route = .main
    }
}

@MainActor
private final class GalleryTrackingRecorder: ObservableObject, TrackingAuthorizationUseCaseProtocol {
    @Published private(set) var calls = 0
    @Published private(set) var elapsed: TimeInterval?
    private var startedAt = Date()

    func reset() {
        calls = 0
        elapsed = nil
        startedAt = Date()
    }

    func callAsFunction() async -> TrackingAuthorizationStatus {
        calls += 1
        elapsed = Date().timeIntervalSince(startedAt)
        return .denied
    }
}
