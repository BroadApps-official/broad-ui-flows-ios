import BroadCore
import Foundation

/// Durable record of the user's consent to AI data processing.
///
/// The consent is asked once per install, before the first submission to an
/// AI provider — a chat message or a generation, whichever comes first.
/// Declining is not a dead end: the host asks again on the next submission.
/// The moment of consent is stored, not only the fact, so support mail can
/// say when the user agreed; a repeated ``accept(at:)`` keeps the first date.
public actor BroadAIDataConsentStore {
    private let store: any KeyValueStoreProtocol
    private let key: String

    /// Creates the consent store over the host key-value store.
    ///
    /// - Parameters:
    ///   - store: Durable host storage, for example the BroadCore state store.
    ///   - key: Storage key; change it only to ask every user again.
    public init(store: any KeyValueStoreProtocol, key: String = "broad.ai-data-consent.accepted-at.v1") {
        self.store = store
        self.key = key
    }

    /// When the user agreed, or `nil` when they have not agreed yet.
    public func acceptedAt() async -> Date? {
        guard case let .data(data) = try? await store.read(key),
              let text = String(bytes: data, encoding: .utf8),
              let seconds = TimeInterval(text)
        else {
            return nil
        }
        return Date(timeIntervalSince1970: seconds)
    }

    /// Whether AI submissions are allowed.
    public func hasAccepted() async -> Bool {
        await acceptedAt() != nil
    }

    /// Records the consent. A second call keeps the first date.
    public func accept(at date: Date = Date()) async {
        guard await acceptedAt() == nil else { return }
        try? await store.write(Data(String(date.timeIntervalSince1970).utf8), forKey: key)
    }
}
