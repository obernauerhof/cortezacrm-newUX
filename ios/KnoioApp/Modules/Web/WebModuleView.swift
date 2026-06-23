import SwiftUI
import WebKit

/// Eingebettetes `web`-Modul (React-Oberfläche). Reicht für die initiale
/// Anfrage das OIDC-Access-Token als Bearer-Header durch (Token-Bridge),
/// damit kein zweiter Login nötig ist.
///
/// ⚠️ Härtung (siehe Architektur §8): In Produktion auf erlaubte Knoio-Origins
/// beschränken und die Navigationsrichtlinie über einen `WKNavigationDelegate`
/// durchsetzen.
struct WebModuleView: UIViewRepresentable {
    let url: URL
    @EnvironmentObject private var auth: AuthService

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Nur einmalig initial laden.
        guard webView.url == nil else { return }
        let target = url
        Task { @MainActor in
            var request = URLRequest(url: target)
            if let token = await auth.currentAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            webView.load(request)
        }
    }
}
