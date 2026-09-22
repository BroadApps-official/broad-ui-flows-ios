import Foundation

public enum BroadSupportEmailRequestBuilder {
    public static func makeRequest(
        configuration: BroadSupportEmailConfiguration
    ) -> BroadSupportEmailRequest? {
        let recipient = configuration.recipient.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let attachmentName = configuration.supportLogFileName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !recipient.isEmpty,
              !configuration.supportLogData.isEmpty,
              !attachmentName.isEmpty
        else {
            return nil
        }

        return BroadSupportEmailRequest(
            recipient: recipient,
            subject: configuration.subject,
            body: makeBody(configuration: configuration),
            supportLogData: configuration.supportLogData,
            supportLogFileName: attachmentName
        )
    }

    private static func makeBody(
        configuration: BroadSupportEmailConfiguration
    ) -> String {
        let optionalIDs = [
            optionalLine(label: "Device ID", value: configuration.deviceID),
            optionalLine(label: "Token balance", value: configuration.tokenBalance)
        ]
        let accountIDs = configuration.additionalIdentifiers.map {
            optionalLine(label: $0.label, value: $0.value)
        }
        let additionalLines = (optionalIDs + accountIDs)
            .compactMap(\.self)
            .map { "\n" + $0 }
            .joined()

        return """
        \(configuration.greeting.text)

        --- App info ---
        App: \(configuration.appName)
        Version: \(configuration.appStoreVersion) (App Store)
        Installed: \(configuration.installedVersion) (\(configuration.buildNumber))
        Bundle: \(configuration.bundleIdentifier)

        --- Device ---
        System: iOS \(configuration.systemVersion)
        Device: \(configuration.deviceModel)
        Locale: \(configuration.localeIdentifier)
        TimeZone: \(configuration.timeZoneIdentifier)

        --- IDs ---
        Adapty profileID: \(configuration.adaptyProfileID)
        Backend userID: \(configuration.backendUserID)
        Subscription: \(configuration.subscriptionStatus)\(additionalLines)

        --- Diagnostics ---
        A support log is attached.

        --- Describe the problem below ---

        """
    }

    private static func optionalLine(label: String, value: String?) -> String? {
        guard let value else { return nil }
        let cleanLabel = singleLine(label)
        let cleanValue = singleLine(value)
        guard !cleanLabel.isEmpty, !cleanValue.isEmpty else { return nil }
        return "\(cleanLabel): \(cleanValue)"
    }

    private static func singleLine(_ value: String) -> String {
        value.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
