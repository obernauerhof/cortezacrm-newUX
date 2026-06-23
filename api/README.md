# Knoio Mobile BFF – API-Contract & Mock-Server

Zentraler Endpunkt für die mobile App ist das **Modul-Manifest** `GET /me/modules`,
aus dem die App ihre Navigation dynamisch und mandantenabhängig aufbaut
(Server-Driven UI). Hintergrund: [`../docs/ios-app/architektur.md`](../docs/ios-app/architektur.md) §4.

## Inhalte

- [`openapi.yaml`](openapi.yaml) — formaler API-Contract (OpenAPI 3.1), inkl.
  Schemas `ModuleManifest`, `Module`, `ModuleType`, `ExternalProvider`, `Tenant`.
- [`mock-server/`](mock-server/) — abhängigkeitsfreier Node-Mock-Server, der
  `GET /me/modules` gemäß Contract ausliefert.

## Mock-Server starten

Benötigt nur Node.js ≥ 18 (keine npm-Installation nötig):

```bash
cd api/mock-server
node server.js          # oder: npm start
# → Knoio mock server läuft auf http://localhost:4010
```

Test:

```bash
curl http://localhost:4010/me/modules
curl http://localhost:4010/healthz
```

## Die iOS-App dagegen laufen lassen

In `ios/KnoioApp/Config/AppConfig.swift`:

```swift
static let useMockAuth     = true                              // Dummy-Login behalten
static let useMockManifest = false                             // echtes Fetch statt MockData
static let apiBaseURL      = URL(string: "http://localhost:4010")!
```

> Für `http://localhost` im Simulator ggf. eine ATS-Ausnahme in
> `Resources/Info.plist` ergänzen (`NSAllowsLocalNetworking`). Bei einem
> Gerätetest die IP des Mac statt `localhost` verwenden.

## Contract validieren / als Mock nutzen (optional)

Der Contract lässt sich auch direkt mit [Prism](https://github.com/stoplightio/prism)
mocken oder validieren:

```bash
npx @stoplight/prism-cli mock api/openapi.yaml   # mockt automatisch auf :4010
```
