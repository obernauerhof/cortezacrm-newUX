# Knoio.ai iOS-App – Architektur- & Integrationskonzept

> **Status:** Entwurf / Diskussionsgrundlage
> **Stand:** 2026-06-21
>
> **Hinweis zum Repository-Stand:** Dieses Repository enthielt zum Zeitpunkt der
> Erstellung nur die `LICENSE`-Datei (kein Quellcode). Alle Bezüge zu konkreten
> Endpunkten, Modul-IDs und Pfaden sind daher als **Vorschlag** zu verstehen und
> müssen gegen den echten Knoio-/Corteza-Code verifiziert und angepasst werden.
> Stellen, die noch zu verifizieren sind, sind mit **`TODO(verify)`** markiert.

---

## 1. Ziel

Eine native iOS-App für Knoio.ai, die einem Nutzer **genau die Module zeigt, die
für seinen Mandanten provisioniert wurden** – dynamisch, ohne App-Store-Update bei
Änderung der Provisionierung. Die App vereint:

- **Eigene Module + CRM-Kern** (eurer React-Standard)
- **Drittdienste**: Nextcloud, Synapse (Matrix), Seafile

…hinter **einem** Login (Single Sign-On), sodass es sich wie *eine* App anfühlt
statt wie eine Linksammlung.

---

## 2. Leitprinzip: Server-Driven UI

Die App hat **keine fest verdrahtete Modul-Liste**. Stattdessen:

1. Nutzer meldet sich **einmal** an (OIDC, siehe §5).
2. App ruft das **Modul-Manifest** ab (`GET /me/modules`, §4).
3. App baut **Navigation/Tab-Bar dynamisch** aus dem Manifest.
4. Ändert sich die Provisionierung serverseitig, ändert sich die App beim
   nächsten Start/Refresh – ohne Release.

```
   Login (OIDC)  ──►  GET /me/modules  ──►  Dynamische Navigation
                                              ├─ web      → WKWebView
                                              ├─ native   → SwiftUI-Screen
                                              └─ external → SDK / Deeplink
```

> **Sicherheitsgrundsatz:** Das Manifest steuert nur **Sichtbarkeit**. Die echte
> Autorisierung passiert **serverseitig pro Request** (RBAC). Die App darf der
> Liste nie blind vertrauen.

---

## 3. Modul-Klassen

Wir unterscheiden drei Integrationsarten, weil sie technisch grundverschieden sind:

| Typ | Was | iOS-Integration | Beispiel |
|-----|-----|-----------------|----------|
| `web` | Eure React-Module + CRM-Kern | `WKWebView` (Token-Injektion via OIDC) | CRM, Reporting, eigene Apps |
| `native` | Kernflows mit höchstem UX-Anspruch | SwiftUI gegen die REST-API | Dashboard, Schnellerfassung |
| `external` | Eigenständige Drittprodukte | Natives SDK / WebView / Deeplink | Nextcloud, Synapse, Seafile |

**Pragmatische Empfehlung für Phase 1:** *WebView-first* für die `web`-Module
(maximale Wiederverwendung des React-Codes), native Hülle drumherum, und nur 1–2
Kernflows nativ. Drittdienste über deren SDKs bzw. WebView.

---

## 4. Modul-Manifest (`GET /me/modules`)

Zentraler Endpunkt, der pro **angemeldetem Nutzer + Mandant** die provisionierten,
sichtbaren Module liefert. Vorschlag für das Schema:

