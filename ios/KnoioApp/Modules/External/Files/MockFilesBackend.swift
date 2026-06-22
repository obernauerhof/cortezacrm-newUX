import Foundation

/// In-Memory-Datei-Backend für die Entwicklung ohne Gateway
/// (`AppConfig.Files.useMock == true`). Bildet mehrere eingehängte Clouds ab.
actor MockFilesBackend: FilesBackend {
    static let shared = MockFilesBackend()

    private let demoMounts = [
        Mount(id: "m-onedrive", name: "OneDrive Business", provider: .microsoft),
        Mount(id: "m-sharepoint", name: "SharePoint – Marketing", provider: .microsoft),
        Mount(id: "m-gdrive", name: "Google Drive", provider: .google),
        Mount(id: "m-nextcloud", name: "Nextcloud", provider: .nextcloud),
    ]

    func mounts() async throws -> [Mount] { demoMounts }

    func entries(in mountId: String, path: String) async throws -> [FileEntry] {
        switch (mountId, path) {
        case ("m-onedrive", "/"):
            return [
                dir(mountId, "Angebote", "/Angebote"),
                file(mountId, "Praesentation.pptx", "/Praesentation.pptx", size: 2_400_000),
            ]
        case ("m-onedrive", "/Angebote"):
            return [file(mountId, "Angebot-2026.docx", "/Angebote/Angebot-2026.docx", size: 58_000)]
        case ("m-sharepoint", "/"):
            return [
                dir(mountId, "Kampagnen", "/Kampagnen"),
                file(mountId, "Brandbook.pdf", "/Brandbook.pdf", size: 8_900_000),
            ]
        case ("m-gdrive", "/"):
            return [
                dir(mountId, "Geteilt mit mir", "/Geteilt mit mir"),
                file(mountId, "Notizen.gdoc", "/Notizen.gdoc", size: 0),
            ]
        case ("m-nextcloud", "/"):
            return [
                dir(mountId, "Projekte", "/Projekte"),
                file(mountId, "Readme.md", "/Readme.md", size: 3_100),
            ]
        default:
            return []
        }
    }

    func downloadLink(mountId: String, path: String) async throws -> URL {
        URL(string: "https://files.demo.knoio.ai/\(mountId)\(path)")!
    }

    private func dir(_ mountId: String, _ name: String, _ path: String) -> FileEntry {
        FileEntry(mountId: mountId, name: name, path: path, isDirectory: true,
                  size: nil, modified: Date().addingTimeInterval(-86_400))
    }

    private func file(_ mountId: String, _ name: String, _ path: String, size: Int64) -> FileEntry {
        FileEntry(mountId: mountId, name: name, path: path, isDirectory: false,
                  size: size, modified: Date().addingTimeInterval(-3_600))
    }
}
