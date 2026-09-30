import Foundation

/// Values supplied by the app for a custom settings screen.
public struct BroadSettingsConfiguration: Sendable {
    public let userID: String
    /// The validated App Store link; `nil` disables sharing and rating.
    public let appStoreLink: URL?
    /// A legacy reading API. Prefer ``appStoreLink`` for availability decisions.
    /// Returns `https://apps.apple.com` when no valid app link is configured.
    /// This property is obsolete in meaning but emits no deprecation warning.
    public var appStoreURL: URL {
        appStoreLink ?? URL(string: "https://apps.apple.com")!
    }

    public let privacyPolicyURL: URL
    public let termsURL: URL
    public let supportEmail: BroadSupportEmailConfiguration?
    public let version: String
    public let build: String
    public let copy: BroadSettingsCopy

    /// Keeps the original signature. Invalid App Store URLs disable app actions.
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
        self.init(
            userID: userID,
            appStoreLink: appStoreURL,
            privacyPolicyURL: privacyPolicyURL,
            termsURL: termsURL,
            supportEmail: supportEmail,
            version: version,
            build: build,
            copy: copy
        )
    }

    /// Pass `nil` while the app has no App Store link.
    /// Invalid links also become `nil`; legal URL preconditions are unchanged.
    public static func withAppStoreLink(
        userID: String,
        appStoreLink: URL?,
        privacyPolicyURL: URL,
        termsURL: URL,
        supportEmail: BroadSupportEmailConfiguration? = nil,
        version: String? = nil,
        build: String? = nil,
        copy: BroadSettingsCopy = .russian
    ) -> Self {
        Self(
            userID: userID,
            appStoreLink: appStoreLink,
            privacyPolicyURL: privacyPolicyURL,
            termsURL: termsURL,
            supportEmail: supportEmail,
            version: version,
            build: build,
            copy: copy
        )
    }

    private init(
        userID: String,
        appStoreLink: URL?,
        privacyPolicyURL: URL,
        termsURL: URL,
        supportEmail: BroadSupportEmailConfiguration? = nil,
        version: String? = nil,
        build: String? = nil,
        copy: BroadSettingsCopy = .russian
    ) {
        precondition(privacyPolicyURL.scheme?.lowercased() == "https")
        precondition(termsURL.scheme?.lowercased() == "https")
        self.userID = userID
        self.appStoreLink = Self.validatedAppStoreLink(appStoreLink)
        self.privacyPolicyURL = privacyPolicyURL
        self.termsURL = termsURL
        self.supportEmail = supportEmail
        self.version = version ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        self.build = build ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        self.copy = copy
    }

    private static func validatedAppStoreLink(_ url: URL?) -> URL? {
        guard let url else { return nil }
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "apps.apple.com",
              url.user == nil, url.password == nil,
              url.port == nil || url.port == 443
        else {
            // An invalid link means there is no link yet: sharing and rating stay hidden.
            return nil
        }
        return url
    }
}
