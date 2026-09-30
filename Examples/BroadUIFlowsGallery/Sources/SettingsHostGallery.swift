import BroadUIFlows
import SwiftUI

/// Exercises the production host and its shared action gate on local fixtures.
@MainActor
struct SettingsHostGallery: View {
    @State private var isPaywallPresented = false
    @State private var presenterCalls = 0
    @State private var restoredCallbacks = 0
    @State private var noAppStoreLink = false
    @State private var noMail = true
    @State private var emptySupportAddress = false

    private var configuration: BroadSettingsConfiguration {
        BroadSettingsConfiguration(
            userID: "fixture-settings-user",
            appStoreLink: noAppStoreLink ? nil : URL(string: "https://apps.apple.com/app/id000000000")!,
            privacyPolicyURL: URL(string: "https://example.invalid/privacy")!,
            termsURL: URL(string: "https://example.invalid/terms")!,
            supportEmail: supportEmail,
            version: "Fixture",
            build: "Fixture",
            copy: .english
        )
    }

    var body: some View {
        BroadSettingsHost(
            configuration: configuration,
            showPaywall: {
                presenterCalls += 1
                isPaywallPresented = true
            },
            restorePurchases: FixtureRestore(),
            canSendMail: { !noMail && BroadSupportEmailComposer.canSendMail },
            onRestored: { _ in restoredCallbacks += 1 },
            content: { screen in
                Form {
                    Section("Fixture modes") {
                        Toggle("Без ссылки App Store", isOn: $noAppStoreLink)
                        Toggle("Без почты", isOn: $noMail)
                        Toggle("Пустой адрес поддержки", isOn: $emptySupportAddress)
                    }
                    Section("App actions") {
                        if screen.canShareApp {
                            Button("Share app") { screen.shareApp() }
                                .frame(minHeight: 44)
                        }
                        if screen.canRateApp {
                            Button("Rate app") { screen.rateApp() }
                                .frame(minHeight: 44)
                        }
                        if !screen.canShareApp, !screen.canRateApp {
                            Text("Share and Rate are hidden; legacy calls safely do nothing.")
                            Button("Call hidden Share + Rate") {
                                screen.shareApp()
                                screen.rateApp()
                            }
                            .frame(minHeight: 44)
                        }
                        Button("Contact support") { screen.contactSupport() }
                            .frame(minHeight: 44)
                        Button("Support + Get Pro (same tap)") {
                            screen.contactSupport()
                            screen.showPaywall()
                        }
                        .frame(minHeight: 44)
                    }
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

    private var supportEmail: BroadSupportEmailConfiguration {
        BroadSupportEmailConfiguration(
            recipient: emptySupportAddress ? "  " : "support@example.invalid",
            subject: "Gallery support fixture",
            greeting: .standard,
            appName: "BroadUIFlows Gallery",
            appStoreVersion: "Fixture",
            installedVersion: "Fixture",
            buildNumber: "Fixture",
            bundleIdentifier: "fixture.gallery",
            systemVersion: "Fixture",
            deviceModel: "Fixture device",
            localeIdentifier: "en_US",
            timeZoneIdentifier: "UTC",
            adaptyProfileID: "fixture-profile",
            backendUserID: "fixture-user",
            subscriptionStatus: "not_subscribed",
            supportLogData: Data("Fixture support log".utf8)
        )
    }
}