```jsonc
{
  "tenant": { "id": "acme", "name": "ACME GmbH" },
  "modules": [
    {
      "id": "crm",
      "type": "web",                    // web | native | external
      "title": "CRM",
      "icon": "person.2.fill",          // SF Symbol o. Asset-Key
      "order": 10,
      "url": "https://acme.knoio.ai/crm",
      "permissions": ["crm.read"],      // rein informativ für UI-Hints
      "badge": "count:crm.open"         // optional, dynamischer Badge-Key
    },
    {
      "id": "files",
      "type": "external",
      "provider": "nextcloud",          // nextcloud | seafile | matrix
      "title": "Dateien",
      "icon": "folder.fill",
      "order": 20,
      "url": "https://cloud.acme.knoio.ai",
      "auth": "oidc"                    // sso über gemeinsamen IdP
    },
    {
      "id": "chat",
      "type": "external",
      "provider": "matrix",
      "title": "Chat",
      "icon": "message.fill",
      "order": 30,
      "homeserver": "https://matrix.acme.knoio.ai",
      "auth": "oidc"
    }
  ]
}
```

**Ableitung aus Corteza (Vorschlag):** Die Liste lässt sich aus den vorhandenen
Konzepten ableiten – *Namespaces/Applications* + *Rollen/RBAC* pro Mandant.
Falls kein passender Endpunkt existiert, ist ein schlanker BFF-Endpunkt
`GET /me/modules` der richtige Ort. **`TODO(verify)`**: Existierenden Endpunkt
für Applications/Entitlements prüfen.

---

## 5. Authentifizierung & SSO (der kritische Teil)

Damit ein Login für **alle** Module + Drittdienste reicht, braucht es einen
**gemeinsamen OIDC/OAuth2 Identity-Provider**. Corteza kann selbst als OIDC-IdP
fungieren; Nextcloud, Synapse und Seafile unterstützen alle OIDC-Login.

```
                     ┌──────────────────┐
   iOS-App  ──login──►   OIDC-IdP        │  (Corteza / Keycloak)
       │              └──────────────────┘
       │ access_token + id_token (PKCE, ASWebAuthenticationSession)
       │
       ├─► Knoio-API        (Bearer-Token)
       ├─► Nextcloud        (OIDC-Login / Login-Flow v2)
       ├─► Synapse/Matrix   (OIDC, MSC3861)
       └─► Seafile          (OIDC / Token-Exchange)
```

**iOS-Vorgaben:**
- **Authorization Code Flow + PKCE** über `ASWebAuthenticationSession`
  (kein eingebetteter WebView für den Login – Apple-Anforderung & Sicherheit).
- Tokens **ausschließlich in der Keychain** (kein UserDefaults).
- Token-Refresh transparent; bei `web`-Modulen Token an den WebView durchreichen
  (z. B. via geschützter Cookie-/Header-Bridge), damit kein zweiter Login nötig ist.

**`TODO(verify)`**: Aktuellen IdP/Auth-Mechanismus von Knoio bestätigen
(Corteza-eigener OIDC vs. externer Keycloak o. Ä.).

---

## 6. Drittdienst-Integration im Detail

Diese Dienste sind **eigenständige Produkte mit eigenen Protokollen** – sie werden
*neben* euren Modulen integriert, nicht *als* React-Modul.

| Dienst | Protokoll/API | Empfohlene iOS-Integration | Auth |
|--------|---------------|----------------------------|------|
| **Nextcloud** | WebDAV + OCS REST | SDK/WebView; alternativ Deeplink in offizielle App | OIDC / Login-Flow v2 |
| **Synapse** (Matrix-Homeserver) | Matrix C-S API | `matrix-rust-sdk` (empfohlen) oder `MatrixSDK` (Swift); alternativ Element-Embed | OIDC (MSC3861) |
| **Seafile** | Seafile REST API + WebDAV | Seafile iOS-Komponenten / WebView | Token / OIDC |

**Integrationsstufen je Dienst (von schnell zu nativ):**
1. **Deeplink/Link-out** in die jeweilige offizielle App – schnellster Start.
2. **WebView** der jeweiligen Weboberfläche mit SSO.
3. **Natives SDK** – beste UX, höchster Aufwand (lohnt v. a. für Chat/Matrix und
   Datei-Sync mit Offline).

**Empfehlung:** Phase 1 = SSO-WebView/Deeplink; Chat (Matrix) und Dateien
(Nextcloud *oder* Seafile – §11) später nativ ausbauen.

