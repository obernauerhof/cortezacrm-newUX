import Foundation

/// Lokales Beispiel-Manifest für die Entwicklung ohne Backend
/// (`AppConfig.useMockManifest == true`). Bildet alle drei Modul-Typen ab.
enum MockData {
    static let manifest = ModuleManifest(
        tenant: .init(id: "demo", name: "Demo GmbH"),
        modules: [
            Module(id: "dashboard", type: .native, title: "Dashboard",
                   icon: "square.grid.2x2.fill", order: 10,
                   url: nil, provider: nil, homeserver: nil,
                   permissions: nil, engine: nil),
            Module(id: "crm", type: .web, title: "CRM",
                   icon: "person.2.fill", order: 20,
                   url: URL(string: "https://demo.knoio.ai/crm"),
                   provider: nil, homeserver: nil,
                   permissions: ["crm.read"], engine: nil),
            Module(id: "files", type: .external, title: "Dateien",
                   icon: "folder.fill", order: 30,
                   url: URL(string: "https://seafile.demo.knoio.ai"),
                   provider: .seafile, homeserver: nil,
                   permissions: nil, engine: nil),
            Module(id: "chat", type: .external, title: "Chat",
                   icon: "message.fill", order: 40,
                   url: nil, provider: .matrix,
                   homeserver: URL(string: "https://matrix.demo.knoio.ai"),
                   permissions: nil, engine: .native),
        ]
    )
}
