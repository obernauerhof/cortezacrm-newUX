# Knoio.ai iOS-App (Grundgerüst)

Native iOS-App (SwiftUI, **native-first**) für Knoio.ai. Die Navigation wird
**dynamisch aus dem Modul-Manifest des Mandanten** (`GET /me/modules`) aufgebaut
(Server-Driven UI). Konzept & Hintergrund: [`../docs/ios-app/architektur.md`](../docs/ios-app/architektur.md).

> **Status:** Grundgerüst / Phase 0. Startet dank Mock-Manifest **ohne Backend**.

## Voraussetzungen

- macOS mit **Xcode 15+** (iOS-Deployment-Target 17.0)
- [**XcodeGen**](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`) –
  das `.xcodeproj` wird generiert und ist bewusst **nicht** eingecheckt.

## Projekt generieren & starten

```bash
cd ios
xcodegen generate        # erzeugt KnoioApp.xcodeproj aus project.yml
open KnoioApp.xcodeproj  # in Xcode öffnen, Simulator wählen, ⌘R
```

Beim ersten Start sind `AppConfig.useMockAuth = true` und
`AppConfig.useMockManifest = true`: Der „Anmelden“-Button setzt ein Dummy-Token,
und es wird das Mock-Manifest (`MockData.swift`) geladen – Tab-Bar mit Dashboard
(native), CRM (web), Dateien (Nextcloud) und Chat (Matrix).

Gegen den **Mock-Server** ([`../api/`](../api/README.md)) testen: `useMockAuth = true`,
`useMockManifest = false`, `apiBaseURL = http://localhost:4010`.

## An die echte Umgebung anbinden

1. `AppConfig.useMockAuth = false` und `useMockManifest = false` setzen.
2. In `AppConfig` die echten Werte eintragen (`TODO(verify)`):
   - `apiBaseURL`
   - `OIDC.authorizationEndpoint`, `OIDC.tokenEndpoint`, `clientID`, `redirectURI`, `scopes`
3. Den OIDC-Redirect (`knoio://oauth/callback`) beim Identity-Provider als
   erlaubte Redirect-URI registrieren. Das URL-Schema `knoio` ist in
   `Resources/Info.plist` hinterlegt.
4. Sicherstellen, dass `GET /me/modules` das in `Module.swift`/Architektur §4
   beschriebene Schema liefert (oder den Decoder anpassen).

## Architektur (Kurzform)

```
KnoioApp/
├─ App/           App-Einstieg, RootView (Login ↔ Haupt-UI)
├─ Auth/          OIDC + PKCE (AuthService), Keychain (TokenStore), LoginView
├─ Networking/    APIClient (Bearer-Token automatisch)
├─ Modules/       Module-Modell, ModuleService (/me/modules), MockData
│  ├─ Native/     Native SwiftUI-Module (Dashboard als Beispiel)
│  ├─ Web/        WKWebView-Einbettung (Token-Bridge)
│  └─ External/   Nextcloud (SSO-Launch); Matrix/ = nativer Chat;
│                 Seafile/ = nativer Dateibrowser
├─ Navigation/    Dynamische TabBar + ModuleHostView (Routing nach Typ)
├─ Config/        AppConfig (Endpunkte, Feature-Flags)
└─ Resources/     Info.plist (URL-Schema)
```

### Modul-Typen

| Typ | Rendering | Datei |
|-----|-----------|-------|
| `native` | SwiftUI gegen REST-API | `Modules/Native/` |
| `web` | WKWebView (eure React-Module) | `Modules/Web/WebModuleView.swift` |
| `external` | Nextcloud per SSO-Launch; **Matrix** (Chat) und **Seafile** (Dateien) nativ | `Modules/External/` |

Matrix-Chat (`AppConfig.Matrix`) und Seafile-Dateibrowser (`AppConfig.Seafile`)
laufen mit `useMock = true` gegen In-Memory-Demodaten; für echte Server jeweils
`useMock = false` und `accessToken`/`token` setzen.

**Matrix-Engine pro Mandant:** Das Manifest-Feld `engine` der Chat-Module steuert,
welche Engine genutzt wird – `native` (eigener Client) oder `rust-sdk`
(matrix-rust-sdk / Element X). So kann ein Admin künftig pro Mandant umschalten.
Der `rust-sdk`-Pfad ist als Platzhalter angelegt (Einbindung siehe
`RustSDKMatrixClient.swift`).

## Nächste Schritte (Roadmap-Phasen)

- **Phase 1:** Echte `/me/modules`-Anbindung, `web`-Module per SSO-WebView.
- **Phase 2:** Drittdienste anbinden – Matrix-Chat nativ (✅ Grundgerüst),
  Nextcloud/Seafile-Dateien.
- **Phase 3:** Native Kernmodule ausbauen (Dashboard mit echten Daten), Push (APNs).
- **Phase 4:** Offline-Lesemodus, Feinschliff, Store-Reife.
