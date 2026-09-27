import Foundation

/// The iTunes lookup API adapter. Invalid or unavailable listings yield no alert.
public struct BroadAppStoreLookupClient: BroadAppStoreLookupProtocol {
    public init() {}

    /// Looks the app up in the storefront of the device region first: the default
    /// US storefront has no listing for apps not sold there. Falls back to it.
    public func lookup(bundleID: String) async throws -> BroadAppStoreListing? {
        guard !bundleID.isEmpty else { return nil }
        if let country = Locale.current.region?.identifier.lowercased(),
           let listing = try await lookup(bundleID: bundleID, country: country) {
            return listing
        }
        return try await lookup(bundleID: bundleID, country: nil)
    }

    private func lookup(bundleID: String, country: String?) async throws -> BroadAppStoreListing? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [URLQueryItem(name: "bundleId", value: bundleID)]
            + (country.map { [URLQueryItem(name: "country", value: $0)] } ?? [])
        guard let url = components?.url else { return nil }
        // A cached answer can hide a fresh release.
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            return nil
        }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard let result = payload.results.first(where: { $0.bundleId == bundleID }),
              let version = BroadAppVersion(result.version),
              let listingURL = URL(string: result.trackViewUrl),
              listingURL.scheme?.lowercased() == "https",
              listingURL.host?.lowercased() == "apps.apple.com"
        else { return nil }
        return BroadAppStoreListing(version: version, url: listingURL)
    }

    private struct Payload: Decodable {
        let results: [Result]
    }

    private struct Result: Decodable {
        let bundleId: String
        let version: String
        let trackViewUrl: String
    }
}
