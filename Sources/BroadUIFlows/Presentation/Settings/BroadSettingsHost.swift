import BroadMonetization
import SwiftUI
import UIKit

/// Supplies a custom settings layout with ready values and gated actions.
/// The app only draws ``BroadSettingsScreen`` and calls its actions.
@MainActor
public struct BroadSettingsHost<Content: View>: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var state: BroadSettingsState
    @State private var destination: Destination?
    @State private var supportAlert: SupportAlert?

    private let configuration: BroadSettingsConfiguration
    private var canSendMail: @MainActor () -> Bool
    private let showPaywall: @MainActor () -> Void
    private let content: @MainActor (BroadSettingsScreen) -> Content

    /// Creates a settings host around an app-owned layout.
    ///
    /// - Parameters:
    ///   - configuration: Account ID, legal links, optional App Store link and support email.
    ///   - showPaywall: Presents the app's subscription paywall, usually the
    ///     `settings` placement. ``BroadSettingsScreen/showPaywall()`` and
    ///     ``BroadSettingsScreen/manageSubscription()`` call it. Settings never open
    ///     App Store subscription management or cancellation for Adapty purchases.
    ///     It comes right after `configuration`, so code written for 6.x gets a clear
    ///     "missing argument for parameter 'showPaywall'" error.
    ///   - restorePurchases: The existing restore use case from BroadMonetization.
    ///   - onRestored: Receives the confirmed snapshot after a successful restore.
    ///   - content: The app's settings layout drawn from ``BroadSettingsScreen``.
    public init(
        configuration: BroadSettingsConfiguration,
        showPaywall: @escaping @MainActor () -> Void,
        restorePurchases: any RestorePurchasesUseCaseProtocol,
        onRestored: @escaping @MainActor (EntitlementSnapshot) -> Void = { _ in },
        @ViewBuilder content: @escaping @MainActor (BroadSettingsScreen) -> Content
    ) {
        self.configuration = configuration
        canSendMail = { BroadSupportEmailComposer.canSendMail }
        self.showPaywall = showPaywall
        self.content = content
        _state = StateObject(wrappedValue: BroadSettingsState(
            restorePurchases: restorePurchases,
            copy: configuration.copy,
            onRestored: onRestored
        ))
    }

    /// Overrides the system mail capability for local Gallery or fixture scenarios.
    public func supportMailCapability(_ canSendMail: @escaping @MainActor () -> Bool) -> Self {
        var host = self
        host.canSendMail = canSendMail
        return host
    }

    public var body: some View {
        content(screen)
            .sheet(item: $destination) { destination in
                switch destination {
                case let .safari(url):
                    BroadInAppSafariView(url: url).ignoresSafeArea()
                case let .email(request):
                    BroadSupportEmailComposer(request: request) { _ in
                        self.destination = nil
                    }
                case let .share(url):
                    BroadSettingsShareSheet(url: url)
                }
            }
            .alert(
                supportAlertTitle,
                isPresented: Binding(
                    get: { supportAlert != nil },
                    set: {
                        if !$0 {
                            supportAlert = nil
                        }
                    }
                ),
                presenting: supportAlert
            ) { alert in
                if case let .fallback(recipient, externalURL) = alert {
                    Button(configuration.copy.copySupportAddressTitle) {
                        state.performSupportAlertAction {
                            UIPasteboard.general.string = recipient
                        }
                    }
                    if let externalURL {
                        Button(configuration.copy.openMailTitle) {
                            state.performSupportAlertAction {
                                if UIApplication.shared.canOpenURL(externalURL) {
                                    openURL(externalURL)
                                }
                            }
                        }
                    }
                }
                Button(configuration.copy.closeSupportTitle, role: .cancel) {
                    state.performSupportAlertAction {}
                }
            } message: { alert in
                switch alert {
                case .missingAddress:
                    Text(configuration.copy.supportAddressMissingMessage)
                case .preparationFailed:
                    Text(configuration.copy.supportPreparationFailedMessage)
                case let .fallback(recipient, _):
                    Text(configuration.copy.supportUnavailableMessage + "\n\n" + recipient)
                }
            }
    }

    private var supportAlertTitle: String {
        switch supportAlert {
        case .missingAddress:
            configuration.copy.supportAddressMissingTitle
        case .preparationFailed:
            configuration.copy.supportPreparationFailedTitle
        case .fallback, nil:
            configuration.copy.supportUnavailableTitle
        }
    }

    private var screen: BroadSettingsScreen {
        BroadSettingsScreen(
            userID: configuration.userID,
            version: configuration.version,
            build: configuration.build,
            isRestoring: state.isRestoring,
            restoreResult: state.restoreResult,
            restoreMessage: state.restoreMessage,
            canContactSupport: configuration.supportEmail.flatMap(BroadSupportEmailRequestBuilder.makeRequest) != nil,
            isUserIDCopied: state.isUserIDCopied,
            canShareApp: configuration.appStoreLink != nil,
            canRateApp: configuration.appStoreLink != nil,
            actions: .init(
                restore: { state.restore() },
                showPaywall: {
                    state.perform { showPaywall() }
                },
                manageSubscription: {
                    state.perform { showPaywall() }
                },
                openPrivacyPolicy: {
                    state.perform { destination = .safari(configuration.privacyPolicyURL) }
                },
                openTerms: {
                    state.perform { destination = .safari(configuration.termsURL) }
                },
                contactSupport: {
                    state.perform { openSupport() }
                },
                copyUserID: {
                    state.perform { state.copyUserID(configuration.userID) }
                },
                rateApp: {
                    state.perform {
                        if let url = reviewURL {
                            openURL(url)
                        }
                    }
                },
                shareApp: {
                    state.perform {
                        if let url = configuration.appStoreLink {
                            destination = .share(url)
                        }
                    }
                }
            )
        )
    }

    private var reviewURL: URL? {
        guard let url = configuration.appStoreLink,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }
        components.queryItems = (components.queryItems ?? []).filter { $0.name != "action" }
            + [URLQueryItem(name: "action", value: "write-review")]
        return components.url
    }

    private func openSupport() {
        switch BroadSettingsSupportAction.resolve(
            configuration: configuration.supportEmail,
            canSendMail: canSendMail(),
            canOpenURL: { UIApplication.shared.canOpenURL($0) }
        ) {
        case .missingAddress:
            supportAlert = .missingAddress
        case .preparationFailed:
            supportAlert = .preparationFailed
        case let .compose(request):
            destination = .email(request)
        case let .fallback(recipient, externalURL):
            supportAlert = .fallback(recipient: recipient, externalURL: externalURL)
        }
    }
}

