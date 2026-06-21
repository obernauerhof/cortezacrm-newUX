import Foundation

/// Eine Seafile-Bibliothek (Library/Repo).
struct SeafileLibrary: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
}

/// Ein Eintrag innerhalb einer Bibliothek (Datei oder Ordner).
struct SeafileEntry: Identifiable, Hashable, Sendable {
    let repoId: String
    let name: String
    let path: String        // vollständiger Pfad inkl. Name, z. B. "/Dokumente/Vertrag.pdf"
    let isDirectory: Bool
    let size: Int64?
    let modified: Date?

    var id: String { repoId + ":" + path }

    var sizeText: String? {
        guard let size, !isDirectory else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// Ziel beim Navigieren in einen Ordner (Wert für `navigationDestination`).
struct SeafileLocation: Hashable, Sendable {
    let repoId: String
    let title: String
    let path: String
}

/// Abstraktion über die Datei-Datenquelle (echter Seafile-Server vs. Mock).
protocol FilesBackend: Sendable {
    func libraries() async throws -> [SeafileLibrary]
    func entries(in repoId: String, path: String) async throws -> [SeafileEntry]
    func downloadLink(repoId: String, path: String) async throws -> URL
}

/// Wählt das Backend abhängig von `AppConfig.Seafile.useMock`.
enum FilesBackendFactory {
    static func make(server: URL) -> FilesBackend {
        if AppConfig.Seafile.useMock {
            return MockFilesBackend.shared
        }
        return LiveSeafileClient(server: server, token: AppConfig.Seafile.token)
    }
}
