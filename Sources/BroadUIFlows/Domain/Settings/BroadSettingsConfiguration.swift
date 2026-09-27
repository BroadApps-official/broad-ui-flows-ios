import Foundation

/// Values supplied by the app for a custom settings screen.
public struct BroadSettingsConfiguration: Sendable {
    public let userID: String
    public let appStoreURL: URL
    public let privacyPolicyURL: URL
    public let termsURL: URL
    public let supportEmail: BroadSupportEmailConfiguration?
    public let version: String
    public let build: String

    public init(
        userID: String,
        appStoreURL: URL,
        privacyPolicyURL: URL,
        termsURL: URL,
        supportEmail: BroadSupportEmailConfiguration? = nil,
        version: String? = nil,
        build: String? = nil
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
    }
}
