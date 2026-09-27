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
                    NavigationLink("Custom paywall (host)") {
                        CustomPaywallGallery()
                    }
                    NavigationLink("Special Offer paywall") {
                        FixturePaywallScreen(showsSpecialOffer: true)
                    }
                    NavigationLink("Token paywall") {
                        FixtureTokenPaywallScreen()
                    }
                    NavigationLink("Custom token paywall (host)") {
                        CustomTokenPaywallGallery()
                    }
                    NavigationLink("Support email") {
                        SupportEmailGallery()
                    }
                    NavigationLink("Settings (host model)") {
                        SettingsGallery()
                    }
                    NavigationLink("App update alert") {
                        AppUpdateGallery()
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
