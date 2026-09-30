import BroadCore
import CoreGraphics
import Foundation

@main
@MainActor
enum SettingsAndOnboardingProbe {
    static func main() async {
        do {
            try appStoreLinks()
            try supportActions()
            try transitionStability()
            try transitionObservationLifecycle()
            try await trackingLifecycle()
        } catch {
            print("FAIL: settings and onboarding: \(error)")
            exit(1)
        }
    }

    private static func appStoreLinks() throws {
        let legal = URL(string: "https://example.invalid/legal")!
        let inferredConfiguration = BroadSettingsConfiguration.init
        let make: (String, URL, URL, URL, BroadSupportEmailConfiguration?, String?, String?, BroadSettingsCopy)
            -> BroadSettingsConfiguration = BroadSettingsConfiguration.init
        let valid = URL(string: "https://apps.apple.com/app/id000000000")!
        let configured = inferredConfiguration("fixture", valid, legal, legal, nil, "Fixture", "Fixture", .english)
        try require(configured.appStoreLink == valid && configured.appStoreURL == valid, "Legacy valid link must be preserved")
        for value in ["https://example.invalid", "http://apps.apple.com/app/id0", "/relative", "mailto:support@example.invalid",
                      "https://apps.apple.com.example.invalid", "https://user@apps.apple.com", "https://apps.apple.com:999/app/id0"] {
            let configuration = make("fixture", URL(string: value)!, legal, legal, nil, nil, nil, .russian)
            try require(configuration.appStoreLink == nil, "Invalid link must fail closed")
            try require(configuration.appStoreURL.absoluteString == "https://apps.apple.com", "Legacy getter must stay nonoptional")
        }
        let noLink = BroadSettingsConfiguration.withAppStoreLink(
            userID: "fixture", appStoreLink: nil, privacyPolicyURL: legal, termsURL: legal
        )
        try require(noLink.appStoreLink == nil, "Explicit nil link must be accepted")
        var calls = 0
        let screen = BroadSettingsScreen(
            userID: "fixture", version: "Fixture", build: "Fixture", isRestoring: false, restoreResult: nil,
            restoreMessage: nil, canContactSupport: true, isUserIDCopied: false, canShareApp: false, canRateApp: false,
            actions: .init(rateApp: { calls += 1 }, shareApp: { calls += 1 })
        )
        screen.rateApp()
        screen.shareApp()
        try require(calls == 0, "Unavailable App Store actions must be no-ops")
        let preview = BroadSettingsScreen.previewWithAppStoreActions(screen, canShareApp: true, canRateApp: true)
        preview.rateApp()
        preview.shareApp()
        try require(preview.canShareApp && preview.canRateApp && calls == 0, "Named preview must use no-op actions")
        let legacyScreen: @MainActor (String, String, String, Bool, BroadSettingsRestoreResult?, String?, Bool, Bool)
            -> BroadSettingsScreen = BroadSettingsScreen.init
        _ = legacyScreen("fixture", "1", "1", false, nil, nil, false, false)
        let legacyCopy: (String, String) -> BroadSettingsCopy = BroadSettingsCopy.init
        let inferredCopy = BroadSettingsCopy.init
        try require(inferredCopy("Custom restore", "Custom empty") == legacyCopy("Custom restore", "Custom empty"),
                    "Inferred copy initializer must preserve the legacy signature")
        let copy = legacyCopy("Custom restore", "Custom empty")
        try require(copy.restoredMessage == "Custom restore", "Legacy restore text must be preserved")
        try require(copy.copySupportAddressTitle == BroadSettingsCopy.russian.copySupportAddressTitle, "Legacy fallback must be Russian")
        try require(BroadSettingsCopy.english.openMailTitle == "Open mail", "English fallback must be localized")
        let custom = BroadSettingsCopy.localized(
            restoredMessage: "Restored", nothingToRestoreMessage: "Empty",
            supportUnavailable: ("No mail", "Copy the address"), copySupportAddressTitle: "Copy",
            closeSupportTitle: "Close", openMailTitle: "Mail", supportAddressMissing: ("No address", "Try later"),
            supportPreparationFailed: ("No attachment", "Retry later")
        )
        try require(custom.supportPreparationFailedTitle == "No attachment" && custom.supportPreparationFailedMessage == "Retry later",
                    "Named copy factory must preserve localized preparation failure texts")
        pass("App Store link validation, legacy initializer references, reading API, no-op actions and localized copy")
    }

