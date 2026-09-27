import SwiftUI

public extension View {
    /// Checks for a newer App Store version when this view appears and offers an update.
    /// Attach it to the app's main tab view.
    func broadAppUpdateAlert(_ checker: BroadAppUpdateChecker) -> some View {
        modifier(BroadAppUpdateAlertModifier(checker: checker))
    }
}

private struct BroadAppUpdateAlertModifier: ViewModifier {
    @Environment(\.openURL) private var openURL
    @ObservedObject var checker: BroadAppUpdateChecker

    func body(content: Content) -> some View {
        content
            .task { await checker.check() }
            .alert(
                "Доступно обновление",
                isPresented: Binding(
                    get: { checker.availableUpdate != nil },
                    set: {
                        if !$0 {
                            checker.dismiss()
                        }
                    }
                )
            ) {
                Button("Отмена", role: .cancel) { checker.dismiss() }
                Button("Обновить") {
                    if let url = checker.availableUpdate?.url {
                        openURL(url)
                    }
                    checker.dismiss()
                }
            } message: {
                Text("В App Store доступна новая версия приложения.")
            }
    }
}
