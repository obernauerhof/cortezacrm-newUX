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

/// Wählt das Backend abhängig von `AppConfig.Matrix.useMock`.
enum ChatBackendFactory {
    static func make(homeserver: URL) -> ChatBackend {
        if AppConfig.Matrix.useMock {
            return MockChatBackend.shared
        }
        return LiveMatrixClient(homeserver: homeserver,
                                accessToken: AppConfig.Matrix.accessToken)
    }
}
