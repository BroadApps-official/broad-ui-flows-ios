import Foundation
import UIKit

public extension BroadSupportEmailEnvironment {
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
    @MainActor
    static func current(
        bundle: Bundle = .main,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> BroadSupportEmailEnvironment {
        BroadSupportEmailEnvironment(
            installedVersion: bundle.string(for: "CFBundleShortVersionString"),
            buildNumber: bundle.string(for: "CFBundleVersion"),
            bundleIdentifier: bundle.bundleIdentifier ?? unavailableValue,
            systemVersion: UIDevice.current.systemVersion,
            deviceModel: hardwareIdentifier(),
            localeIdentifier: locale.identifier,
            timeZoneIdentifier: timeZone.identifier
        )
    }

    /// The `uname` machine string, for example `iPhone17,1`.
    ///
    /// On the simulator `uname` answers with the host Mac, so the simulated
    /// device is read from the environment instead — otherwise every letter
    /// sent from a debug build claims to come from an `arm64` Mac.
    static func hardwareIdentifier(
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
