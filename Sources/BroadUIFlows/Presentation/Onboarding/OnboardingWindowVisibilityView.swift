import SwiftUI
import UIKit

@MainActor
struct OnboardingWindowVisibilityView: UIViewRepresentable {
    typealias VisibilityValidator = @MainActor () -> Bool

    let isEnabled: Bool
    let onTransitionSettledChange: @MainActor (Bool) -> Void
    let onVisibilityChange: @MainActor (
        _ isVisible: Bool,
        _ validateCurrentVisibility: VisibilityValidator?
    ) -> Void

    func makeUIView(context: Context) -> OnboardingWindowVisibilityProbeView {
        OnboardingWindowVisibilityProbeView(
            isEnabled: isEnabled,
            onVisibilityChange: onVisibilityChange,
            onTransitionSettledChange: onTransitionSettledChange
        )
    }

    func updateUIView(
        _ uiView: OnboardingWindowVisibilityProbeView,
        context: Context
    ) {
        uiView.isEnabled = isEnabled
        uiView.onTransitionSettledChange = onTransitionSettledChange
        uiView.onVisibilityChange = onVisibilityChange
        uiView.reportVisibility(force: true)
    }

    static func dismantleUIView(
        _ uiView: OnboardingWindowVisibilityProbeView,
        coordinator: Void
    ) {
        uiView.stopObservingTransition()
        uiView.onVisibilityChange(false, nil)
    }
}

@MainActor
final class OnboardingWindowVisibilityProbeView: UIView {
    var onVisibilityChange: @MainActor (
        _ isVisible: Bool,
        _ validateCurrentVisibility: OnboardingWindowVisibilityView.VisibilityValidator?
    ) -> Void

    var isEnabled: Bool
    var onTransitionSettledChange: @MainActor (Bool) -> Void

    private var lastReportedVisibility: Bool?
    private var transitionTask: Task<Void, Never>?
    private var isTransitionSettled = false

    init(
        isEnabled: Bool,
        onVisibilityChange: @escaping @MainActor (
            _ isVisible: Bool,
            _ validateCurrentVisibility: OnboardingWindowVisibilityView.VisibilityValidator?
        ) -> Void,
        onTransitionSettledChange: @escaping @MainActor (Bool) -> Void
    ) {
        self.isEnabled = isEnabled
        self.onVisibilityChange = onVisibilityChange
        self.onTransitionSettledChange = onTransitionSettledChange
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        startObservingVisibilityEnvironment()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        transitionTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportVisibility()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        reportVisibility()
    }

    func reportVisibility(force: Bool = false) {
        let isVisible = isCurrentlyVisible
        if isVisible {
            startObservingTransitionIfNeeded()
        } else {
            stopObservingTransition()
        }

        guard force || lastReportedVisibility != isVisible else {
            return
        }

        lastReportedVisibility = isVisible
        onVisibilityChange(
            isVisible,
            { [weak self] in
                self?.isReadyForTracking == true
            }
        )
    }

    func stopObservingTransition() {
        transitionTask?.cancel()
        transitionTask = nil
        if isTransitionSettled {
            isTransitionSettled = false
            onTransitionSettledChange(false)
        }
    }

    private func startObservingTransitionIfNeeded() {
        guard transitionTask == nil, !isTransitionSettled else { return }
        transitionTask = Task { @MainActor [weak self] in
            let startedAt = ContinuousClock.now
            var stability = OnboardingTransitionStability()
            while !Task.isCancelled {
                // Sample presentation layers after SwiftUI has installed its animation.
                do {
                    try await Task.sleep(for: .milliseconds(16))
                } catch {
                    return
                }
                guard !Task.isCancelled, let self, isCurrentlyVisible, let window else { return }
                let elapsed = startedAt.duration(to: .now)
                guard elapsed < OnboardingTransitionStability.maximumWait else {
                    // A timeout never grants permission to request over another route.
                    return
                }
                if stability.sample(
                    frame: presentedFrame(in: window),
                    windowBounds: window.bounds,
                    isOpaque: isFullyOpaque,
                    elapsed: elapsed
                ) {
                    isTransitionSettled = true
                    onTransitionSettledChange(true)
                    return
                }
            }
        }
    }

    private var isReadyForTracking: Bool {
        guard isCurrentlyVisible, isTransitionSettled, isFullyOpaque, let window else {
            return false
        }
        return OnboardingTransitionStability.isInsideWindow(
            presentedFrame(in: window), windowBounds: window.bounds
        )
    }

    private func presentedFrame(in window: UIWindow) -> CGRect {
        let presentedLayer = layer.presentation() ?? layer
        return presentedLayer.convert(
            presentedLayer.bounds, to: window.layer.presentation() ?? window.layer
        )
    }

    private var isFullyOpaque: Bool {
        var ancestorView: UIView? = self
        while let view = ancestorView {
            if view.isHidden {
                return false
            }
            ancestorView = view.superview
        }
        var ancestorLayer: CALayer? = layer.presentation() ?? layer
        while let currentLayer = ancestorLayer {
            if currentLayer.isHidden || currentLayer.opacity < 0.999 {
                return false
            }
            ancestorLayer = currentLayer.superlayer
        }
        return true
    }

    private var isCurrentlyVisible: Bool {
        guard isEnabled, let window else {
            return false
        }

        return !window.isHidden
            && window.alpha > 0
            && window.windowScene?.activationState == .foregroundActive
    }

    private func startObservingVisibilityEnvironment() {
        let notifications: [Notification.Name] = [
            UIWindow.didBecomeVisibleNotification,
            UIWindow.didBecomeHiddenNotification,
            UIScene.didActivateNotification,
            UIScene.willDeactivateNotification
        ]

        for name in notifications {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibilityEnvironmentDidChange(_:)),
                name: name,
                object: nil
            )
        }
    }

    @objc
    private func visibilityEnvironmentDidChange(_: Notification) {
        reportVisibility()
    }
}
