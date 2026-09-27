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

    private let configuration: BroadSettingsConfiguration
    private let content: @MainActor (BroadSettingsScreen) -> Content

    public init(
        configuration: BroadSettingsConfiguration,
        restorePurchases: any RestorePurchasesUseCaseProtocol,
        onRestored: @escaping @MainActor (EntitlementSnapshot) -> Void = { _ in },
        @ViewBuilder content: @escaping @MainActor (BroadSettingsScreen) -> Content
    ) {
        self.configuration = configuration
        self.content = content
        _state = StateObject(wrappedValue: BroadSettingsState(
            restorePurchases: restorePurchases,
            copy: configuration.copy,
            onRestored: onRestored
        ))
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
            actions: .init(
                restore: { state.restore() },
                manageSubscription: {
                    state.perform {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            openURL(url)
                        }
                    }
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
                    state.perform { destination = .share(configuration.appStoreURL) }
                }
            )
        )
    }

    private var reviewURL: URL? {
        guard var components = URLComponents(url: configuration.appStoreURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = (components.queryItems ?? []).filter { $0.name != "action" }
            + [URLQueryItem(name: "action", value: "write-review")]
        return components.url
    }

    private func openSupport() {
        guard let configuration = configuration.supportEmail,
              let request = BroadSupportEmailRequestBuilder.makeRequest(configuration: configuration)
        else {
            return
        }
        if BroadSupportEmailComposer.canSendMail {
            destination = .email(request)
        } else if let url = request.externalComposeURL {
            openURL(url)
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
