import BroadUIFlows
import SwiftUI

/// A custom paywall drawn only from `BroadPaywallScreen`: the kind of screen an
/// app builds from its Figma frame. In an app it sits inside `BroadPaywallHost`;
/// here it renders the fixture states, so no SDK or purchase runs.
struct CustomPaywallGallery: View {
    @State private var state: BroadPaywallScreen.PreviewState = .plans

    var body: some View {
        VStack(spacing: 0) {
            Picker("State", selection: $state) {
                ForEach(BroadPaywallScreen.PreviewState.allCases, id: \.self) { state in
                    Text(String(describing: state)).tag(state)
                }
            }
            .pickerStyle(.menu)
            .padding(.vertical, 8)

            CustomPaywallExample(screen: .preview(state))
        }
        .navigationTitle("Custom paywall (host)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomPaywallExample: View {
    let screen: BroadPaywallScreen

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                if screen.canClose {
                    Button("Close", systemImage: "xmark") { screen.close() }
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            Text("Unlock everything")
                .font(.largeTitle.bold())
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
            Text("Plans are not available right now.")
        case let .failed(error):
            VStack(spacing: 12) {
                Text(error.userMessage)
                Button("Try again") { screen.retry() }
            }
        case .plans:
            VStack(spacing: 10) {
                ForEach(screen.plans) { plan in
                    planRow(plan)
                }
            }
            if let message = screen.noticeMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(screen.notice?.isFailure == true ? .red : .secondary)
            }
        }
    }

    private func planRow(_ plan: BroadPaywallPlan) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.periodText ?? "")
                    .font(.headline)
                if let weekly = plan.weeklyPrice {
                    Text("\(weekly) / week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let savings = plan.savingsPercent, plan.isBestValue {
                Text("−\(savings)%")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2), in: Capsule())
            }
            Text(plan.price ?? "—")
                .font(.headline)
        }
        .padding(16)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(plan.isSelected ? Color.accentColor : .secondary.opacity(0.3), lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture { screen.select(plan) }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { screen.select(plan) }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                screen.purchase()
            } label: {
                Group {
                    if screen.activity == .purchasing {
                        ProgressView()
                    } else {
                        Text("Continue")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(BroadNoPressEffectButtonStyle())
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .disabled(!screen.canPurchase)

            HStack(spacing: 20) {
                Button("Restore") { screen.restore() }
                    .disabled(screen.isBusy)
                ForEach(screen.legalLinks) { link in
                    Button(link.title) { screen.open(link) }
                }
            }
            .font(.footnote)
            .frame(minHeight: 44)
        }
        .padding(.bottom, 8)
    }
}
