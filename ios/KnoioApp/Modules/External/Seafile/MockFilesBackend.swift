import Foundation

/// In-Memory-Datei-Backend für die Entwicklung ohne Seafile-Server
/// (`AppConfig.Seafile.useMock == true`).
actor MockFilesBackend: FilesBackend {
    static let shared = MockFilesBackend()

    private let demoLibraries = [
        SeafileLibrary(id: "lib-tresor", name: "Mein Tresor"),
        SeafileLibrary(id: "lib-projekte", name: "Projekte"),
    ]

    func libraries() async throws -> [SeafileLibrary] { demoLibraries }

    func entries(in repoId: String, path: String) async throws -> [SeafileEntry] {
        switch (repoId, path) {
        case ("lib-tresor", "/"):
            return [
                dir(repoId, "Dokumente", "/Dokumente"),
                file(repoId, "Angebot.pdf", "/Angebot.pdf", size: 248_000),
                file(repoId, "Notizen.txt", "/Notizen.txt", size: 1_200),
            ]
        case ("lib-tresor", "/Dokumente"):
            return [
                file(repoId, "Vertrag.docx", "/Dokumente/Vertrag.docx", size: 56_320),
            ]
        case ("lib-projekte", "/"):
            return [
                dir(repoId, "Knoio", "/Knoio"),
                file(repoId, "Roadmap.md", "/Roadmap.md", size: 4_096),
            ]
        default:
            return []
        }
    }

    func downloadLink(repoId: String, path: String) async throws -> URL {
        URL(string: "https://seafile.demo.knoio.ai/mock\(path)")!
    }

    private func dir(_ repoId: String, _ name: String, _ path: String) -> SeafileEntry {
        SeafileEntry(repoId: repoId, name: name, path: path, isDirectory: true,
                     size: nil, modified: Date().addingTimeInterval(-86_400))
    }

    private func file(_ repoId: String, _ name: String, _ path: String, size: Int64) -> SeafileEntry {
        SeafileEntry(repoId: repoId, name: name, path: path, isDirectory: false,
                     size: size, modified: Date().addingTimeInterval(-3_600))
    }
}
