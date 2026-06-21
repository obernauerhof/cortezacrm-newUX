import Foundation

/// Schlanker REST-Client gegen die Knoio-API. Hängt automatisch das
/// OIDC-Access-Token als Bearer-Header an jede Anfrage.
actor APIClient {
    private let baseURL: URL
    private let tokenProvider: @Sendable () async -> String?
    private let session: URLSession

    init(baseURL: URL = AppConfig.apiBaseURL,
         tokenProvider: @escaping @Sendable () async -> String?,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.session = session
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path, method: "GET", body: nil)
    }

    func request<T: Decodable>(_ path: String, method: String, body: Data?) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = await tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige URL."
        case .invalidResponse: return "Ungültige Server-Antwort."
        case .httpStatus(let code): return "HTTP-Fehler \(code)."
        }
    }
}
