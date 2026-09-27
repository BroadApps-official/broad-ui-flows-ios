import Foundation

/// A validated App Store version and its product page.
public struct BroadAppStoreListing: Sendable {
    public let version: BroadAppVersion
    public let url: URL

    public init(version: BroadAppVersion, url: URL) {
        self.version = version
        self.url = url
    }
}

/// Finds the current listing for the app's bundle identifier.
public protocol BroadAppStoreLookupProtocol: Sendable {
    func lookup(bundleID: String) async throws -> BroadAppStoreListing?
}

/// Persists the baseline version used by the update rule.
@MainActor
public protocol BroadAppVersionBaselineStoreProtocol {
    /// The version above which a store update should be offered.
    func version(for bundleID: String) -> String?
    func save(_ version: String, for bundleID: String)
    /// The last installed version, used to detect an app update even when the
    /// initial baseline was higher than the installed version.
    func installedVersion(for bundleID: String) -> String?
    func saveInstalledVersion(_ version: String, for bundleID: String)
}

enum BroadAppUpdateRule {
    static func initialBaseline(installed: BroadAppVersion, store: BroadAppVersion) -> BroadAppVersion {
        max(installed, store)
    }

    static func refreshedBaseline(
        installed: BroadAppVersion,
        previousInstall: BroadAppVersion?,
        baseline: BroadAppVersion
    ) -> BroadAppVersion {
        if let previousInstall, previousInstall != installed {
            return installed
        }
        return baseline
    }

    static func shouldAlert(store: BroadAppVersion, baseline: BroadAppVersion) -> Bool {
        store > baseline
    }
}
