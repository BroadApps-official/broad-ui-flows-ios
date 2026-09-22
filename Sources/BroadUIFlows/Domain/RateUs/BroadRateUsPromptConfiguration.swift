import Foundation

/// When the app-owned Rate Us prompt may appear.
///
/// The prompt belongs after a successful target action — the moment the user
/// has something to rate — and never inside onboarding. A subscriber is asked
/// after a later action than a free user: a free user usually gets a single
/// trial action before the paywall, so waiting longer would mean never asking.
///
/// Counts are thresholds, not intervals: the policy asks once per install and
/// never repeats, even when the prompt was dismissed.
public struct BroadRateUsPromptConfiguration: Equatable, Sendable {
    /// Successful target actions a subscriber completes before the prompt.
    public let subscriberThreshold: Int
    /// Successful target actions a free user completes before the prompt.
    public let freeUserThreshold: Int
    /// Prefix of the keys the policy keeps in the host key-value store.
    public let storageKeyPrefix: String

    /// Creates the prompt rules. Thresholds below one are raised to one.
    ///
    /// - Parameters:
    ///   - subscriberThreshold: Target actions of a subscriber before the prompt.
    ///   - freeUserThreshold: Target actions of a free user before the prompt.
    ///   - storageKeyPrefix: Key prefix inside the host key-value store.
    public init(
        subscriberThreshold: Int = 2,
        freeUserThreshold: Int = 1,
        storageKeyPrefix: String = "broad.rate-us"
    ) {
        self.subscriberThreshold = max(1, subscriberThreshold)
        self.freeUserThreshold = max(1, freeUserThreshold)
        self.storageKeyPrefix = storageKeyPrefix
    }
}

/// Where the app is when a target action succeeds.
public enum BroadRateUsPromptContext: Equatable, Sendable {
    /// The main app flow: the prompt is allowed.
    case main
    /// Onboarding is on screen: the platform forbids Rate Us there.
    case onboarding
}
