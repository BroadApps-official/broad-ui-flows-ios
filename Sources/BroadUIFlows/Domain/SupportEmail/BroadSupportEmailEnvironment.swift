import Foundation

/// The facts about the running app and phone that a support letter states, read
/// from the system rather than restated by the host.
///
/// ``BroadSupportEmailConfiguration`` asks for seven of them. None is a product
/// decision: the bundle knows its version and identifier, and UIKit and
/// Foundation know the rest. Left to the host, each application read the same
/// values again, and the device model in particular came out as the same block
/// of `utsname` reflection copied from project to project — spelled slightly
/// differently every time.
public struct BroadSupportEmailEnvironment: Equatable, Sendable {
    /// What a field reads as when the system has no answer.
    public static let unavailableValue = "unavailable"

    public let installedVersion: String
    public let buildNumber: String
    public let bundleIdentifier: String
    public let systemVersion: String
    /// The hardware identifier — `iPhone17,1` — not the marketing name.
    ///
    /// Support needs to tell one phone from another, and only this string does
    /// that reliably; iOS carries no public marketing name at runtime.
    public let deviceModel: String
    public let localeIdentifier: String
    public let timeZoneIdentifier: String

    public init(
        installedVersion: String,
        buildNumber: String,
        bundleIdentifier: String,
        systemVersion: String,
        deviceModel: String,
        localeIdentifier: String,
        timeZoneIdentifier: String
    ) {
        self.installedVersion = installedVersion
        self.buildNumber = buildNumber
        self.bundleIdentifier = bundleIdentifier
        self.systemVersion = systemVersion
        self.deviceModel = deviceModel
        self.localeIdentifier = localeIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}

public extension BroadSupportEmailConfiguration {
    /// Builds the configuration from a read environment, leaving the host only
    /// the fields that are its own to decide.
    ///
    /// `adaptyProfileID`, `backendUserID` and `subscriptionStatus` stay explicit:
    /// they come from the monetization layer, and a letter that quietly reports
    /// the wrong account is worse than one that says the value is unavailable.
    init(
        recipient: String,
        subject: String,
        greeting: BroadSupportEmailGreeting,
        appName: String,
        appStoreVersion: String,
        environment: BroadSupportEmailEnvironment,
        adaptyProfileID: String,
        backendUserID: String,
        subscriptionStatus: String,
        supportLogData: Data,
        supportLogFileName: String = "support-log.txt"
    ) {
        self.init(
            recipient: recipient,
            subject: subject,
            greeting: greeting,
            appName: appName,
            appStoreVersion: appStoreVersion,
            installedVersion: environment.installedVersion,
            buildNumber: environment.buildNumber,
            bundleIdentifier: environment.bundleIdentifier,
            systemVersion: environment.systemVersion,
            deviceModel: environment.deviceModel,
            localeIdentifier: environment.localeIdentifier,
            timeZoneIdentifier: environment.timeZoneIdentifier,
            adaptyProfileID: adaptyProfileID,
            backendUserID: backendUserID,
            subscriptionStatus: subscriptionStatus,
            supportLogData: supportLogData,
            supportLogFileName: supportLogFileName
        )
    }
}
