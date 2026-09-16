import Foundation

/// The facts about the running app and phone that a support letter states, read
/// from the system rather than restated by the host.
///
/// ``BroadSupportEmailConfiguration`` asks for seven of them. None is a product
/// decision: the bundle knows its version and identifier, and Foundation knows
/// the rest. Left to the host, each application read the same
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

    /// Reads every field from the running app and phone.
    ///
    /// A value the system does not report reads as ``unavailableValue`` instead
    /// of an empty line, so a letter never arrives with a blank field that looks
    /// like the sender deleted it.
    ///
    /// - Parameters:
    ///   - bundle: which bundle the version, build and identifier come from.
    ///   - locale: the locale to report; defaults to the app's current one.
    ///   - timeZone: the time zone to report; defaults to the phone's current one.
    public static func current(
        bundle: Bundle = .main,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> BroadSupportEmailEnvironment {
        BroadSupportEmailEnvironment(
            installedVersion: bundle.string(for: "CFBundleShortVersionString"),
            buildNumber: bundle.string(for: "CFBundleVersion"),
            bundleIdentifier: bundle.bundleIdentifier ?? unavailableValue,
            systemVersion: systemVersion(),
            deviceModel: hardwareIdentifier(),
            localeIdentifier: locale.identifier,
            timeZoneIdentifier: timeZone.identifier
        )
    }

    /// The operating system version the way `UIDevice` spells it — `18.2`, or
    /// `18.2.1` when there is a patch component.
    ///
    /// Read from `ProcessInfo` rather than `UIDevice`, so the whole reader stays
    /// free of UIKit and of the main actor: a support letter is often assembled
    /// off the main thread, and this is not a value worth hopping for.
    public static func systemVersion(
        version: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
    ) -> String {
        let core = "\(version.majorVersion).\(version.minorVersion)"
        return version.patchVersion == 0 ? core : "\(core).\(version.patchVersion)"
    }

    /// The `uname` machine string, for example `iPhone17,1`.
    ///
    /// On the simulator `uname` answers with the host Mac, so the simulated
    /// device is read from the environment instead — otherwise every letter
    /// sent from a debug build claims to come from an `arm64` Mac.
    public static func hardwareIdentifier(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String {
        let simulated = environment["SIMULATOR_MODEL_IDENTIFIER"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let simulated, !simulated.isEmpty {
            return simulated
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer -> String? in
            let bytes = Array(buffer.prefix { $0 != 0 })
            return String(bytes: bytes, encoding: .utf8)
        }
        let trimmed = (identifier ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? unavailableValue : trimmed
    }
}

private extension Bundle {
    func string(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return BroadSupportEmailEnvironment.unavailableValue
        }
        return value
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
