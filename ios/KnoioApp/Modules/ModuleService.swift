import Foundation

/// Lädt und hält das Modul-Manifest des angemeldeten Mandanten.
/// Quelle der dynamischen Navigation (Server-Driven UI).
@MainActor
final class ModuleService: ObservableObject {
    @Published private(set) var manifest: ModuleManifest?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// Provisionierte Module, sortiert nach `order`.
    var modules: [Module] {
        (manifest?.modules ?? []).sorted { $0.order < $1.order }
    }

    var tenantName: String {
        manifest?.tenant.name ?? ""
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if AppConfig.useMockManifest {
                manifest = MockData.manifest
            } else {
                manifest = try await api.get("/me/modules")
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
