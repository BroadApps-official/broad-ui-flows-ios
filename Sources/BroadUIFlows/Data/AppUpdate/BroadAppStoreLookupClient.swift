import Foundation

/// The iTunes lookup API adapter. Invalid or unavailable listings yield no alert.
public struct BroadAppStoreLookupClient: BroadAppStoreLookupProtocol {
    public init() {}

    public func lookup(bundleID: String) async throws -> BroadAppStoreListing? {
        guard !bundleID.isEmpty else { return nil }
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [URLQueryItem(name: "bundleId", value: bundleID)]
        guard let url = components?.url else { return nil }
        let (data, response) = try await URLSession.shared.data(from: url)
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
