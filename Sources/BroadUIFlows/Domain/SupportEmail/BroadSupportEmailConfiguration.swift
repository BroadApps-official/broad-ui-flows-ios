import Foundation

public enum BroadSupportEmailGreeting: Equatable, Sendable {
    case standard
    case ruBilling

    var text: String {
        switch self {
        case .standard:
            "Hi! I need help with the app."
        case .ruBilling:
            "Hi! I need help with the app. (ukassa)"
        }
    }
}

public struct BroadSupportEmailConfiguration: Equatable, Sendable {
    public let recipient: String
    public let subject: String
    public let greeting: BroadSupportEmailGreeting
    public let appName: String
    public let appStoreVersion: String
    public let installedVersion: String
    public let buildNumber: String
    public let bundleIdentifier: String
    public let systemVersion: String
    public let deviceModel: String
    public let localeIdentifier: String
    public let timeZoneIdentifier: String
    public let adaptyProfileID: String
    public let backendUserID: String
    public let subscriptionStatus: String
    /// Confirmed balance for apps with tokens. Use `nil` when absent or unknown;
    /// do not substitute zero for an unavailable balance.
    public let tokenBalance: String?
    /// Device identifier the backend account is bound to; `nil` omits the line.
    public let deviceID: String?
    /// Other available IDs in display order, especially the account credited with tokens.
    /// Empty labels or values are omitted from the email.
    public let additionalIdentifiers: [BroadSupportEmailIdentifier]
    public let supportLogData: Data
    public let supportLogFileName: String

    public init(
        recipient: String,
        subject: String,
        greeting: BroadSupportEmailGreeting,
        appName: String,
        appStoreVersion: String,
        installedVersion: String,
        buildNumber: String,
        bundleIdentifier: String,
        systemVersion: String,
        deviceModel: String,
        localeIdentifier: String,
        timeZoneIdentifier: String,
        adaptyProfileID: String,
        backendUserID: String,
        subscriptionStatus: String,
        tokenBalance: String? = nil,
        deviceID: String? = nil,
        additionalIdentifiers: [BroadSupportEmailIdentifier] = [],
        supportLogData: Data,
        supportLogFileName: String = "support-log.txt"
    ) {
        self.recipient = recipient
        self.subject = subject
        self.greeting = greeting
        self.appName = appName
        self.appStoreVersion = appStoreVersion
        self.installedVersion = installedVersion
        self.buildNumber = buildNumber
        self.bundleIdentifier = bundleIdentifier
        self.systemVersion = systemVersion
        self.deviceModel = deviceModel
        self.localeIdentifier = localeIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
        self.adaptyProfileID = adaptyProfileID
        self.backendUserID = backendUserID
        self.subscriptionStatus = subscriptionStatus
        self.tokenBalance = tokenBalance
        self.deviceID = deviceID
        self.additionalIdentifiers = additionalIdentifiers
        self.supportLogData = supportLogData
        self.supportLogFileName = supportLogFileName
    }
}

public struct BroadSupportEmailRequest: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let recipient: String
    public let subject: String
    public let body: String
    public let supportLogData: Data
    public let supportLogFileName: String

    init(
        recipient: String,
        subject: String,
        body: String,
        supportLogData: Data,
        supportLogFileName: String
    ) {
        id = UUID()
        self.recipient = recipient
        self.subject = subject
        self.body = body
        self.supportLogData = supportLogData
        self.supportLogFileName = supportLogFileName
    }

    public var externalComposeURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject)
        ]
        return components.url
    }
}
