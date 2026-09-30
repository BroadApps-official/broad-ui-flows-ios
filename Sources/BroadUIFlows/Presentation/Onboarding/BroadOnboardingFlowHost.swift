import SwiftUI

/// Actions shared by the standard onboarding renderer and app-owned renderers.
/// The host keeps completion and ATT lifecycle rules outside visual code.
@MainActor
public struct OnboardingFlowActions {
    private let advanceAction: @MainActor () -> Void

    init(advance: @escaping @MainActor () -> Void) {
        advanceAction = advance
    }

    /// Advances to the next configured page or completes the onboarding when
    /// the current page is the last one.
    public func advance() {
        advanceAction()
    }
}

/// A logic-only onboarding host for applications with a fully custom design.
///
/// It owns lifecycle, window visibility, invalid configuration handling and
/// the safe ATT boundary. The `content` closure owns every visual decision.
@MainActor
public struct BroadOnboardingFlowHost<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var isObservingVisibility = false
    @State private var isTransitionSettled = false
    @StateObject private var viewModel: OnboardingViewModel

    private let onCompleted: @MainActor () -> Void
    private let content: @MainActor (
        OnboardingViewModel,
        OnboardingFlowActions
    ) -> Content

    public init(
        viewModel: OnboardingViewModel,
        onCompleted: @escaping @MainActor () -> Void,
        @ViewBuilder content: @escaping @MainActor (
            OnboardingViewModel,
            OnboardingFlowActions
        ) -> Content
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCompleted = onCompleted
        self.content = content
    }

    public var body: some View {
        Group {
            if viewModel.configuration.isValid {
                content(
                    viewModel,
                    OnboardingFlowActions(advance: advance)
                )
            } else {
                Color.clear
                    .accessibilityHidden(true)
            }
        }
        .background(windowVisibilityObserver)
        .onAppear {
            isObservingVisibility = true
            viewModel.onboardingDidAppear()
            viewModel.applicationActiveDidChange(scenePhase == .active)

            if viewModel.completeInvalidConfigurationIfNeeded() {
                onCompleted()
            }
        }
        .onDisappear {
            isObservingVisibility = false
            isTransitionSettled = false
            viewModel.onboardingDidDisappear()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            viewModel.applicationActiveDidChange(phase == .active)
        }
        .onChange(of: viewModel.currentIndex) { previousIndex, currentIndex in
            let firstIndex = viewModel.configuration.pages.startIndex
            if previousIndex == firstIndex, currentIndex != firstIndex {
                viewModel.firstSlideDidDisappear()
            }
            if currentIndex == firstIndex {
                markFirstPageVisibleIfNeeded()
            }
        }
    }

    private var windowVisibilityObserver: some View {
        OnboardingWindowVisibilityView(isEnabled: isObservingVisibility, onTransitionSettledChange: { isSettled in
            isTransitionSettled = isSettled
            if isSettled {
                markFirstPageVisibleIfNeeded()
            } else {
                viewModel.firstSlideDidDisappear()
            }
        }) { isVisible, validateCurrentVisibility in
            viewModel.windowVisibilityDidChange(
                isVisible,
                validateCurrentVisibility: validateCurrentVisibility
            )
        }
        .accessibilityHidden(true)
    }

    private func markFirstPageVisibleIfNeeded() {
        guard isTransitionSettled, viewModel.currentIndex == viewModel.configuration.pages.startIndex else {
            return
        }
        viewModel.firstSlideDidAppear()
    }

    private func advance() {
        if viewModel.advance() {
            onCompleted()
        }
    }
}
