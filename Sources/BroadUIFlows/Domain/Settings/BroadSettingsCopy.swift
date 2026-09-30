import Foundation

/// Texts the settings host produces itself; the layout owns every other word.
public struct BroadSettingsCopy: Equatable, Sendable {
    public let restoredMessage: String
    public let nothingToRestoreMessage: String
    public let supportUnavailableTitle: String
    public let supportUnavailableMessage: String
    public let copySupportAddressTitle: String
    public let closeSupportTitle: String
    public let openMailTitle: String
    public let supportAddressMissingTitle: String
    public let supportAddressMissingMessage: String

    /// Keeps the original initializer; new support texts use Russian defaults.
    public init(restoredMessage: String, nothingToRestoreMessage: String) {
        self.init(
            restoredMessage: restoredMessage,
            nothingToRestoreMessage: nothingToRestoreMessage,
            supportUnavailableTitle: Self.russian.supportUnavailableTitle,
            supportUnavailableMessage: Self.russian.supportUnavailableMessage,
            copySupportAddressTitle: Self.russian.copySupportAddressTitle,
            closeSupportTitle: Self.russian.closeSupportTitle,
            openMailTitle: Self.russian.openMailTitle,
            supportAddressMissingTitle: Self.russian.supportAddressMissingTitle,
            supportAddressMissingMessage: Self.russian.supportAddressMissingMessage
        )
    }

    /// Creates localized restore and support fallback texts.
    /// The host appends the support address to `supportUnavailableMessage`.
    public init(
        restoredMessage: String,
        nothingToRestoreMessage: String,
        supportUnavailableTitle: String,
        supportUnavailableMessage: String,
        copySupportAddressTitle: String,
        closeSupportTitle: String,
        openMailTitle: String,
        supportAddressMissingTitle: String,
        supportAddressMissingMessage: String
    ) {
        self.restoredMessage = restoredMessage
        self.nothingToRestoreMessage = nothingToRestoreMessage
        self.supportUnavailableTitle = supportUnavailableTitle
        self.supportUnavailableMessage = supportUnavailableMessage
        self.copySupportAddressTitle = copySupportAddressTitle
        self.closeSupportTitle = closeSupportTitle
        self.openMailTitle = openMailTitle
        self.supportAddressMissingTitle = supportAddressMissingTitle
        self.supportAddressMissingMessage = supportAddressMissingMessage
    }

    public static let russian = BroadSettingsCopy(
        restoredMessage: "Покупки восстановлены.",
        nothingToRestoreMessage: "Покупок для восстановления не найдено.",
        supportUnavailableTitle: "Почта недоступна",
        supportUnavailableMessage: "Вы можете скопировать адрес поддержки:",
        copySupportAddressTitle: "Скопировать адрес",
        closeSupportTitle: "Закрыть",
        openMailTitle: "Открыть почту",
        supportAddressMissingTitle: "Поддержка недоступна",
        supportAddressMissingMessage: "Адрес поддержки не указан. Попробуйте позже."
    )

    public static let english = BroadSettingsCopy(
        restoredMessage: "Purchases restored.",
        nothingToRestoreMessage: "No purchases to restore.",
        supportUnavailableTitle: "Mail unavailable",
        supportUnavailableMessage: "You can copy the support address:",
        copySupportAddressTitle: "Copy address",
        closeSupportTitle: "Close",
        openMailTitle: "Open mail",
        supportAddressMissingTitle: "Support unavailable",
        supportAddressMissingMessage: "The support address is not configured. Please try again later."
    )
}
