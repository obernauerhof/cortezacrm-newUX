# Dateien & Collaboration – Konzept (Modell B)

> **Status:** Entwurf / Diskussionsgrundlage · **Stand:** 2026-06-22
> Ergänzt [`architektur.md`](architektur.md) um den Datei- und Collaboration-Teil.

## 0. Getroffene Entscheidungen

- **Schale (GUI) = die Knoio-App** (Modell B), **nicht** die Nextcloud-UI.
- **Chat & Kanäle = Matrix/Element** (Spaces = Kanalgruppen).
- **Dateien = ein provider-neutrales Files-Modul** über eine **Mount-Gateway-Schicht**.
- **Fremde Clouds einhängen ist Pflicht:** Google Drive, Microsoft (OneDrive/
  SharePoint), Nextcloud — dazu Seafile sowie S3/SMB/WebDAV.
- **Collaboration Space** = feste Kopplung *Matrix-Space ⇄ Ordner/Library*.

## 1. Warum ein Mount-Gateway (und nicht „Nextcloud macht das")

| Ansatz | Google Drive | OneDrive/SharePoint | Nextcloud | Seafile | S3/SMB/WebDAV |
|---|---|---|---|---|---|
| **Nextcloud External Storage** | ❌ nicht mehr robust eingebaut | ⚠️ nur via Connector/Enterprise | – | ⚠️ via WebDAV | ✅ |
| **rclone-Gateway** | ✅ | ✅ | ✅ (WebDAV) | ✅ (WebDAV) | ✅ |

Da „Google **und** Microsoft einhängen" ein hartes Muss ist, scheidet „Nextcloud
allein" als Aggregator aus. **Empfehlung:** eine serverseitige **Mount-Gateway-
Schicht auf Basis von rclone** (läuft auf eurem Hetzner/Linux), die alle Quellen
**einheitlich** als WebDAV/S3 bereitstellt. Nextcloud/Seafile sind dann *eine*
Quelle von vielen — nicht die Schale.

## 2. Architektur

```
        ┌──────────────── Knoio-App (Schale, Modell B) ────────────────┐
        │  Dynamische Module aus /me/modules                           │
        │   ├─ Chat/Kanäle  → Matrix/Element                           │
        │   └─ Dateien      → Files-Modul (provider-neutral)           │
        └───────────────────────────┬──────────────────────────────────┘
                                     │  ein OIDC-Login (SSO)
                       ┌─────────────▼──────────────┐
                       │   Mount-Gateway (rclone)    │  ← serverseitig (Hetzner)
                       │   einheitlich: WebDAV / S3  │
                       └───┬───────┬───────┬─────┬───┘
              Google Drive │  MS    │ Next- │ Sea-│  S3 / SMB / WebDAV
                           │ OneDr. │ cloud │ file│
                           │ ShareP.│       │     │
```

**Auth-Modell (wichtig):**
- Die **App** authentifiziert sich nur **einmal** gegen Knoio per **OIDC**.
- Die **Pro-Anbieter-OAuth-Tokens** (Google, Microsoft …) liegen **serverseitig
  im Gateway** (verschlüsselt), **nie auf dem Gerät**. Der Admin/Nutzer verbindet
  ein Cloud-Konto einmalig über einen OAuth-Connect-Flow.
- Knoio-**RBAC** entscheidet, welcher Nutzer im Mandanten welche Mounts sieht;
  das Gateway erzwingt die Eingrenzung.

## 3. Mapping zu eurem Bild (SharePoint / OneDrive)

| Dein Begriff | Umsetzung |
|---|---|
| **SharePoint** (Team-Ablagen) | Mount auf SharePoint-Doc-Library **oder** Nextcloud Group Folder / Seafile geteilte Library |
| **OneDrive Business** (persönlich, Org) | Mount auf OneDrive for Business **oder** persönliche Nextcloud/Seafile-Ablage |
| **OneDrive personal** (eingehängt) | Mount auf privates OneDrive-Konto (rclone-Connector) |
| **Google** | Mount auf Google Drive / Shared Drives |
| **Nextcloud** | Mount via WebDAV |

Jeder Mount erscheint in der Files-UI als eigenes **„Laufwerk" (Root)**.

## 4. Datenmodell (Evolution des bestehenden `FilesBackend`)

Unser iOS-`FilesBackend` (heute Seafile-spezifisch: `libraries()`) wird
**provider-neutral** mit **mehreren Wurzeln (Mounts)**:

```
Mount   { id, name, provider, icon }          // ein eingehängtes Laufwerk
Entry   { mountId, path, name, isDir, size, mtime }

protocol FilesBackend {
    func mounts() async throws -> [Mount]                       // statt libraries()
    func entries(in mountId: String, path: String) -> [Entry]
    func downloadLink(mountId: String, path: String) -> URL
}
```

→ Der bestehende `SeafileBrowserView` wird zum generischen **FilesBrowser**:
Mount-Liste als oberste Ebene, darunter identische Ordner-Navigation.
Seafile/Nextcloud sind dann nur noch zwei von mehreren Mount-Providern.

## 5. Provisionierung / Admin (pro Mandant)

- Admin legt im Mandanten die **Mounts** an (Provider + OAuth-Connect für
  Google/Microsoft, WebDAV-Creds für Nextcloud/Seafile).
- Ausgeliefert an die App über das Manifest — entweder als Teil des Files-Moduls
  oder über einen eigenen Endpunkt `GET /me/mounts` (analog zu `/me/modules`).
- Konsistent mit dem bereits umgesetzten „admin-wählbar pro Mandant"-Muster
  (vgl. Chat-`engine`).

## 6. Collaboration Space

- **Space-Binding:** `{ matrixSpaceId, mountId, path }` — ein Projekt = ein
  Matrix-Space **plus** ein Ordner/Library.
- **UI:** ein Eintrag mit zwei Reitern — *Chat/Kanäle* (Matrix) und *Dateien*
  (der gebundene Ordner). So entsteht der Teams-/Slack-artige „Collaboration
  Space" unter einer Oberfläche.
- Auslieferung z. B. über `GET /me/spaces` → Liste der Space-Bindings.

## 7. Auswirkungen auf den bestehenden Code (iOS)

1. `FilesBackend`: `libraries()` → `mounts()`, Modell `SeafileLibrary` → `Mount`
   verallgemeinern; `SeafileEntry` → `Entry` mit `mountId`.
2. `SeafileBrowserView` → generischer `FilesBrowserView` (Mounts als Wurzeln).
3. `LiveSeafileClient` wird zu **einem** `GatewayFilesClient` (WebDAV/S3 gegen das
   rclone-Gateway); Seafile/Nextcloud/Google/MS sind serverseitige Mounts.
4. Neues `CollaborationSpace`-Modul, das Matrix-Room + Files-Ordner zusammen rendert.

## 8. Offene Punkte / `TODO(verify)`

- Gateway-Betrieb: rclone `serve` (WebDAV/S3) vs. fertige Lösung; Mandanten-
  Mandantentrennung (ein Gateway pro Tenant vs. Pfad-Scoping).
- OAuth-Connect-Flows für Google/Microsoft (Consent, Refresh, Token-Storage).
- Berechtigungsabbildung: Quell-ACLs (SharePoint/Drive) vs. Knoio-RBAC.
- Performance/Caching großer Verzeichnisse über das Gateway.