---

## 7. App-Architektur (Native Shell + WebView)

```
┌──────────────────────────── iOS-App (SwiftUI) ───────────────────────────┐
│  AppCoordinator                                                           │
│   ├─ AuthService        (OIDC, PKCE, Keychain, Refresh)                   │
│   ├─ ModuleService      (GET /me/modules, Caching, Refresh-on-foreground) │
│   ├─ Dynamische TabBar  (aus Manifest gerendert)                          │
│   │     ├─ WebModuleView      (WKWebView + Token-Bridge)                  │
│   │     ├─ NativeModuleView   (SwiftUI gegen REST-API)                    │
│   │     └─ ExternalModuleView (SDK / Deeplink / WebView)                  │
│   ├─ PushService        (APNs – optional, Phase 2)                        │
│   └─ DeeplinkRouter     (universelle Links / knoio:// Schema)             │
└───────────────────────────────────────────────────────────────────────────┘
```

**Sprache/Tooling:** Swift + SwiftUI, Swift Concurrency (`async/await`),
keine schwergewichtigen Cross-Plattform-Frameworks im Kern (die WebViews
übernehmen die Web-Wiederverwendung).

---

## 8. Sicherheit

- **Serverseitige Autorisierung (RBAC)** bei jedem Request – Manifest ≠ Berechtigung.
- **Keychain** für Tokens; kein Token im Klartext-Log.
- **App Transport Security** (TLS, Pinning für die Knoio-Domains optional prüfen).
- **WebView-Härtung:** nur erlaubte Origins, kein generisches `window.open`,
  Token-Bridge auf konkrete Hosts beschränken.
- **Logout** invalidiert Tokens zentral (IdP-Session) und lokal (Keychain + WebView-Cookies).

---

## 9. Offline & Push (Phase 2)

- **Push (APNs):** Benachrichtigungen aus CRM-Events und Matrix-Chat.
- **Offline:** zunächst nur native Kernflows (Lesecache); WebView-Module bleiben online.

---

## 10. Umsetzungs-Roadmap

| Phase | Inhalt | Ergebnis |
|-------|--------|----------|
| **0 – Fundament** | OIDC-Login (PKCE), Keychain, `GET /me/modules` (ggf. BFF-Stub) | Login + leere dynamische TabBar |
| **1 – Web-Module** | `web`-Module als SSO-WebView; dynamische Navigation | Alle React-Module nutzbar |
| **2 – Drittdienste** | Nextcloud/Seafile + Matrix via SSO-WebView/Deeplink | Dateien & Chat erreichbar |
| **3 – Nativ-Ausbau** | Dashboard nativ, Matrix nativ (SDK), Push | Premium-UX in Kernbereichen |
| **4 – Offline/Polish** | Caching, Offline-Lesemodus, Feinschliff | Store-Reife |

---

## 11. Offene Punkte / Entscheidungen

1. **Nextcloud *oder* Seafile für Dateien?** Beide parallel anzubieten ist für die
   Nutzer verwirrend und doppelter Pflegeaufwand. Empfehlung: **einen** Datei-Dienst
   als Standard, den anderen nur falls mandantenspezifisch provisioniert.
2. **WebView-first vs. nativ-first** als Grundausrichtung (Empfehlung: WebView-first
   in Phase 1).
3. **`TODO(verify)`**: Echten IdP/OIDC-Setup, Applications-/Entitlement-Endpunkt und
   Domainstruktur (`*.knoio.ai`) am Quellcode bestätigen.

---

## 12. Nächster Schritt

Sobald der Knoio-/Corteza-Quellcode verfügbar ist:
- konkreten Auth-/OIDC-Flow und Applications-Endpunkt im Code lokalisieren,
- `GET /me/modules` entweder anbinden oder als BFF ergänzen,
- App-Grundgerüst (Phase 0) als eigenes iOS-Projekt aufsetzen.
