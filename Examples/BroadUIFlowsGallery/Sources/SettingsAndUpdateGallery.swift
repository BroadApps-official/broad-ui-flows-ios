import BroadUIFlows
import SwiftUI

/// Fixture layouts exercise the screen models without invoking their actions.
struct SettingsGallery: View {
    @State private var state: BroadSettingsScreen.PreviewState = .ready

    var body: some View {
        Form {
            Picker("Restore state", selection: $state) {
                ForEach(BroadSettingsScreen.PreviewState.allCases, id: \.self) { state in
                    Text(String(describing: state)).tag(state)
                }
            }
            Section("Account") {
                let screen = BroadSettingsScreen.preview(state)
                LabeledContent("User ID", value: screen.userID)
                LabeledContent("Version", value: screen.version)
                LabeledContent("Build", value: screen.build)
            }
            Section("Actions") {
                let screen = BroadSettingsScreen.preview(state)
                Button { screen.restore() } label: {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                }
                .frame(minHeight: 44)
                Button { screen.showPaywall() } label: {
                    Label("Get Pro — opens the paywall", systemImage: "crown")
                }
                .frame(minHeight: 44)
                Button { screen.manageSubscription() } label: {
                    Label("Manage subscription — opens the same paywall", systemImage: "creditcard")
                }
                .frame(minHeight: 44)
                Button { screen.openPrivacyPolicy() } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                .frame(minHeight: 44)
                Button { screen.openTerms() } label: {
                    Label("Terms of Use", systemImage: "doc.text")
                }
                .frame(minHeight: 44)
                Button { screen.contactSupport() } label: {
                    Label("Contact support", systemImage: "envelope")
                }
                .frame(minHeight: 44)
                Button { screen.copyUserID() } label: {
                    Label("Copy user ID", systemImage: "doc.on.doc")
                }
                .frame(minHeight: 44)
                Button { screen.rateApp() } label: {
                    Label("Rate app", systemImage: "star")
                }
                .frame(minHeight: 44)
                Button { screen.shareApp() } label: {
                    Label("Share app", systemImage: "square.and.arrow.up")
                }
                .frame(minHeight: 44)
                if screen.isRestoring {
                    ProgressView()
                }
                if let message = screen.restoreMessage {
                    Text(message)
                }
            }
        }
        .navigationTitle("Settings fixtures")
    }
}

struct AppUpdateGallery: View {
    var body: some View {
        List {
            ForEach(BroadAppUpdateChecker.PreviewState.allCases, id: \.self) { state in
                NavigationLink(String(describing: state)) {
                    AppUpdateFixture(state: state)
                }
            }
        }
        .navigationTitle("Update fixtures")
    }
}

private struct AppUpdateFixture: View {
    @StateObject private var checker: BroadAppUpdateChecker
    private let state: BroadAppUpdateChecker.PreviewState

    init(state: BroadAppUpdateChecker.PreviewState) {
        self.state = state
        _checker = StateObject(wrappedValue: .preview(state))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(String(describing: state))
            Text("This fixture never looks up the App Store or opens a link.")
        }
        .broadAppUpdateAlert(checker)
        .environment(\.openURL, OpenURLAction { _ in .handled })
    }
}
