import BroadCore
import BroadUIFlows
import SwiftUI

/// Fixture of the AI data processing consent: the answer is shown on screen,
/// nothing is stored or sent.
struct FixtureAIDataConsentScreen: View {
    @State private var decision: BroadAIDataConsentDecision?

    var body: some View {
        BroadAIDataConsentView(configuration: Self.configuration) { decision = $0 }
            .overlay(alignment: .top) {
                if let decision {
                    Text(decision == .agreed ? "Agreed" : "Declined")
                        .font(.footnote.weight(.semibold))
                        .padding(8)
                        .background(.thinMaterial, in: .capsule)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
    }

    private static let configuration = BroadAIDataConsentConfiguration(
        appName: "Sample App",
        providers: [
            BroadAIProviderDisclosure(
                name: "Provider A",
                purpose: "text conversations",
                privacyPolicyURL: URL(string: "https://example.com/privacy/a")!
            ),
            BroadAIProviderDisclosure(
                name: "Provider B",
                purpose: "image and video generation",
                privacyPolicyURL: URL(string: "https://example.com/privacy/b")!
            )
        ],
        privacyPolicyURL: URL(string: "https://example.com/privacy")!,
        termsOfUseURL: URL(string: "https://example.com/terms")!
    )
}

/// Fixture of the Rate Us prompt rule over an in-memory store: each tap is one
/// successful target action of a free user or a subscriber.
struct FixtureRateUsPolicyScreen: View {
    @State private var policy = BroadRateUsPromptPolicy(store: FixtureKeyValueStore())
    @State private var log: [String] = []

    var body: some View {
        List {
            Section("Target action succeeded") {
                Button("Free user") { record(isSubscribed: false) }
                Button("Subscriber") { record(isSubscribed: true) }
                Button("During onboarding") { record(isSubscribed: false, context: .onboarding) }
                Button("Reset", role: .destructive) {
                    policy = BroadRateUsPromptPolicy(store: FixtureKeyValueStore())
                    log = []
                }
            }
            Section("Decisions") {
                ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.footnote.monospaced())
                }
            }
        }
        .navigationTitle("Rate Us rule")
    }

    private func record(isSubscribed: Bool, context: BroadRateUsPromptContext = .main) {
        Task {
            let prompt = await policy.recordTargetAction(isSubscribed: isSubscribed, context: context)
            let who = context == .onboarding ? "onboarding" : (isSubscribed ? "subscriber" : "free")
            log.append("\(who): \(prompt ? "show Rate Us" : "no prompt")")
        }
    }
}

/// In-memory key-value store for fixtures only.
actor FixtureKeyValueStore: KeyValueStoreProtocol {
    private var values: [String: Data] = [:]

    func read(_ key: String) async throws -> KeyValueStoreEntry {
        values[key].map(KeyValueStoreEntry.data) ?? .missing
    }

    func write(_ data: Data, forKey key: String) async throws {
        values[key] = data
    }

    func write(_ data: Data, forKey key: String, ifMatching snapshot: KeyValueStoreEntry) async throws -> Bool {
        guard try await read(key) == snapshot else { return false }
        values[key] = data
        return true
    }

    func remove(_ key: String) async throws {
        values[key] = nil
    }

    func remove(_ key: String, ifMatching snapshot: KeyValueStoreEntry) async throws -> Bool {
        guard try await read(key) == snapshot else { return false }
        values[key] = nil
        return true
    }
}
