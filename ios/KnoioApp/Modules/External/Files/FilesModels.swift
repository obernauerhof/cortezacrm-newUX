import Foundation

/// Ein eingehängtes Laufwerk (Mount) hinter dem Datei-Gateway —
/// z. B. Google Drive, OneDrive/SharePoint, Nextcloud, Seafile, S3/SMB/WebDAV.
struct Mount: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let provider: MountProvider
}

/// Quelle eines Mounts (steuert v. a. Icon/Label in der UI).
enum MountProvider: String, Decodable, Sendable {
    case google
    case microsoft
    case nextcloud
    case seafile
    case s3
    case smb
    case webdav
    case other

    var systemImage: String {
        switch self {
        case .google:    return "g.circle.fill"
        case .microsoft: return "m.circle.fill"
        case .nextcloud: return "cloud.fill"
        case .seafile:   return "externaldrive.fill"
        case .s3:        return "cylinder.split.1x2.fill"
        case .smb:       return "network"
        case .webdav:    return "globe"
        case .other:     return "externaldrive"
        }
    }
}

/// Ein Eintrag innerhalb eines Mounts (Datei oder Ordner).
struct FileEntry: Identifiable, Hashable, Sendable {
    let mountId: String
    let name: String
    let path: String        // vollständiger Pfad inkl. Name
    let isDirectory: Bool
    let size: Int64?
    let modified: Date?

    var id: String { mountId + ":" + path }

    var sizeText: String? {
        guard let size, !isDirectory else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// Ziel beim Navigieren in einen Ordner (Wert für `navigationDestination`).
struct FilesLocation: Hashable, Sendable {
    let mountId: String
    let title: String
    let path: String
}

/// Provider-neutrale Datei-Datenquelle. Spricht das Knoio-Datei-Gateway an,
/// hinter dem die einzelnen Cloud-Mounts liegen. Siehe
/// `docs/ios-app/dateien-collaboration.md`.
protocol FilesBackend: Sendable {
    func mounts() async throws -> [Mount]
    func entries(in mountId: String, path: String) async throws -> [FileEntry]
    func downloadLink(mountId: String, path: String) async throws -> URL
}

/// Wählt das Backend abhängig von `AppConfig.Files.useMock`.
enum FilesBackendFactory {
    static func make(gateway: URL) -> FilesBackend {
        if AppConfig.Files.useMock {
            return MockFilesBackend.shared
        }
        return LiveFilesClient(gateway: gateway, token: AppConfig.Files.token)
    }
}
