import Combine
import Foundation

/// Checks the App Store without blocking the app or presenting on network errors.
@MainActor
public final class BroadAppUpdateChecker: ObservableObject {
    /// A new version to offer, or `nil` when there is no alert.
    @Published public private(set) var availableUpdate: BroadAppStoreListing?

    private let bundleID: String
    private let installedVersion: String
    private let lookup: any BroadAppStoreLookupProtocol
    private let baselineStore: any BroadAppVersionBaselineStoreProtocol
    private var isChecking = false
    private var isPreview = false

    public init(
        bundleID: String,
        installedVersion: String,
        lookup: any BroadAppStoreLookupProtocol,
        baselineStore: any BroadAppVersionBaselineStoreProtocol
    ) {
        self.bundleID = bundleID
        self.installedVersion = installedVersion
        self.lookup = lookup
        self.baselineStore = baselineStore
    }

    /// Uses the default lookup client and UserDefaults baseline adapter.
    public convenience init(
        bundleID: String = Bundle.main.bundleIdentifier ?? "",
        installedVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        lookup: any BroadAppStoreLookupProtocol = BroadAppStoreLookupClient()
    ) {
        self.init(
            bundleID: bundleID,
            installedVersion: installedVersion,
            lookup: lookup,
            baselineStore: BroadUserDefaultsAppVersionStore()
        )
    }

    /// Performs one lookup. The first successful lookup records a baseline and stays quiet.
    public func check() async {
        guard !isPreview,
              !isChecking,
              !bundleID.isEmpty,
              let installed = BroadAppVersion(installedVersion)
        else { return }
        isChecking = true
        defer { isChecking = false }
        availableUpdate = nil

        let stored = baselineStore.version(for: bundleID).flatMap(BroadAppVersion.init)
        let previousInstall = baselineStore.installedVersion(for: bundleID).flatMap(BroadAppVersion.init)
        let baseline: BroadAppVersion?
        if let stored {
            let refreshed = BroadAppUpdateRule.refreshedBaseline(
                installed: installed,
                previousInstall: previousInstall,
                baseline: stored
            )
            if refreshed != stored {
                baselineStore.save(refreshed.rawValue, for: bundleID)
            }
            baselineStore.saveInstalledVersion(installed.rawValue, for: bundleID)
            baseline = refreshed
        } else {
            baseline = nil
        }

        guard let listing = try? await lookup.lookup(bundleID: bundleID) else { return }
        if let baseline {
            if BroadAppUpdateRule.shouldAlert(store: listing.version, baseline: baseline) {
                availableUpdate = listing
            }
        } else {
            let baseline = BroadAppUpdateRule.initialBaseline(installed: installed, store: listing.version)
            baselineStore.save(baseline.rawValue, for: bundleID)
            baselineStore.saveInstalledVersion(installed.rawValue, for: bundleID)
        }
    }

    /// Dismisses the current prompt. A later check can present a newer version.
    public func dismiss() {
        availableUpdate = nil
    }
}

public extension BroadAppUpdateChecker {
    /// Network-free checker fixtures for previews and Gallery.
    enum PreviewState: CaseIterable, Sendable {
        case firstLaunch
        case noUpdate
        case unavailable
        case updateAvailable
    }

    /// Makes a checker that never performs a network request or writes defaults.
    static func preview(_ state: PreviewState) -> BroadAppUpdateChecker {
        let checker = BroadAppUpdateChecker(bundleID: "fixture.app", installedVersion: "1.0.0")
        checker.isPreview = true
        if state == .updateAvailable,
           let version = BroadAppVersion("1.0.10"),
           let url = URL(string: "https://apps.apple.com/app/fixture") {
            checker.availableUpdate = BroadAppStoreListing(version: version, url: url)
        }
        return checker
    }
}