    private static func supportActions() throws {
        for canSend in [false, true] {
            for canOpen in [false, true] {
                var checks = 0
                let action = BroadSettingsSupportAction.resolve(configuration: support(), canSendMail: canSend) { url in
                    checks += 1
                    return canOpen && url.scheme == "mailto"
                }
                switch action {
                case let .compose(request):
                    try require(canSend && checks == 0, "Native compose must not open or check external mail")
                    try require(request.recipient == "support@example.invalid", "Address must be trimmed")
                    try require(!request.supportLogData.isEmpty, "Native compose must retain its attachment")
                case let .fallback(recipient, url):
                    try require(!canSend && checks == 1, "Missing native mail must produce the alert fallback")
                    try require(recipient == "support@example.invalid", "Copy action must use the trimmed address")
                    try require((url != nil) == canOpen, "External mail action requires canOpenURL")
                    let query = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems ?? []
                    try require(query.allSatisfy { $0.name == "subject" }, "External mail must not promise an unattached log")
                case .missingAddress:
                    throw ContractFailure(description: "Configured address must not disappear")
                case .preparationFailed:
                    throw ContractFailure(description: "Valid support log must compose successfully")
                }
                for invalid in [support(log: Data()), support(fileName: ""), support(fileName: " \n ")] {
                    var invalidChecks = 0
                    let result = BroadSettingsSupportAction.resolve(configuration: invalid, canSendMail: canSend) { _ in
                        invalidChecks += 1
                        return canOpen
                    }
                    if canSend {
                        guard case .preparationFailed = result else {
                            throw ContractFailure(description: "Invalid attachment needs a preparation alert, never a mail fallback")
                        }
                        try require(invalidChecks == 0, "Preparation failure must not check external mail")
                    } else {
                        guard case let .fallback(_, url) = result else {
                            throw ContractFailure(description: "Missing native mail must retain its copy/close fallback")
                        }
                        try require(invalidChecks == 1 && (url != nil) == canOpen, "No-mail fallback still checks URL capability")
                    }
                }
                for missing in [nil, support(recipient: " \n ")] {
                    let result = BroadSettingsSupportAction.resolve(configuration: missing, canSendMail: canSend) { _ in
                        throwAwayURLCheck()
                        return canOpen
                    }
                    guard case .missingAddress = result else {
                        throw ContractFailure(description: "Empty support needs its own alert")
                    }
                }
            }
        }
        pass("Native compose, copy/close fallback, conditional mailto, missing address, invalid attachments and no duplicate presentation")
    }

    private static func throwAwayURLCheck() {
        fatalError("A missing address must never check an external URL")
    }

    private static func support(
        recipient: String = " support@example.invalid ",
        log: Data = Data("Fixture support log".utf8),
        fileName: String = "support-log.txt"
    ) -> BroadSupportEmailConfiguration {
        BroadSupportEmailConfiguration(
            recipient: recipient, subject: "Fixture & subject", greeting: .standard, appName: "Fixture",
            appStoreVersion: "Fixture", installedVersion: "Fixture", buildNumber: "Fixture", bundleIdentifier: "fixture",
            systemVersion: "Fixture", deviceModel: "Fixture", localeIdentifier: "en_US", timeZoneIdentifier: "UTC",
            adaptyProfileID: "fixture-profile", backendUserID: "fixture-user", subscriptionStatus: "not_subscribed",
            supportLogData: log, supportLogFileName: fileName
        )
    }

