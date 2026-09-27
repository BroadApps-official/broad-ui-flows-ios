import BroadUIFlows
import SwiftUI

/// Fixture routes for checking the optional slide and Reduce Motion fade.
struct AppFlowTransitionGallery: View {
    @State private var route: AppFlowRoute = .onboarding

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Onboarding") { route = .onboarding }
                Button("Paywall") { route = .initialPaywall }
                Button("Main") { route = .main }
            }
            .buttonStyle(.bordered)
            .frame(minHeight: 44)

            BroadAppFlowView(route: route, transition: .slide) {
                routeCard("Launch", color: .gray)
            } onboarding: {
                routeCard("Onboarding", color: .blue)
            } initialPaywall: {
                routeCard("Paywall", color: .purple)
            } main: {
                routeCard("Main", color: .green)
            }
        }
        .padding()
        .navigationTitle("App flow transition")
    }

    private func routeCard(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.title.bold())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack {
        AppFlowTransitionGallery()
    }
}
