import SwiftUI

/// Texts of the update alert.
public struct BroadAppUpdateAlertCopy: Equatable, Sendable {
    public let title: String
    public let message: String
    public let cancelTitle: String
    public let updateTitle: String

    public init(title: String, message: String, cancelTitle: String, updateTitle: String) {
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.updateTitle = updateTitle
    }

    public static let russian = BroadAppUpdateAlertCopy(
        title: "Доступно обновление",
        message: "В App Store доступна новая версия приложения.",
        cancelTitle: "Отмена",
        updateTitle: "Обновить"
    )

    public static let english = BroadAppUpdateAlertCopy(
        title: "Update available",
        message: "A new version of the app is available on the App Store.",
        cancelTitle: "Cancel",
        updateTitle: "Update"
    )
}

public extension View {
    /// Checks for a newer App Store version when this view appears and offers an update.
    /// Attach it to the app's main tab view, not to the splash or other screens.
    func broadAppUpdateAlert(
        _ checker: BroadAppUpdateChecker,
        copy: BroadAppUpdateAlertCopy = .russian
    ) -> some View {
        modifier(BroadAppUpdateAlertModifier(checker: checker, copy: copy))
    }
}

private struct BroadAppUpdateAlertModifier: ViewModifier {
    @Environment(\.openURL) private var openURL
    @ObservedObject var checker: BroadAppUpdateChecker
    let copy: BroadAppUpdateAlertCopy

    func body(content: Content) -> some View {
        content
            .task { await checker.check() }
            .alert(
                copy.title,
                isPresented: Binding(
                    get: { checker.availableUpdate != nil },
                    set: {
                        if !$0 {
                            checker.dismiss()
                        }
                    }
                )
            ) {
                Button(copy.cancelTitle, role: .cancel) { checker.dismiss() }
                Button(copy.updateTitle) {
                    if let url = checker.availableUpdate?.url {
                        openURL(url)
                    }
                    checker.dismiss()
                }
            } message: {
                Text(copy.message)
            }
    }
}
