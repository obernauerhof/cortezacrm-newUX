import Foundation

/// Nativer Seafile-Client gegen die Web-API v2. Authentifizierung via
/// Token-Auth (Header `Authorization: Token <token>`); bei SSO entsprechend
/// beziehen. Ohne Dritt-SDK — voll unter eigener Kontrolle.
actor LiveSeafileClient: FilesBackend {
    private let server: URL
    private let token: String
    private let session: URLSession

    init(server: URL, token: String, session: URLSession = .shared) {
        self.server = server
        self.token = token
        self.session = session
    }

    func libraries() async throws -> [SeafileLibrary] {
        let repos: [RepoDTO] = try await get("/api2/repos/")
        // Seafile kann denselben Repo mehrfach liefern (eigene/geteilte) → deduplizieren.
        var seen = Set<String>()
        return repos.compactMap { repo in
            guard seen.insert(repo.id).inserted else { return nil }
            return SeafileLibrary(id: repo.id, name: repo.name)
        }
    }

    func entries(in repoId: String, path: String) async throws -> [SeafileEntry] {
        let dtos: [EntryDTO] = try await get("/api2/repos/\(repoId)/dir/",
                                             query: [.init(name: "p", value: path)])
        return dtos.map { dto in
            let isDir = dto.type == "dir"
            let childPath = (path == "/" ? "" : path) + "/" + dto.name
            return SeafileEntry(
                repoId: repoId,
                name: dto.name,
                path: childPath,
                isDirectory: isDir,
                size: dto.size,
                modified: dto.mtime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            )
        }
    }

    func downloadLink(repoId: String, path: String) async throws -> URL {
        // Seafile liefert hier als Body einen JSON-String mit der Download-URL.
        let link: String = try await get("/api2/repos/\(repoId)/file/",
                                         query: [.init(name: "p", value: path),
                                                 .init(name: "reuse", value: "1")])
        guard let url = URL(string: link) else { throw APIError.invalidResponse }
        return url
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var comps = URLComponents(url: server, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        comps.path = path
        if !query.isEmpty { comps.queryItems = query }
        guard let url = comps.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - DTOs

    private struct RepoDTO: Decodable {
        let id: String
        let name: String
    }

    private struct EntryDTO: Decodable {
        let type: String      // "file" | "dir"
        let name: String
        let size: Int64?
        let mtime: Int64?
    }
}
