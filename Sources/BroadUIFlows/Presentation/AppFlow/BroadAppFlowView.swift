import SwiftUI

/// Animation used when ``BroadAppFlowView`` changes routes.
public enum BroadAppFlowTransition: Equatable, Sendable {
    /// Keep the existing immediate route replacement.
    case none
    /// Insert from the trailing edge and remove toward the leading edge.
    /// Reduce Motion replaces the movement with a fade.
    case slide
}

/// Displays the current application route with an optional route transition.
@MainActor
public struct BroadAppFlowView<
    LaunchContent: View,
    OnboardingContent: View,
    PaywallContent: View,
    MainContent: View
>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let route: AppFlowRoute
    private let transition: BroadAppFlowTransition
    private let launch: @MainActor () -> LaunchContent
    private let onboarding: @MainActor () -> OnboardingContent
    private let initialPaywall: @MainActor () -> PaywallContent
    private let main: @MainActor () -> MainContent

    /// Creates an app flow with immediate route replacement.
    public init(
        route: AppFlowRoute,
        @ViewBuilder launch: @escaping @MainActor () -> LaunchContent,
        @ViewBuilder onboarding: @escaping @MainActor () -> OnboardingContent,
        @ViewBuilder initialPaywall: @escaping @MainActor () -> PaywallContent,
        @ViewBuilder main: @escaping @MainActor () -> MainContent
    ) {
        self.init(
            route: route, transition: .none,
            launch: launch, onboarding: onboarding,
            initialPaywall: initialPaywall, main: main
        )
    }

    /// Creates an app flow with an optional animated route change.
    public init(
        route: AppFlowRoute,
        transition: BroadAppFlowTransition,
        @ViewBuilder launch: @escaping @MainActor () -> LaunchContent,
        @ViewBuilder onboarding: @escaping @MainActor () -> OnboardingContent,
        @ViewBuilder initialPaywall: @escaping @MainActor () -> PaywallContent,
        @ViewBuilder main: @escaping @MainActor () -> MainContent
    ) {
        self.route = route
        self.transition = transition
        self.launch = launch
        self.onboarding = onboarding
        self.initialPaywall = initialPaywall
        self.main = main
    }

    public var body: some View {
        if transition == .none {
            routeContent
        } else {
            ZStack {
                routeContent
                    .id(route)
                    .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
            .animation(.easeInOut(duration: 0.25), value: route)
        }
    }

    @ViewBuilder
    private var routeContent: some View {
        switch route {
        case .launch:
            launch()
        case .onboarding:
            onboarding()
        case .initialPaywall:
            initialPaywall()
        case .main:
            main()
        @unknown default:
            launch()
        }
    }
}
