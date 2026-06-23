import SwiftUI

// MARK: - Mount-Liste (oberste Ebene)

/// Provider-neutraler Dateibrowser: eingehängte Clouds (Mounts) → Ordner →
/// Datei. Wird innerhalb des `NavigationStack` von `ModuleHostView` dargestellt.
struct FilesBrowserView: View {
    let gateway: URL
    @StateObject private var model: MountsModel

    init(gateway: URL) {
        self.gateway = gateway
        _model = StateObject(wrappedValue: MountsModel(gateway: gateway))
    }

    var body: some View {
        List(model.mounts) { mount in
            NavigationLink(value: FilesLocation(mountId: mount.id, title: mount.name, path: "/")) {
                Label(mount.name, systemImage: mount.provider.systemImage)
            }
        }
        .listStyle(.plain)
        .overlay {
            if model.mounts.isEmpty {
                if model.isLoading {
                    ProgressView()
                } else if let error = model.error {
                    ContentUnavailableView("Dateien nicht verfügbar",
                                           systemImage: "externaldrive.badge.xmark",
                                           description: Text(error))
                } else {
                    ContentUnavailableView("Keine Laufwerke eingehängt",
                                           systemImage: "externaldrive")
                }
            }
        }
        // Ein Ziel für die gesamte Tiefe des Stacks (Mount-Wurzel und Unterordner).
        .navigationDestination(for: FilesLocation.self) { location in
            FilesDirectoryView(gateway: gateway, location: location)
        }
        .task { await model.load() }
    }
}

@MainActor
final class MountsModel: ObservableObject {
    @Published private(set) var mounts: [Mount] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let backend: FilesBackend

    init(gateway: URL) {
        backend = FilesBackendFactory.make(gateway: gateway)
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            mounts = try await backend.mounts()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Ordneransicht

struct FilesDirectoryView: View {
    let gateway: URL
    @StateObject private var model: FilesDirectoryModel
    @Environment(\.openURL) private var openURL

    init(gateway: URL, location: FilesLocation) {
        self.gateway = gateway
        _model = StateObject(wrappedValue: FilesDirectoryModel(gateway: gateway, location: location))
    }

    var body: some View {
        List(model.entries) { entry in
            if entry.isDirectory {
                NavigationLink(value: FilesLocation(mountId: entry.mountId,
                                                    title: entry.name,
                                                    path: entry.path)) {
                    Label(entry.name, systemImage: "folder.fill")
                }
            } else {
                Button {
                    Task {
                        if let url = await model.downloadLink(for: entry) { openURL(url) }
                    }
                } label: {
                    HStack {
                        Label(entry.name, systemImage: "doc")
                        Spacer()
                        if let size = entry.sizeText {
                            Text(size).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.primary)
            }
        }
        .listStyle(.plain)
        .navigationTitle(model.location.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if model.entries.isEmpty {
                if model.isLoading {
                    ProgressView()
                } else if let error = model.error {
                    ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle",
                                           description: Text(error))
                } else {
                    ContentUnavailableView("Leerer Ordner", systemImage: "folder")
                }
            }
        }
        .task { await model.load() }
    }
}

@MainActor
final class FilesDirectoryModel: ObservableObject {
    @Published private(set) var entries: [FileEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    let location: FilesLocation
    private let backend: FilesBackend

    init(gateway: URL, location: FilesLocation) {
        self.location = location
        backend = FilesBackendFactory.make(gateway: gateway)
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            entries = try await backend.entries(in: location.mountId, path: location.path)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func downloadLink(for entry: FileEntry) async -> URL? {
        do {
            return try await backend.downloadLink(mountId: entry.mountId, path: entry.path)
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
