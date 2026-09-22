import Foundation

/// A third-party AI provider that receives what the user submits.
///
/// App Review 5.1.1(i) and 5.1.2(i) expect the consent screen to name every
/// recipient of personal data and to link its privacy policy, not only the
/// app's own policy.
public struct BroadAIProviderDisclosure: Equatable, Sendable, Identifiable {
    /// Provider name shown to the user, for example "OpenAI".
    public let name: String
    /// What the provider processes, for example "text conversations".
    public let purpose: String
    /// The provider's privacy policy.
    public let privacyPolicyURL: URL

    public var id: String {
        name + "|" + purpose
    }

    /// Creates a provider disclosure.
    public init(name: String, purpose: String, privacyPolicyURL: URL) {
        self.name = name
        self.purpose = purpose
        self.privacyPolicyURL = privacyPolicyURL
    }
}

/// Texts of the AI data processing consent screen.
///
/// `%@` in ``intro``, ``processing`` and ``noSale`` is replaced with the app name.
/// Hosts localize the copy themselves; ``english`` and ``russian`` are ready
/// defaults.
public struct BroadAIDataConsentCopy: Equatable, Sendable {
    public let title: String
    public let intro: String
    public let processing: String
    public let retention: String
    public let noSale: String
    public let checkbox: String
    public let privacyPolicyTitle: String
    public let termsOfUseTitle: String
    public let agreeTitle: String
    public let declineTitle: String

    /// Creates the consent copy.
    public init(
        title: String,
        intro: String,
        processing: String,
        retention: String,
        noSale: String,
        checkbox: String,
        privacyPolicyTitle: String,
        termsOfUseTitle: String,
        agreeTitle: String,
        declineTitle: String
    ) {
        self.title = title
        self.intro = intro
        self.processing = processing
        self.retention = retention
        self.noSale = noSale
        self.checkbox = checkbox
        self.privacyPolicyTitle = privacyPolicyTitle
        self.termsOfUseTitle = termsOfUseTitle
        self.agreeTitle = agreeTitle
        self.declineTitle = declineTitle
    }

    public static let english = BroadAIDataConsentCopy(
        title: "AI Data Processing Consent",
        intro: "To chat or create with %@, you need to agree to how the content you send is shared.",
        processing: "%@ sends what you choose to submit — your messages and any files you attach — " +
            "to its own servers and to the AI providers handling your request:",
        retention: "Your conversations are kept so you can return to them later. " +
            "Deleting a chat removes its content from our servers.",
        noSale: "%@ never sells your data or uses it for advertising, tracking, profiling, or training AI models.",
        checkbox: "I agree that what I submit will be shared with %@ and the relevant AI provider " +
            "only to process my request.",
        privacyPolicyTitle: "Privacy Policy",
        termsOfUseTitle: "Terms of Use",
        agreeTitle: "Agree and Continue",
        declineTitle: "Not Now"
    )

    public static let russian = BroadAIDataConsentCopy(
        title: "Согласие на обработку данных ИИ",
        intro: "Чтобы общаться и создавать в %@, согласитесь с тем, как передаётся отправленное вами.",
        processing: "%@ отправляет то, что вы решили передать, — сообщения и приложенные файлы — " +
            "на свои серверы и ИИ-провайдерам, которые обрабатывают запрос:",
        retention: "Переписка хранится, чтобы к ней можно было вернуться. " +
            "Удаление чата удаляет его содержимое с наших серверов.",
        noSale: "%@ не продаёт ваши данные и не использует их для рекламы, отслеживания, " +
            "профилирования или обучения моделей ИИ.",
        checkbox: "Я согласен, что отправленное мной будет передано %@ и соответствующему " +
            "ИИ-провайдеру только для обработки запроса.",
        privacyPolicyTitle: "Политика конфиденциальности",
        termsOfUseTitle: "Условия использования",
        agreeTitle: "Согласиться",
        declineTitle: "Не сейчас"
    )
}

/// Everything the consent screen shows.
public struct BroadAIDataConsentConfiguration: Equatable, Sendable {
    public let appName: String
    /// Every AI provider that receives user content. Must not be empty.
    public let providers: [BroadAIProviderDisclosure]
    public let privacyPolicyURL: URL
    public let termsOfUseURL: URL
    public let copy: BroadAIDataConsentCopy

    /// Creates the consent configuration.
    public init(
        appName: String,
        providers: [BroadAIProviderDisclosure],
        privacyPolicyURL: URL,
        termsOfUseURL: URL,
        copy: BroadAIDataConsentCopy = .english
    ) {
        self.appName = appName
        self.providers = providers
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.copy = copy
    }

    /// A consent that names no provider does not satisfy App Review.
    public var isValid: Bool {
        !appName.isEmpty && !providers.isEmpty
    }

    func text(_ template: String) -> String {
        template.replacingOccurrences(of: "%@", with: appName)
    }
}