@MainActor
private final class BroadSettingsState: ObservableObject {
    @Published private(set) var isRestoring = false
    @Published private(set) var restoreResult: BroadSettingsRestoreResult?
    @Published private(set) var restoreMessage: String?
    @Published private(set) var isUserIDCopied = false

    private let restorePurchases: any RestorePurchasesUseCaseProtocol
    private let copy: BroadSettingsCopy
    private let onRestored: @MainActor (EntitlementSnapshot) -> Void
    private var nextActionAt = Date.distantPast
    private var copiedResetTask: Task<Void, Never>?

    init(
        restorePurchases: any RestorePurchasesUseCaseProtocol,
        copy: BroadSettingsCopy,
        onRestored: @escaping @MainActor (EntitlementSnapshot) -> Void
    ) {
        self.restorePurchases = restorePurchases
        self.copy = copy
        self.onRestored = onRestored
    }

    deinit {
        copiedResetTask?.cancel()
    }

    /// Copies the ID and raises `isUserIDCopied` for two seconds, so the layout
    /// can confirm the copy.
    func copyUserID(_ userID: String) {
        UIPasteboard.general.string = userID
        isUserIDCopied = true
        copiedResetTask?.cancel()
        copiedResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.isUserIDCopied = false
        }
    }

    func perform(_ action: () -> Void) {
        guard Date() >= nextActionAt else { return }
        nextActionAt = Date().addingTimeInterval(0.4)
        action()
    }

    /// Alert choices already own the interaction; execute immediately and renew the shared gate.
    func performSupportAlertAction(_ action: () -> Void) {
        nextActionAt = Date().addingTimeInterval(0.4)
        action()
    }

    func restore() {
        perform {
            guard !isRestoring else { return }
            isRestoring = true
            restoreResult = nil
            restoreMessage = nil
            let useCase = restorePurchases
            Task { @MainActor [weak self, useCase] in
                let outcome = await useCase()
                guard let self else { return }
                isRestoring = false
                switch outcome {
                case let .restored(snapshot):
                    restoreResult = .restored
                    restoreMessage = copy.restoredMessage
                    onRestored(snapshot)
                case .nothingFound:
                    restoreResult = .nothingToRestore
                    restoreMessage = copy.nothingToRestoreMessage
                case let .unavailable(error), let .failed(error):
                    restoreResult = .failed(error)
                    restoreMessage = error.userMessage
                }
            }
        }
    }
}

private enum Destination: Identifiable {
    case safari(URL)
    case email(BroadSupportEmailRequest)
    case share(URL)

    var id: String {
        switch self {
        case .safari: "safari"
        case .email: "email"
        case .share: "share"
        }
    }
}

private struct BroadSettingsShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private enum SupportAlert {
    case missingAddress
    case preparationFailed
    case fallback(recipient: String, externalURL: URL?)
}
