import BroadCore
import Foundation

/// Decides whether the app-owned Rate Us prompt appears after a successful
/// target action (a reply, a generation — whatever the app defines).
///
/// The host calls ``recordTargetAction(isSubscribed:context:)`` once per
/// successful action. The policy counts actions in the host key-value store,
/// returns `true` exactly once per install when the threshold is reached and
/// marks the prompt as used before returning — a prompt that did not appear
/// is never retried, because asking twice is worse than not asking.
///
/// The native review request stays in the host: this module does not import
/// StoreKit. Onboarding is never a valid context.
public actor BroadRateUsPromptPolicy {
    private let configuration: BroadRateUsPromptConfiguration
    private let store: any KeyValueStoreProtocol

    private var promptedKey: String {
        configuration.storageKeyPrefix + ".prompted.v1"
    }

    private var countKey: String {
        configuration.storageKeyPrefix + ".target-actions.v1"
    }

    /// Creates a policy over the host key-value store.
    ///
    /// - Parameters:
    ///   - configuration: Thresholds and storage prefix.
    ///   - store: Durable host storage, for example the BroadCore state store.
    public init(
        configuration: BroadRateUsPromptConfiguration = BroadRateUsPromptConfiguration(),
        store: any KeyValueStoreProtocol
    ) {
        self.configuration = configuration
        self.store = store
    }

    /// Records one successful target action and answers whether to show the
    /// prompt now.
    ///
    /// - Parameters:
    ///   - isSubscribed: Whether the user has active premium access.
    ///   - context: Where the action happened; onboarding always answers `false`
    ///     and does not count the action.
    /// - Returns: `true` once per install, when the threshold is reached.
    ///   Storage errors answer `false`: a failed read is no reason to ask.
    public func recordTargetAction(
        isSubscribed: Bool,
        context: BroadRateUsPromptContext = .main
    ) async -> Bool {
        guard context == .main else { return false }
        guard let prompted = try? await store.read(promptedKey), prompted == .missing else {
            return false
        }

        let count = await storedCount() + 1
        try? await store.write(Self.encode(count), forKey: countKey)

        let threshold = isSubscribed
            ? configuration.subscriberThreshold
            : configuration.freeUserThreshold
        guard count >= threshold else { return false }

        do {
            try await store.write(Data([1]), forKey: promptedKey)
        } catch {
            return false
        }
        return true
    }

    /// Marks the prompt as used without showing it, for example after the user
    /// rated the app from a settings row.
    public func markPrompted() async {
        try? await store.write(Data([1]), forKey: promptedKey)
    }

    /// Whether the automatic prompt has already been used on this install.
    public func hasPrompted() async -> Bool {
        guard let entry = try? await store.read(promptedKey) else { return true }
        return entry != .missing
    }

    private func storedCount() async -> Int {
        guard case let .data(data) = try? await store.read(countKey),
              let text = String(bytes: data, encoding: .utf8),
              let value = Int(text)
        else {
            return 0
        }
        return max(0, value)
    }

    private static func encode(_ count: Int) -> Data {
        Data(String(count).utf8)
    }
}
