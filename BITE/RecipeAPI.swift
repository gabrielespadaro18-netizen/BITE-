import Foundation

/// No Airtable personal access token ever ships in the app.
/// Set BITE_API_URL in Info.plist to your deployed read-only proxy URL.
enum RecipeAPI {
    private static var endpoint: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "BITE_API_URL") as? String,
              let url = URL(string: raw), url.scheme == "https",
              !raw.contains("YOUR_WORKER") else { return nil }
        return url
    }

    static var isConfigured: Bool { endpoint != nil }

    static func fetch() async throws -> [Recipe] {
        guard let url = endpoint else { throw APIError.notConfigured }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else { throw APIError.invalidResponse }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return payload.recipes
    }

    private struct Payload: Decodable { let recipes: [Recipe] }
    private enum APIError: LocalizedError {
        case notConfigured, invalidResponse
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Airtable proxy not configured"
            case .invalidResponse: return "Airtable request failed"
            }
        }
    }
}
