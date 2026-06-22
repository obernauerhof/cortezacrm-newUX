import Foundation

/// Ein Matrix-Raum (joined room).
struct MatrixRoom: Identifiable, Hashable, Sendable {
    let id: String      // Matrix-Room-ID, z. B. "!abc:homeserver"
    let name: String
}

/// Eine Chat-Nachricht (m.room.message / m.text).
struct MatrixMessage: Identifiable, Hashable, Sendable {
    let id: String      // Matrix-Event-ID
    let sender: String  // Matrix-User-ID, z. B. "@anna:homeserver"
    let body: String
    let timestamp: Date
    let isMine: Bool
}

/// Abstraktion über die Chat-Datenquelle (echter Homeserver vs. Mock).
protocol ChatBackend: Sendable {
    func rooms() async throws -> [MatrixRoom]
    func messages(in roomId: String) async throws -> [MatrixMessage]
    func send(_ text: String, to roomId: String) async throws -> MatrixMessage
}

/// Vom Admin pro Mandant wählbare Chat-Engine (aus dem Modul-Manifest).
enum ChatEngine: String, Decodable, Sendable {
    /// Eigener nativer Client gegen die Matrix-C-S-API.
    case native
    /// matrix-rust-sdk — dieselbe Engine wie Element X.
    case rustSdk = "rust-sdk"
}

/// Fehler des Chat-Layers.
enum ChatError: LocalizedError {
    case engineNotWired(String)

    var errorDescription: String? {
        switch self {
        case .engineNotWired(let message): return message
        }
    }
}

/// Wählt das Backend abhängig von Mock-Schalter und (admin-/mandantengewählter)
/// Engine.
enum ChatBackendFactory {
    static func make(homeserver: URL, engine: ChatEngine) -> ChatBackend {
        if AppConfig.Matrix.useMock {
            return MockChatBackend.shared
        }
        switch engine {
        case .native:
            return LiveMatrixClient(homeserver: homeserver,
                                    accessToken: AppConfig.Matrix.accessToken)
        case .rustSdk:
            return RustSDKMatrixClient(homeserver: homeserver,
                                       accessToken: AppConfig.Matrix.accessToken)
        }
    }
}
