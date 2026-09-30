import CoreGraphics
import Foundation

/// A bounded, fail-closed visibility check shared with executable contract probes.
struct OnboardingTransitionStability {
    static let maximumWait: Duration = .seconds(3)
    static let settlingInterval: Duration = .milliseconds(100)
    private var candidateFrame: CGRect?
    private var candidateSince: Duration = .zero

    mutating func sample(
        frame: CGRect,
        windowBounds: CGRect,
        isOpaque: Bool,
        elapsed: Duration
    ) -> Bool {
        guard elapsed < Self.maximumWait,
              isOpaque,
              Self.isInsideWindow(frame, windowBounds: windowBounds)
        else {
            candidateFrame = nil
            return false
        }
        if let candidateFrame, Self.framesMatch(candidateFrame, frame) {
            return elapsed - candidateSince >= Self.settlingInterval
        }
        candidateFrame = frame
        candidateSince = elapsed
        return false
    }

    static func isInsideWindow(_ frame: CGRect, windowBounds: CGRect) -> Bool {
        // Allow insets for app-owned layouts, while rejecting a sliding host.
        !frame.isEmpty && !frame.isInfinite && !frame.isNull
            && frame.minX >= windowBounds.minX - 1
            && frame.maxX <= windowBounds.maxX + 1
            && frame.maxY > windowBounds.minY
            && frame.minY < windowBounds.maxY
    }

    private static func framesMatch(_ first: CGRect, _ second: CGRect) -> Bool {
        abs(first.minX - second.minX) <= 0.5
            && abs(first.minY - second.minY) <= 0.5
            && abs(first.width - second.width) <= 0.5
            && abs(first.height - second.height) <= 0.5
    }
}