    private static func transitionStability() throws {
        let bounds = CGRect(x: 0, y: 0, width: 393, height: 852)
        var stability = OnboardingTransitionStability()
        for (x, time) in [(393.0, 0), (200.0, 100), (20.0, 200), (0.0, 250), (0.0, 349)] {
            try require(!stability.sample(frame: bounds.offsetBy(dx: x, dy: 0), windowBounds: bounds,
                                          isOpaque: true, elapsed: .milliseconds(time)), "ATT must wait through slide and settling")
        }
        try require(stability.sample(frame: bounds, windowBounds: bounds, isOpaque: true, elapsed: .milliseconds(350)),
                    "Resting slide must settle after 100 ms")
        var fade = OnboardingTransitionStability()
        try require(!fade.sample(frame: bounds, windowBounds: bounds, isOpaque: false, elapsed: .milliseconds(400)), "Fade must finish")
        try require(!fade.sample(frame: bounds, windowBounds: bounds, isOpaque: true, elapsed: .milliseconds(500)), "Opacity starts settling")
        try require(fade.sample(frame: bounds, windowBounds: bounds, isOpaque: true, elapsed: .milliseconds(600)), "Opaque frame must settle")
        var moving = OnboardingTransitionStability()
        let inset = bounds.insetBy(dx: 40, dy: 40)
        for time in stride(from: 0, through: 250, by: 50) {
            try require(!moving.sample(frame: inset.offsetBy(dx: CGFloat(time) / 50, dy: 0), windowBounds: bounds,
                                       isOpaque: true, elapsed: .milliseconds(time)), "Movement inside the window must reset settling")
        }
        try require(!moving.sample(frame: inset, windowBounds: bounds, isOpaque: true, elapsed: .seconds(3)), "Timeout must fail closed")
        var noGeometry = OnboardingTransitionStability()
        try require(!noGeometry.sample(frame: .zero, windowBounds: bounds, isOpaque: true, elapsed: .seconds(1)), "Empty host cannot settle")
        pass("Transition end: movement, 100 ms settling, Reduce Motion opacity, inset layouts and bounded fail-closed timeout")
    }

