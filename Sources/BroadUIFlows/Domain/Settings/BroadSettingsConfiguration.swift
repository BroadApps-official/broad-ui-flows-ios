import Foundation

/// Texts the settings host produces itself; the layout owns every other word.
public struct BroadSettingsCopy: Equatable, Sendable {
    public let restoredMessage: String
    public let nothingToRestoreMessage: String

    public init(restoredMessage: String, nothingToRestoreMessage: String) {
        self.restoredMessage = restoredMessage
        self.nothingToRestoreMessage = nothingToRestoreMessage
    }

    public static let russian = BroadSettingsCopy(
        restoredMessage: "Покупки восстановлены.",
        nothingToRestoreMessage: "Покупок для восстановления не найдено."
    )

    public static let english = BroadSettingsCopy(
        restoredMessage: "Purchases restored.",
        nothingToRestoreMessage: "No purchases to restore."
    )
}

/// Values supplied by the app for a custom settings screen.
public struct BroadSettingsConfiguration: Sendable {
    public let userID: String
    public let appStoreURL: URL
    public let privacyPolicyURL: URL
    public let termsURL: URL
    public let supportEmail: BroadSupportEmailConfiguration?
    public let version: String
    public let build: String
    public let copy: BroadSettingsCopy

    public init(
        userID: String,
        appStoreURL: URL,
        privacyPolicyURL: URL,
        termsURL: URL,
        supportEmail: BroadSupportEmailConfiguration? = nil,
        version: String? = nil,
        build: String? = nil,
        copy: BroadSettingsCopy = .russian
    ) {
        precondition(appStoreURL.scheme?.lowercased() == "https" && appStoreURL.host?.lowercased() == "apps.apple.com")
        precondition(privacyPolicyURL.scheme?.lowercased() == "https")
        precondition(termsURL.scheme?.lowercased() == "https")
        self.userID = userID
        self.appStoreURL = appStoreURL
        self.privacyPolicyURL = privacyPolicyURL
        self.termsURL = termsURL
        self.supportEmail = supportEmail
        self.version = version ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        self.build = build ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        self.copy = copy
    }
}
