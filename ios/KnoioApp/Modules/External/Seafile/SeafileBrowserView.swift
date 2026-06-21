import SwiftUI

// MARK: - Bibliotheksliste

/// Nativer Seafile-Dateibrowser: Bibliotheken → Ordner → Datei. Wird innerhalb
/// des `NavigationStack` von `ModuleHostView` dargestellt.
struct SeafileBrowserView: View {
    let server: URL
    @StateObject private var model: SeafileLibrariesModel

    init(server: URL) {
        self.server = server
        _model = StateObject(wrappedValue: SeafileLibrariesModel(server: server))
    }

    var body: some View {
        List(model.libraries) { library in
            NavigationLink(value: SeafileLocation(repoId: library.id, title: library.name, path: "/")) {
                Label(library.name, systemImage: "externaldrive.fill")
            }
        }
        .listStyle(.plain)
        .overlay {
            if model.libraries.isEmpty {
                if model.isLoading {
                    ProgressView()
                } else if let error = model.error {
                    ContentUnavailableView("Dateien nicht verfügbar",
                                           systemImage: "externaldrive.badge.xmark",
                                           description: Text(error))
                } else {
                    ContentUnavailableView("Keine Bibliotheken", systemImage: "externaldrive")
                }
            }
        }
        // Ein Ziel für die gesamte Tiefe des Stacks (Bibliothek und Unterordner).
        .navigationDestination(for: SeafileLocation.self) { location in
            SeafileDirectoryView(server: server, location: location)
        }
        .task { await model.load() }
    }
}

@MainActor
final class SeafileLibrariesModel: ObservableObject {
    @Published private(set) var libraries: [SeafileLibrary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let backend: FilesBackend

    init(server: URL) {
        backend = FilesBackendFactory.make(server: server)
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            libraries = try await backend.libraries()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Ordneransicht

struct SeafileDirectoryView: View {
    let server: URL
    @StateObject private var model: SeafileDirectoryModel
    @Environment(\.openURL) private var openURL

    init(server: URL, location: SeafileLocation) {
        self.server = server
        _model = StateObject(wrappedValue: SeafileDirectoryModel(server: server, location: location))
    }

    var body: some View {
        List(model.entries) { entry in
            if entry.isDirectory {
                NavigationLink(value: SeafileLocation(repoId: entry.repoId,
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
final class SeafileDirectoryModel: ObservableObject {
    @Published private(set) var entries: [SeafileEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    let location: SeafileLocation
    private let backend: FilesBackend

    init(server: URL, location: SeafileLocation) {
        self.location = location
        backend = FilesBackendFactory.make(server: server)
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            entries = try await backend.entries(in: location.repoId, path: location.path)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func downloadLink(for entry: SeafileEntry) async -> URL? {
        do {
            return try await backend.downloadLink(repoId: entry.repoId, path: entry.path)
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
