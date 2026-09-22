import SwiftUI

/// The user's answer on the AI data processing consent screen.
public enum BroadAIDataConsentDecision: Equatable, Sendable {
    case agreed
    case declined
}

/// Colors and fonts of the standard consent screen. Hosts pass their design
/// tokens; ``standard`` follows the system palette.
public struct BroadAIDataConsentTheme: Sendable {
    public let background: Color
    public let surface: Color
    public let primaryText: Color
    public let secondaryText: Color
    public let link: Color
    public let accent: Color
    public let actionForeground: Color
    public let border: Color
    public let titleFont: Font
    public let bodyFont: Font
    public let linkFont: Font
    public let actionFont: Font

    /// Creates a consent theme.
    public init(
        background: Color,
        surface: Color,
        primaryText: Color,
        secondaryText: Color,
        link: Color,
        accent: Color,
        actionForeground: Color,
        border: Color,
        titleFont: Font,
        bodyFont: Font,
        linkFont: Font,
        actionFont: Font
    ) {
        self.background = background
        self.surface = surface
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.link = link
        self.accent = accent
        self.actionForeground = actionForeground
        self.border = border
        self.titleFont = titleFont
        self.bodyFont = bodyFont
        self.linkFont = linkFont
        self.actionFont = actionFont
    }

    public static var standard: BroadAIDataConsentTheme {
        BroadAIDataConsentTheme(
            background: Color(uiColor: .systemBackground),
            surface: Color(uiColor: .secondarySystemBackground),
            primaryText: Color(uiColor: .label),
            secondaryText: Color(uiColor: .secondaryLabel),
            link: .accentColor,
            accent: .accentColor,
            actionForeground: .white,
            border: Color(uiColor: .separator),
            titleFont: .title2.weight(.semibold),
            bodyFont: .subheadline,
            linkFont: .subheadline.weight(.medium),
            actionFont: .body.weight(.semibold)
        )
    }
}

/// Standard AI data processing consent screen.
///
/// Names every AI provider with a link to its privacy policy, links the app's
/// own Privacy Policy and Terms of Use, and enables the primary action only
/// after the explicit checkbox — consent is a deliberate act, not a pass-through
/// tap. The host records the answer with ``BroadAIDataConsentStore`` and shows
/// the screen before the first AI submission.
public struct BroadAIDataConsentView: View {
    private let configuration: BroadAIDataConsentConfiguration
    private let theme: BroadAIDataConsentTheme
    private let onDecision: @MainActor (BroadAIDataConsentDecision) -> Void

    @State private var isChecked = false
    @Environment(\.openURL) private var openURL

    /// Creates the consent screen.
    ///
    /// - Parameters:
    ///   - configuration: App name, providers, legal links and copy.
    ///   - theme: Host design tokens.
    ///   - onDecision: Called with the user's answer; the host stores it.
    public init(
        configuration: BroadAIDataConsentConfiguration,
        theme: BroadAIDataConsentTheme = .standard,
        onDecision: @escaping @MainActor (BroadAIDataConsentDecision) -> Void
    ) {
        self.configuration = configuration
        self.theme = theme
        self.onDecision = onDecision
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(configuration.copy.title)
                        .font(theme.titleFont)
                        .foregroundStyle(theme.primaryText)
                    paragraph(configuration.text(configuration.copy.intro))
                    paragraph(configuration.text(configuration.copy.processing))
                    providers
                    paragraph(configuration.copy.retention)
                    paragraph(configuration.text(configuration.copy.noSale))
                    legalLinks
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            footer
        }
        .background(theme.background.ignoresSafeArea())
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(theme.bodyFont)
            .foregroundStyle(theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var providers: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(configuration.providers) { provider in
                Button {
                    openURL(provider.privacyPolicyURL)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(provider.name)
                            .font(theme.linkFont)
                            .foregroundStyle(theme.link)
                            .underline()
                        Text(provider.purpose)
                            .font(theme.bodyFont)
                            .foregroundStyle(theme.secondaryText)
                    }
                    .frame(minHeight: BroadInteractiveMetrics.minimumHitDimension)
                    .contentShape(.rect)
                }
                .buttonStyle(BroadNoPressEffectButtonStyle())
            }
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            link(configuration.copy.privacyPolicyTitle, url: configuration.privacyPolicyURL)
            link(configuration.copy.termsOfUseTitle, url: configuration.termsOfUseURL)
        }
    }

    private func link(_ title: String, url: URL) -> some View {
        Button(title) { openURL(url) }
            .font(theme.linkFont)
            .foregroundStyle(theme.link)
            .buttonStyle(BroadNoPressEffectButtonStyle())
            .frame(minHeight: BroadInteractiveMetrics.minimumHitDimension)
    }

    private var footer: some View {
        VStack(spacing: 16) {
            Button {
                isChecked.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isChecked ? theme.accent : theme.background)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(isChecked ? theme.accent : theme.primaryText, lineWidth: 1.5)
                        }
                        .overlay {
                            if isChecked {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(theme.actionForeground)
                            }
                        }
                        .frame(width: 24, height: 24)
                    Text(configuration.text(configuration.copy.checkbox))
                        .font(theme.bodyFont)
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(theme.surface, in: .rect(cornerRadius: 16, style: .continuous))
                .contentShape(.rect)
            }
            .buttonStyle(BroadNoPressEffectButtonStyle())

            HStack(spacing: 12) {
                action(configuration.copy.declineTitle, isPrimary: false, isEnabled: true) {
                    onDecision(.declined)
                }
                action(configuration.copy.agreeTitle, isPrimary: true, isEnabled: canAgree) {
                    onDecision(.agreed)
                }
            }
        }
        .padding(16)
        .background(theme.background)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.border).frame(height: 1 / 3)
        }
    }

    /// The checkbox is mandatory, and a consent that names no provider is not valid.
    private var canAgree: Bool {
        isChecked && configuration.isValid
    }

    /// A disabled primary action is shown with a muted fill, not a press effect:
    /// the state has to be readable before the tap.
    private func action(
        _ title: String,
        isPrimary: Bool,
        isEnabled: Bool,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Text(title)
                .font(theme.actionFont)
                .foregroundStyle(isPrimary ? theme.actionForeground : theme.primaryText)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    isPrimary ? theme.accent.opacity(isEnabled ? 1 : 0.4) : theme.surface,
                    in: .capsule
                )
        }
        .buttonStyle(BroadNoPressEffectButtonStyle())
        .disabled(!isEnabled)
    }
}
