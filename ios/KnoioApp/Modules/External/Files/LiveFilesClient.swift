import Foundation

/// Live-Client gegen das Knoio-Datei-Gateway (BFF). Provider-neutral: die App
/// kennt nur Mounts und Pfade; das Einhängen einzelner Clouds (Google,
/// Microsoft, Nextcloud, Seafile …) und deren Pro-Anbieter-OAuth passiert
/// serverseitig im Gateway. Authentifizierung hier via Bearer (OIDC/SSO).
///
/// Contract: siehe `api/openapi.yaml` (`/me/mounts`).
actor LiveFilesClient: FilesBackend {
    private let gateway: URL
    private let token: String
    private let session: URLSession

    init(gateway: URL, token: String, session: URLSession = .shared) {
        self.gateway = gateway
        self.token = token
        self.session = session
    }

    func mounts() async throws -> [Mount] {
        let dtos: [MountDTO] = try await get("/me/mounts")
        return dtos.map { Mount(id: $0.id, name: $0.name, provider: $0.provider) }
    }

    func entries(in mountId: String, path: String) async throws -> [FileEntry] {
        let dtos: [EntryDTO] = try await get("/me/mounts/\(encode(mountId))/entries",
                                             query: [.init(name: "path", value: path)])
        return dtos.map { dto in
            let childPath = (path == "/" ? "" : path) + "/" + dto.name
            return FileEntry(
                mountId: mountId,
                name: dto.name,
                path: childPath,
                isDirectory: dto.type == "dir",
                size: dto.size,
                modified: dto.mtime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            )
        }
    }

    func downloadLink(mountId: String, path: String) async throws -> URL {
        let dto: DownloadDTO = try await get("/me/mounts/\(encode(mountId))/download",
                                             query: [.init(name: "path", value: path)])
        guard let url = URL(string: dto.url) else { throw APIError.invalidResponse }
        return url
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var comps = URLComponents(url: gateway, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        comps.path = path
        if !query.isEmpty { comps.queryItems = query }
        guard let url = comps.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func encode(_ component: String) -> String {
        component.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? component
    }

    // MARK: - DTOs

    private struct MountDTO: Decodable {
        let id: String
        let name: String
        let provider: MountProvider
    }

    private struct EntryDTO: Decodable {
        let type: String      // "file" | "dir"
        let name: String
        let size: Int64?
        let mtime: Int64?
    }

    private struct DownloadDTO: Decodable {
        let url: String
    }
}
