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

    /// Wenn `true`, läuft die App ohne Backend gegen ein lokales Mock-Manifest
    /// und einen Dummy-Login. Für die Anbindung an die echte Umgebung auf
    /// `false` setzen.
    static let useMockData = true
}
