import BroadMonetization
import BroadUIFlows
import SwiftUI

/// A custom token store drawn only from `BroadTokenPaywallScreen`. "Live" runs
/// it inside `BroadTokenPaywallHost` on fixtures (a purchase credits a local
/// ledger); the other entries render fixture states.
struct CustomTokenPaywallGallery: View {
    private enum Mode: Hashable {
        case live
        case preview(BroadTokenPaywallScreen.PreviewState)
    }

    @State private var mode: Mode = .live

    var body: some View {
        VStack(spacing: 0) {
            Picker("State", selection: $mode) {
                Text("live (fixtures)").tag(Mode.live)
                ForEach(BroadTokenPaywallScreen.PreviewState.allCases, id: \.self) { state in
                    Text(String(describing: state)).tag(Mode.preview(state))
                }
            }
            .pickerStyle(.menu)
            .padding(.vertical, 8)

            switch mode {
            case .live:
                BroadTokenPaywallHost(
                    viewModel: FixtureTokenPaywallScreen.makeViewModel(showsAnalytics: false),
                    tokenAmount: { product in
                        // An app maps its product IDs or backend catalog to amounts.
                        ["fixture-token-product": 100][product.productID.rawValue]
                    },
                    onClose: {},
                    content: { screen in
                        CustomTokenPaywallExample(screen: screen)
                    }
                )
            case let .preview(state):
                CustomTokenPaywallExample(screen: .preview(state))
            }
        }
        .navigationTitle("Custom token paywall (host)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomTokenPaywallExample: View {
    let screen: BroadTokenPaywallScreen

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(screen.balanceText ?? "—")
                            .font(.title2.bold())
                        if screen.activity == .refreshingBalance {
                            ProgressView()
                        }
                    }
                }
                Spacer()
                if screen.canClose {
                    Button("Close", systemImage: "xmark") { screen.close() }
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            content
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var content: some View {
        switch screen.content {
        case .loading:
            ProgressView()
        case .empty:
            VStack(spacing: 12) {
                Text("No token packages right now.")
                Button("Try again") { screen.retry() }
            }
        case let .failed(error):
            VStack(spacing: 12) {
                Text(error.userMessage)
                Button("Try again") { screen.retry() }
            }
        case .packages:
            VStack(spacing: 10) {
                ForEach(screen.packages) { package in
                    packageRow(package)
                }
            }
            if let message = screen.noticeMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .onTapGesture { screen.dismissNotice() }
            }
        }
    }

    private func packageRow(_ package: BroadTokenPackage) -> some View {
        HStack {
            Text(package.tokens.map { "\($0) tokens" } ?? package.title ?? "Tokens")
                .font(.headline)
            Spacer()
            Text(package.price ?? "—")
                .font(.headline)
        }
        .padding(16)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(package.isSelected ? Color.accentColor : .secondary.opacity(0.3), lineWidth: 2)
        )
        .opacity(package.isAvailable ? 1 : 0.4)
        .contentShape(Rectangle())
        .onTapGesture { screen.select(package) }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { screen.select(package) }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                if screen.needsConfirmation {
                    screen.confirm()
                } else {
                    screen.purchase()
                }
            } label: {
                Group {
                    if screen.activity == .purchasing || screen.activity == .confirming {
                        ProgressView()
                    } else {
                        Text(screen.needsConfirmation ? "Check purchase" : "Buy")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(BroadNoPressEffectButtonStyle())
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .disabled(screen.needsConfirmation ? screen.isBusy : !screen.canPurchase)

            Button("Refresh balance") { screen.refreshBalance() }
                .font(.footnote)
                .frame(minHeight: 44)
                .disabled(screen.isBusy)
        }
        .padding(.bottom, 8)
    }
}
