import Foundation
import AuthenticationServices
import CryptoKit

/// Verwaltet Authentifizierung via OIDC Authorization-Code-Flow + PKCE.
///
/// Der Login läuft über `ASWebAuthenticationSession` (Apple-konform, kein
/// eingebetteter Login-WebView). Tokens werden in der Keychain gehalten.
@MainActor
final class AuthService: NSObject, ObservableObject {
    enum State: Equatable {
        case unauthenticated
        case authenticating
        case authenticated
    }

    @Published private(set) var state: State = .unauthenticated
    @Published private(set) var errorMessage: String?

    private let tokenStore = TokenStore()
    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        if let tokens = tokenStore.load(), tokens.expiresAt > Date() {
            state = .authenticated
        }
    }

    /// Liefert ein gültiges Access-Token (erneuert es bei Bedarf via Refresh).
    func currentAccessToken() async -> String? {
        guard let tokens = tokenStore.load() else { return nil }
        if tokens.expiresAt > Date().addingTimeInterval(60) {
            return tokens.accessToken
        }
        return try? await refresh(using: tokens)?.accessToken
    }

    // MARK: - Login

    func login() {
        if AppConfig.useMockAuth {
            try? tokenStore.save(.init(accessToken: "mock-token",
                                       refreshToken: nil,
                                       expiresAt: .distantFuture))
            state = .authenticated
            return
        }

        state = .authenticating
        errorMessage = nil

        let verifier = Self.makeCodeVerifier()
        let challenge = Self.codeChallenge(for: verifier)
        let expectedState = UUID().uuidString

        var comps = URLComponents(url: AppConfig.OIDC.authorizationEndpoint,
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: AppConfig.OIDC.clientID),
            .init(name: "redirect_uri", value: AppConfig.OIDC.redirectURI),
            .init(name: "scope", value: AppConfig.OIDC.scopes.joined(separator: " ")),
            .init(name: "state", value: expectedState),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        let scheme = URL(string: AppConfig.OIDC.redirectURI)?.scheme
        let session = ASWebAuthenticationSession(url: comps.url!,
                                                 callbackURLScheme: scheme) { [weak self] callbackURL, error in
            guard let self else { return }
            Task { await self.handleCallback(callbackURL,
                                             error: error,
                                             expectedState: expectedState,
                                             verifier: verifier) }
        }
        session.presentationContextProvider = self
        webAuthSession = session
        session.start()
    }

    func logout() {
        tokenStore.clear()
        state = .unauthenticated
    }

    private func handleCallback(_ url: URL?, error: Error?,
                                expectedState: String, verifier: String) async {
        if let error {
            errorMessage = error.localizedDescription
            state = .unauthenticated
            return
        }
        guard let url,
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = comps.queryItems?.first(where: { $0.name == "code" })?.value,
              comps.queryItems?.first(where: { $0.name == "state" })?.value == expectedState
        else {
            errorMessage = "Ungültige Login-Antwort."
            state = .unauthenticated
            return
        }
        do {
            let tokens = try await exchangeCode(code, verifier: verifier)
            try tokenStore.save(tokens)
            state = .authenticated
        } catch {
            errorMessage = error.localizedDescription
            state = .unauthenticated
        }
    }

    // MARK: - Token-Endpoint

    private func exchangeCode(_ code: String, verifier: String) async throws -> TokenStore.Tokens {
        try await postToken([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": AppConfig.OIDC.redirectURI,
            "client_id": AppConfig.OIDC.clientID,
            "code_verifier": verifier,
        ])
    }

    private func refresh(using tokens: TokenStore.Tokens) async throws -> TokenStore.Tokens? {
        guard let refreshToken = tokens.refreshToken else {
            logout()
            return nil
        }
        let refreshed = try await postToken([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": AppConfig.OIDC.clientID,
        ])
        try tokenStore.save(refreshed)
        return refreshed
    }

    private func postToken(_ parameters: [String: String]) async throws -> TokenStore.Tokens {
        var request = URLRequest(url: AppConfig.OIDC.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { key, value in
                let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlFormValueAllowed) ?? value
                return "\(key)=\(encoded)"
            }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        return .init(accessToken: decoded.accessToken,
                     refreshToken: decoded.refreshToken,
                     expiresAt: Date().addingTimeInterval(TimeInterval(decoded.expiresIn ?? 3600)))
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }

    // MARK: - PKCE

    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
