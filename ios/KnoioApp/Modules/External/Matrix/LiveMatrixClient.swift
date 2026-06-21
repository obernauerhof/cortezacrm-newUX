import Foundation

/// Nativer Matrix-Client gegen die Client-Server-REST-API (v3).
/// Bewusst ohne Dritt-SDK gehalten — voll unter eigener Kontrolle und
/// ohne Binär-Abhängigkeit. Authentifizierung via Bearer-Access-Token
/// (bei OIDC/MSC3861 das SSO-Token).
actor LiveMatrixClient: ChatBackend {
    private let homeserver: URL
    private let accessToken: String
    private let session: URLSession
    private var cachedUserID: String?

    init(homeserver: URL, accessToken: String, session: URLSession = .shared) {
        self.homeserver = homeserver
        self.accessToken = accessToken
        self.session = session
    }

    func rooms() async throws -> [MatrixRoom] {
        let joined: JoinedRoomsResponse = try await get("/_matrix/client/v3/joined_rooms")
        var result: [MatrixRoom] = []
        for id in joined.joinedRooms {
            let name = (try? await roomName(id)) ?? id
            result.append(MatrixRoom(id: id, name: name))
        }
        return result
    }

    func messages(in roomId: String) async throws -> [MatrixMessage] {
        let me = try await userID()
        let path = "/_matrix/client/v3/rooms/\(encode(roomId))/messages"
        let resp: MessagesResponse = try await get(path, query: [
            .init(name: "dir", value: "b"),
            .init(name: "limit", value: "30"),
        ])
        let messages = resp.chunk
            .filter { $0.type == "m.room.message" && $0.content?.body != nil }
            .map { event in
                MatrixMessage(id: event.eventId,
                              sender: event.sender,
                              body: event.content?.body ?? "",
                              timestamp: Date(timeIntervalSince1970: Double(event.originServerTS) / 1000),
                              isMine: event.sender == me)
            }
        // /messages?dir=b liefert neueste zuerst → für die Anzeige umkehren.
        return Array(messages.reversed())
    }

    func send(_ text: String, to roomId: String) async throws -> MatrixMessage {
        let me = try await userID()
        let txnId = UUID().uuidString
        let path = "/_matrix/client/v3/rooms/\(encode(roomId))/send/m.room.message/\(txnId)"
        let body = try JSONSerialization.data(withJSONObject: ["msgtype": "m.text", "body": text])
        let resp: SendResponse = try await put(path, body: body)
        return MatrixMessage(id: resp.eventId, sender: me, body: text,
                             timestamp: Date(), isMine: true)
    }

    // MARK: - Helpers

    private func roomName(_ roomId: String) async throws -> String {
        let resp: RoomNameResponse = try await get(
            "/_matrix/client/v3/rooms/\(encode(roomId))/state/m.room.name/")
        return resp.name
    }

    private func userID() async throws -> String {
        if let cachedUserID { return cachedUserID }
        let resp: WhoAmIResponse = try await get("/_matrix/client/v3/account/whoami")
        cachedUserID = resp.userId
        return resp.userId
    }

    private func encode(_ component: String) -> String {
        component.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? component
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try await request(path, method: "GET", query: query, body: nil)
    }

    private func put<T: Decodable>(_ path: String, body: Data) async throws -> T {
        try await request(path, method: "PUT", query: [], body: body)
    }

    private func request<T: Decodable>(_ path: String, method: String,
                                       query: [URLQueryItem], body: Data?) async throws -> T {
        guard var comps = URLComponents(url: homeserver, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        comps.percentEncodedPath = path
        if !query.isEmpty { comps.queryItems = query }
        guard let url = comps.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Response-Modelle

    private struct JoinedRoomsResponse: Decodable {
        let joinedRooms: [String]
        enum CodingKeys: String, CodingKey { case joinedRooms = "joined_rooms" }
    }

    private struct RoomNameResponse: Decodable { let name: String }

    private struct WhoAmIResponse: Decodable {
        let userId: String
        enum CodingKeys: String, CodingKey { case userId = "user_id" }
    }

    private struct SendResponse: Decodable {
        let eventId: String
        enum CodingKeys: String, CodingKey { case eventId = "event_id" }
    }

    private struct MessagesResponse: Decodable { let chunk: [Event] }

    private struct Event: Decodable {
        let type: String
        let sender: String
        let eventId: String
        let originServerTS: Int64
        let content: Content?

        enum CodingKeys: String, CodingKey {
            case type, sender, content
            case eventId = "event_id"
            case originServerTS = "origin_server_ts"
        }

        struct Content: Decodable { let body: String? }
    }
}
