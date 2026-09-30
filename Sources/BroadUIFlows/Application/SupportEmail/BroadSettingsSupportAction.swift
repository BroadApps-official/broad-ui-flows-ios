import Foundation

/// Resolves the host's support presentation without importing UI frameworks.
enum BroadSettingsSupportAction {
    case missingAddress
    case preparationFailed
    case compose(BroadSupportEmailRequest)
    case fallback(recipient: String, externalURL: URL?)

    static func resolve(
        configuration: BroadSupportEmailConfiguration?,
        canSendMail: Bool,
        canOpenURL: (URL) -> Bool
    ) -> Self {
        guard let configuration else { return .missingAddress }
        let recipient = configuration.recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !recipient.isEmpty else { return .missingAddress }
        if canSendMail {
            guard let request = BroadSupportEmailRequestBuilder.makeRequest(configuration: configuration) else {
                return .preparationFailed
            }
            return .compose(request)
        }

        // External mail receives no body promising an unattached support log.
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [URLQueryItem(name: "subject", value: configuration.subject)]
        let externalURL = components.url.flatMap { canOpenURL($0) ? $0 : nil }
        return .fallback(recipient: recipient, externalURL: externalURL)
    }
}
