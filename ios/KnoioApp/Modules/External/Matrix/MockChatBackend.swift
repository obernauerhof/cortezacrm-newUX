import Foundation

/// In-Memory-Chat-Backend für die Entwicklung ohne Homeserver
/// (`AppConfig.Matrix.useMock == true`). Gesendete Nachrichten bleiben
/// für die Dauer der App-Sitzung erhalten (shared Instanz).
actor MockChatBackend: ChatBackend {
    static let shared = MockChatBackend()

    private var sent: [String: [MatrixMessage]] = [:]

    private let demoRooms = [
        MatrixRoom(id: "!team:demo", name: "Team Knoio"),
        MatrixRoom(id: "!support:demo", name: "Support"),
    ]

    private let demoMessages: [String: [MatrixMessage]] = [
        "!team:demo": [
            MatrixMessage(id: "$1", sender: "@anna:demo",
                          body: "Moin! Steht das Release für morgen?",
                          timestamp: Date().addingTimeInterval(-3600), isMine: false),
            MatrixMessage(id: "$2", sender: "@me:demo",
                          body: "Ja, alles grün ✅",
                          timestamp: Date().addingTimeInterval(-3000), isMine: true),
        ],
        "!support:demo": [
            MatrixMessage(id: "$3", sender: "@kunde:demo",
                          body: "Frage zur letzten Rechnung …",
                          timestamp: Date().addingTimeInterval(-7200), isMine: false),
        ],
    ]

    func rooms() async throws -> [MatrixRoom] { demoRooms }

    func messages(in roomId: String) async throws -> [MatrixMessage] {
        (demoMessages[roomId] ?? []) + (sent[roomId] ?? [])
    }

    func send(_ text: String, to roomId: String) async throws -> MatrixMessage {
        let message = MatrixMessage(id: UUID().uuidString, sender: "@me:demo",
                                    body: text, timestamp: Date(), isMine: true)
        sent[roomId, default: []].append(message)
        return message
    }
}
