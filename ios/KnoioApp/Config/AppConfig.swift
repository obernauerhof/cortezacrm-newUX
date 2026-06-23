import Foundation

/// Zentrale App-Konfiguration.
///
/// ⚠️ Die Werte sind Platzhalter und müssen gegen die echte Knoio-/Corteza-
/// Infrastruktur verifiziert werden — siehe `docs/ios-app/architektur.md`
/// (TODO(verify): IdP, Endpunkte, Domains).
enum AppConfig {
    /// Basis-URL der Knoio-REST-API (Quelle des Modul-Manifests `GET /me/modules`).
    static let apiBaseURL = URL(string: "https://api.knoio.ai")!

    /// Konfiguration für den nativen Matrix-Chat.
    enum Matrix {
        /// Native Chat-Daten aus dem In-Memory-Mock statt echtem Homeserver.
        static let useMock = true

        /// Access-Token für die Matrix Client-Server-API. Bei OIDC/MSC3861
        /// das SSO-Token. `TODO(verify)` – echten Bezug ergänzen.
        static let accessToken = ""
    }

    /// Konfiguration für das provider-neutrale Dateimodul (Gateway).
    enum Files {
        /// Native Datei-Daten aus dem In-Memory-Mock statt echtem Gateway.
        static let useMock = true

        /// Bearer-Token für das Knoio-Datei-Gateway (BFF). Bei SSO das
        /// OIDC-Token. `TODO(verify)`.
        static let token = ""
    }

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
