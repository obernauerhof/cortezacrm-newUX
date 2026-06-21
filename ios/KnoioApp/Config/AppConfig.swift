import Foundation

/// Zentrale App-Konfiguration.
///
/// ⚠️ Die Werte sind Platzhalter und müssen gegen die echte Knoio-/Corteza-
/// Infrastruktur verifiziert werden — siehe `docs/ios-app/architektur.md`
/// (TODO(verify): IdP, Endpunkte, Domains).
enum AppConfig {
    /// Basis-URL der Knoio-REST-API (Quelle des Modul-Manifests `GET /me/modules`).
    static let apiBaseURL = URL(string: "https://api.knoio.ai")!

    /// OIDC-Konfiguration des gemeinsamen Identity-Providers (SSO).
    enum OIDC {
        static let authorizationEndpoint = URL(string: "https://id.knoio.ai/oauth2/authorize")!
        static let tokenEndpoint = URL(string: "https://id.knoio.ai/oauth2/token")!
        static let clientID = "knoio-ios"
        static let redirectURI = "knoio://oauth/callback"
        static let scopes = ["openid", "profile", "email", "offline_access"]
    }

    /// Dummy-Login statt echtem OIDC-Flow (Entwicklung ohne IdP).
    static let useMockAuth = true

    /// Lokales Mock-Manifest (`MockData`) statt Fetch von `apiBaseURL`
    /// (Entwicklung ohne Backend).
    ///
    /// Tipp: Gegen den Mock-Server testen → `useMockAuth = true`,
    /// `useMockManifest = false`, `apiBaseURL = http://localhost:4010`
    /// (siehe `api/README.md`).
    static let useMockManifest = true
}
