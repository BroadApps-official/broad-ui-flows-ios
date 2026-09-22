import BroadUIFlows
import Foundation
import SwiftUI

struct SupportEmailGallery: View {
    @State private var includesTokens = true

    var body: some View {
        Form {
            Toggle("App uses tokens", isOn: $includesTokens)
            Section("Email preview — fixtures only") {
                Text(request?.body ?? "Support request unavailable")
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Support email")
    }

    private var request: BroadSupportEmailRequest? {
        BroadSupportEmailRequestBuilder.makeRequest(
            configuration: BroadSupportEmailConfiguration(
                recipient: "support@example.invalid",
                subject: "Gallery support preview",
                greeting: .standard,
                appName: "BroadUIFlows Gallery",
                appStoreVersion: "4.1.0",
                installedVersion: "4.1.0",
                buildNumber: "1",
                bundleIdentifier: "fixture.gallery",
                systemVersion: "17.0",
                deviceModel: "Fixture device",
                localeIdentifier: "en_US",
                timeZoneIdentifier: "UTC",
                adaptyProfileID: "fixture-adapty-profile",
                backendUserID: "fixture-backend-user",
                subscriptionStatus: "inactive",
                tokenBalance: includesTokens ? "100" : nil,
                deviceID: "fixture-device",
                additionalIdentifiers: includesTokens
                    ? [
                        BroadSupportEmailIdentifier(
                            label: "Token account ID",
                            value: "fixture-token-account"
                        )
                    ]
                    : [],
                supportLogData: Data("Fixture support log".utf8)
            )
        )
    }
}