    private static func trackingLifecycle() async throws {
        let recorder = ProbeTrackingRecorder()
        let model = onboarding(recorder: recorder)
        model.onboardingDidAppear()
        model.applicationActiveDidChange(true)
        model.windowVisibilityDidChange(true)
        try await Task.sleep(for: .milliseconds(150))
        try require(recorder.calls == 0, "onAppear alone must never start ATT")
        model.firstSlideDidAppear()
        try await Task.sleep(for: .milliseconds(20))
        try require(recorder.calls == 0, "Delay must start after the visibility signal")
        model.firstSlideDidDisappear()
        try await Task.sleep(for: .milliseconds(100))
        try require(recorder.calls == 0, "Leaving the first slide must cancel ATT")
        model.firstSlideDidAppear()
        try await eventually("ATT after visible first slide") { recorder.calls == 1 }
        model.firstSlideDidAppear()
        try await Task.sleep(for: .milliseconds(100))
        try require(recorder.calls == 1, "ATT must be requested once")
        for disabled in [true, false] {
            let skipped = onboarding(recorder: recorder, disabled: disabled, noPages: !disabled)
            skipped.onboardingDidAppear()
            skipped.applicationActiveDidChange(true)
            skipped.windowVisibilityDidChange(true)
            skipped.firstSlideDidAppear()
            try await Task.sleep(for: .milliseconds(100))
            try require(recorder.calls == 1, "Disabled or invalid onboarding must never request ATT")
        }
        let cancelled = onboarding(recorder: recorder)
        cancelled.onboardingDidAppear()
        cancelled.applicationActiveDidChange(true)
        cancelled.windowVisibilityDidChange(true)
        cancelled.firstSlideDidAppear()
        cancelled.onboardingDidDisappear()
        try await Task.sleep(for: .milliseconds(100))
        try require(recorder.calls == 1, "Disappearing onboarding must cancel ATT")
        let hidden = onboarding(recorder: recorder)
        hidden.onboardingDidAppear()
        hidden.applicationActiveDidChange(true)
        var visible = true
        hidden.windowVisibilityDidChange(true, validateCurrentVisibility: { visible })
        hidden.firstSlideDidAppear()
        visible = false
        try await Task.sleep(for: .milliseconds(100))
        try require(recorder.calls == 1, "Window visibility must be revalidated after delay")
        let resumedRecorder = ProbeTrackingRecorder()
        let resumed = onboarding(recorder: resumedRecorder)
        resumed.onboardingDidAppear()
        resumed.applicationActiveDidChange(true)
        resumed.windowVisibilityDidChange(true)
        resumed.firstSlideDidAppear()
        resumed.applicationActiveDidChange(false)
        resumed.windowVisibilityDidChange(false)
        resumed.firstSlideDidDisappear()
        try await Task.sleep(for: .milliseconds(100))
        try require(resumedRecorder.calls == 0, "Early activity or visibility loss must cancel ATT")
        resumed.applicationActiveDidChange(true)
        resumed.windowVisibilityDidChange(true)
        resumed.firstSlideDidAppear()
        try await eventually("ATT after visibility restoration") { resumedRecorder.calls == 1 }
        pass("ATT lifecycle: no request during loader/appearance, delayed visible first slide, once-only, cancellation and disabled/invalid onboarding")
    }

    private static func transitionObservationLifecycle() throws {
        var observation = OnboardingTransitionObservation()
        let hidden = observation.begin()!
        try require(observation.begin() == nil, "Only one transition observation may run")
        try require(observation.finish(generation: hidden), "Early visibility loss must release observation ownership")
        let restored = observation.begin()!
        try require(restored != hidden, "Restored visibility must start a new generation")
        observation.cancel()
        let replacement = observation.begin()!
        try require(!observation.finish(generation: restored), "Cancelled task completion must not clear its replacement")
        try require(observation.activeGeneration == replacement, "Replacement must retain observation ownership")
        try require(observation.finish(generation: replacement), "Current completion must release observation ownership")
        let timeout = observation.begin()!
        var stability = OnboardingTransitionStability()
        let bounds = CGRect(x: 0, y: 0, width: 393, height: 852)
        try require(!stability.sample(frame: bounds, windowBounds: bounds, isOpaque: true, elapsed: .seconds(3)),
                    "Timeout must never report a settled transition")
        try require(observation.finish(generation: timeout), "Timeout must release observation ownership")
        try require(observation.begin() != nil, "Later visibility reports may observe again after timeout")
        pass("Transition observation: early exit, visibility restoration, cancellation generation guard and fail-closed timeout retry")
    }

    private static func onboarding(recorder: ProbeTrackingRecorder, disabled: Bool = false, noPages: Bool = false) -> OnboardingViewModel {
        OnboardingViewModel(
            configuration: OnboardingConfiguration(
                pages: noPages ? [] : [OnboardingPageConfiguration(id: "first", title: "First", media: .init(identifier: "fixture"))],
                continueTitle: "Continue", completionTitle: "Finish", progressAccessibilityLabel: "Progress",
                trackingAuthorizationPolicy: disabled ? .disabled : .afterFirstSlide(delay: .milliseconds(60))
            ),
            requestTrackingAuthorizationUseCase: recorder
        )
    }
}

@MainActor
private final class ProbeTrackingRecorder: TrackingAuthorizationUseCaseProtocol {
    private(set) var calls = 0
    func callAsFunction() async -> TrackingAuthorizationStatus {
        calls += 1
        return .denied
    }
}
