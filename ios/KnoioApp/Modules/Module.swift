import Foundation

/// Ein für den Mandanten provisioniertes Modul — ein Eintrag aus dem
/// Manifest `GET /me/modules`. Siehe `docs/ios-app/architektur.md` §4.
struct Module: Identifiable, Decodable, Hashable {
    let id: String
    let type: ModuleType
    let title: String
    /// SF-Symbol-Name für das Tab-Icon.
    let icon: String
    let order: Int
    /// Ziel-URL für `web`- und `external`-Module.
    let url: URL?
    /// Anbieter bei `external`-Modulen.
    let provider: ExternalProvider?
    /// Matrix-Homeserver (nur Provider `.matrix`).
    let homeserver: URL?
    /// Informative Berechtigungen (UI-Hints — keine Autorisierung!).
    let permissions: [String]?
    /// Chat-Engine bei `provider == .matrix` — vom Admin pro Mandant wählbar.
    /// `native` = eigener Client, `rust-sdk` = matrix-rust-sdk (Element X).
    /// Fehlt das Feld, gilt `native`.
    let engine: ChatEngine?
}

/// Integrationsart eines Moduls. Bestimmt, wie es in der App gerendert wird.
enum ModuleType: String, Decodable {
    /// Native SwiftUI-Umsetzung gegen die REST-API.
    case native
    /// Eingebettete React-Oberfläche via WKWebView.
    case web
    /// Eigenständiger Drittdienst (SDK / WebView / Deeplink).
    case external
}

/// Drittanbieter/Art eines `external`-Moduls.
enum ExternalProvider: String, Decodable {
    /// Chat/Kanäle via Matrix.
    case matrix
    /// Provider-neutrales Dateimodul über das Gateway (mit eingehängten Clouds).
    case files
}

/// Antwort von `GET /me/modules`.
struct ModuleManifest: Decodable {
    let tenant: Tenant
    let modules: [Module]

    struct Tenant: Decodable, Hashable {
        let id: String
        let name: String
    }
}
