import BroadMonetization
import BroadUIFlows
import SwiftUI

/// A custom token store drawn only from `BroadTokenPaywallScreen`. "Live" runs
/// it inside `BroadTokenPaywallHost` on fixtures (a purchase credits a local
/// ledger); the other entries render fixture states.
struct CustomTokenPaywallGallery: View {
    private let copy = BroadTokenPaywallCopy.english

    private enum Mode: Hashable {
        case live
        case preview(BroadTokenPaywallScreen.PreviewState)
    }

    @State private var mode: Mode = .live

    var body: some View {
        VStack(spacing: 0) {
            Picker("State", selection: $mode) {
                Text("live (fixtures, 3s close delay)").tag(Mode.live)
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
                CustomTokenPaywallExample(screen: .preview(state, copy: copy))
            }
        }
        .navigationTitle("Custom token paywall (host)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomTokenPaywallExample: View {
    let screen: BroadTokenPaywallScreen
    private let copy = BroadTokenPaywallCopy.english

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(copy.header.balanceTitle)
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
                    Button(copy.actions.closeAccessibilityLabel, systemImage: "xmark") { screen.close() }
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
            ProgressView(copy.states.loadingTitle)
        case .empty:
            VStack(spacing: 12) {
                Text(copy.states.emptyTitle)
                Text(copy.states.emptyMessage)
                Button(copy.actions.retryTitle) { screen.retry() }
            }
        case let .failed(error):
            VStack(spacing: 12) {
                Text(copy.states.errorTitle)
                Text(error.userMessage)
                Button(copy.actions.retryTitle) { screen.retry() }
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
            Text(package.tokens.map { "\($0) tokens" } ?? package.title ?? copy.products.fallbackTitle)
                .font(.headline)
            Spacer()
            if let savings = package.savingsPercent, package.isBestValue {
                Text("Save \(savings)%")
                    .font(.caption.bold())
            }
            Text(package.price ?? copy.products.unavailablePriceTitle)
                .font(.headline)
        }
        .padding(16)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(package.isSelected ? Color.accentColor : .secondary.opacity(0.3), lineWidth: 2)
        )
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
                        Text(screen.needsConfirmation ? copy.actions.confirmTitle : copy.actions.purchaseTitle)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(BroadNoPressEffectButtonStyle())
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .disabled(screen.needsConfirmation ? screen.isBusy : !screen.canPurchase)

            Button(copy.actions.recoverBalanceTitle) { screen.refreshBalance() }
                .font(.footnote)
                .frame(minHeight: 44)
                .disabled(screen.isBusy)
        }
        .padding(.bottom, 8)
    }
}
