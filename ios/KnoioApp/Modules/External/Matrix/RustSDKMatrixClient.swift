import Foundation

/// Matrix-Backend auf Basis der **matrix-rust-sdk** — dieselbe Engine wie
/// Element X iOS. Wird gewählt, wenn das Modul-Manifest `engine: "rust-sdk"`
/// liefert (vom Admin pro Mandant einstellbar).
///
/// ──────────────────────────────────────────────────────────────────────────
/// EINBINDUNG (auf dem Mac gegen die echte SDK iterieren):
///
///   1. SPM-Paket in `ios/project.yml` ergänzen:
///        packages:
///          MatrixRustSDK:
///            url: https://github.com/matrix-org/matrix-rust-sdk-swift
///            from: "<version>"
///      und unter `targets.KnoioApp.dependencies`:
///            - package: MatrixRustSDK
///
///   2. `import MatrixRustSDK`
///
///   3. Client aufbauen und Session herstellen:
///        let client = try await ClientBuilder()
///            .homeserverUrl(url: homeserver.absoluteString)
///            .build()
///        // Login via OIDC/SSO (gemeinsamer IdP) bzw. restoreSession(...)
///
///   4. Auf die ChatBackend-Methoden abbilden:
///        - rooms()    → RoomListService / roomList()
///        - messages() → Timeline des Raums (paginieren)
///        - send()     → timeline.send(msg:)
///
/// Bis das SDK eingebunden ist, bleibt dies ein bewusst schlanker Platzhalter,
/// der den Auswahlmechanismus erfüllt, ohne die Binär-Abhängigkeit (und damit
/// die CI) einzuführen. Der Fehler wird in der UI sichtbar gemacht.
/// ──────────────────────────────────────────────────────────────────────────
actor RustSDKMatrixClient: ChatBackend {
    private let homeserver: URL
    private let accessToken: String

    init(homeserver: URL, accessToken: String) {
        self.homeserver = homeserver
        self.accessToken = accessToken
    }

    func rooms() async throws -> [MatrixRoom] { throw notWired }
    func messages(in roomId: String) async throws -> [MatrixMessage] { throw notWired }
    func send(_ text: String, to roomId: String) async throws -> MatrixMessage { throw notWired }

    private var notWired: ChatError {
        .engineNotWired("matrix-rust-sdk (Element X) ist noch nicht eingebunden. "
            + "Einbindungsschritte siehe Kommentar in RustSDKMatrixClient.swift.")
    }
}
