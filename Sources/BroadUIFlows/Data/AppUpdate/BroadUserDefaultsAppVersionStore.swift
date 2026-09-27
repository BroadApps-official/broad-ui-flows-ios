import Foundation

/// UserDefaults storage for the app update baseline, scoped by bundle ID.
@MainActor
public struct BroadUserDefaultsAppVersionStore: BroadAppVersionBaselineStoreProtocol {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func version(for bundleID: String) -> String? {
        defaults.string(forKey: key(for: bundleID))
    }

    public func save(_ version: String, for bundleID: String) {
        defaults.set(version, forKey: key(for: bundleID))
    }

    public func installedVersion(for bundleID: String) -> String? {
        defaults.string(forKey: installedKey(for: bundleID))
    }

    public func saveInstalledVersion(_ version: String, for bundleID: String) {
        defaults.set(version, forKey: installedKey(for: bundleID))
    }

    private func key(for bundleID: String) -> String {
        "BroadUIFlows.appUpdate.baseline.\(bundleID)"
    }

    private func installedKey(for bundleID: String) -> String {
        "BroadUIFlows.appUpdate.installed.\(bundleID)"
    }
}
