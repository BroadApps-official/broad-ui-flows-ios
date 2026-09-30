import BroadUIFlows
import SwiftUI

/// Exercises the production host and its shared action gate on local fixtures.
@MainActor
struct SettingsHostGallery: View {
    @State private var isPaywallPresented = false
    @State private var presenterCalls = 0
    @State private var restoredCallbacks = 0

    private let configuration = BroadSettingsConfiguration(
        userID: "fixture-settings-user",
        appStoreURL: URL(string: "https://apps.apple.com/app/id000000000")!,
        privacyPolicyURL: URL(string: "https://example.invalid/privacy")!,
        termsURL: URL(string: "https://example.invalid/terms")!,
        version: "Fixture",
        build: "Fixture",
        copy: .english
    )

    var body: some View {
        BroadSettingsHost(
            configuration: configuration,
            showPaywall: {
                presenterCalls += 1
                isPaywallPresented = true
            },
            restorePurchases: FixtureRestore(),
            onRestored: { _ in restoredCallbacks += 1 },
            content: { screen in
                Form {
                    Section("Account") {
                        LabeledContent("User ID", value: screen.userID)
                        LabeledContent("Version", value: screen.version)
                        LabeledContent("Build", value: screen.build)
                    }
                    Section("Subscription") {
                        Button("Get Pro") { screen.showPaywall() }
                            .frame(minHeight: 44)
                        Button("Manage subscription") { screen.manageSubscription() }
                            .frame(minHeight: 44)
                        Button("Get Pro + Manage (same tap)") {
                            screen.showPaywall()
                            screen.manageSubscription()
                        }
                        .frame(minHeight: 44)
                        Button("Manage + Get Pro (same tap)") {
                            screen.manageSubscription()
                            screen.showPaywall()
                        }
                        .frame(minHeight: 44)
                    }
                    Section("Restore fixture") {
                        Button("Restore purchases") { screen.restore() }
                            .frame(minHeight: 44)
                        if screen.isRestoring {
                            ProgressView()
                        }
                        if let message = screen.restoreMessage {
                            Text(message)
                        }
                        LabeledContent("Restored callbacks", value: String(restoredCallbacks))
                    }
                    Section("Shared gate") {
                        LabeledContent("Presenter calls", value: String(presenterCalls))
                        Text("Both subscription actions open the same sheet. Two actions within 400 ms count as one call.")
                    }
                }
            }
        )
        .sheet(isPresented: $isPaywallPresented) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Paywall · settings")
                        .font(.title)
                    Text("Local fixture — no SDK, network or payments.")
                    LabeledContent("Presenter calls", value: String(presenterCalls))
                }
                .padding(20)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isPaywallPresented = false }
                            .frame(minHeight: 44)
                    }
                }
            }
        }
        .navigationTitle("Settings host")
    }
}
