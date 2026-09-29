import BroadCore
import Foundation

/// The typed result of a settings restore attempt.
public enum BroadSettingsRestoreResult: Equatable, Sendable {
    case restored
    case nothingToRestore
    case failed(AppError)
}

/// Ready settings values and actions for an app-owned SwiftUI layout.
/// Every action supplied by ``BroadSettingsHost`` passes through one tap gate.
@MainActor
public struct BroadSettingsScreen {
    public let userID: String
    public let version: String
    public let build: String
    public let isRestoring: Bool
    public let restoreResult: BroadSettingsRestoreResult?
    public let restoreMessage: String?
    public let canContactSupport: Bool
    /// True when the host received `showPaywall`, so subscription rows lead somewhere.
    public let canShowPaywall: Bool
    /// True for two seconds after ``copyUserID()``, to show "Copied".
    public let isUserIDCopied: Bool

    let actions: Actions

    public func restore() {
        actions.restore()
    }

    /// Opens the app's subscription paywall, for "Get Pro", "Upgrade" or a
    /// subscription status row.
    public func showPaywall() {
        actions.showPaywall()
    }

    /// Same as ``showPaywall()``. Purchases go through Adapty, so a
    /// "Manage subscription" row from the design only opens the paywall: there is
    /// no in-app cancellation and no App Store subscription page.
    public func manageSubscription() {
        actions.manageSubscription()
    }

    public func openPrivacyPolicy() {
        actions.openPrivacyPolicy()
    }

    public func openTerms() {
        actions.openTerms()
    }

    public func contactSupport() {
        actions.contactSupport()
    }

    public func copyUserID() {
        actions.copyUserID()
    }

    public func rateApp() {
        actions.rateApp()
    }

    public func shareApp() {
        actions.shareApp()
    }

    /// Builds a screen with the given values; actions default to no-ops, for
    /// previews of an app's own layout.
    public init(
        userID: String,
        version: String,
        build: String,
        isRestoring: Bool = false,
        restoreResult: BroadSettingsRestoreResult? = nil,
        restoreMessage: String? = nil,
        canContactSupport: Bool = false,
        canShowPaywall: Bool = false,
        isUserIDCopied: Bool = false
    ) {
        self.init(
            userID: userID,
            version: version,
            build: build,
            isRestoring: isRestoring,
            restoreResult: restoreResult,
            restoreMessage: restoreMessage,
            canContactSupport: canContactSupport,
            canShowPaywall: canShowPaywall,
            isUserIDCopied: isUserIDCopied,
            actions: Actions()
        )
    }

    init(
        userID: String,
        version: String,
        build: String,
        isRestoring: Bool,
        restoreResult: BroadSettingsRestoreResult?,
        restoreMessage: String?,
        canContactSupport: Bool,
        canShowPaywall: Bool,
        isUserIDCopied: Bool,
        actions: Actions
    ) {
        self.userID = userID
        self.version = version
        self.build = build
        self.isRestoring = isRestoring
        self.restoreResult = restoreResult
        self.restoreMessage = restoreMessage
        self.canContactSupport = canContactSupport
        self.canShowPaywall = canShowPaywall
        self.isUserIDCopied = isUserIDCopied
        self.actions = actions
    }

    struct Actions {
        var restore: @MainActor () -> Void = {}
        var showPaywall: @MainActor () -> Void = {}
        var manageSubscription: @MainActor () -> Void = {}
        var openPrivacyPolicy: @MainActor () -> Void = {}
        var openTerms: @MainActor () -> Void = {}
        var contactSupport: @MainActor () -> Void = {}
        var copyUserID: @MainActor () -> Void = {}
        var rateApp: @MainActor () -> Void = {}
        var shareApp: @MainActor () -> Void = {}
    }
}
