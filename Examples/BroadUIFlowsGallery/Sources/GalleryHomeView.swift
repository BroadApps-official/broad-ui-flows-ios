import SwiftUI

struct GalleryHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("UI scenarios") {
                    NavigationLink("Onboarding") {
                        FixtureOnboardingScreen()
                    }
                    NavigationLink("Loadable states") {
                        LoadableStatesGallery()
                    }
                    NavigationLink("Subscription paywall") {
                        FixturePaywallScreen(showsSpecialOffer: false)
                    }
                    NavigationLink("Special Offer paywall") {
                        FixturePaywallScreen(showsSpecialOffer: true)
                    }
                    NavigationLink("Token paywall") {
                        FixtureTokenPaywallScreen()
                    }
                    NavigationLink("RU subscription management") {
                        FixtureRUSubscriptionScreen()
                    }
                }

                Section("Safety") {
                    Label("Fixtures only", systemImage: "shippingbox")
                    Label("No SDK activation", systemImage: "network.slash")
                    Label("No financial operations", systemImage: "creditcard.trianglebadge.exclamationmark")
                }
            }
            .navigationTitle("BroadUIFlows")
        }
    }
}
