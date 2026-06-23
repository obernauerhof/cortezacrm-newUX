import SwiftUI

/// Rendert ein einzelnes Modul abhängig von seinem `ModuleType`.
struct ModuleHostView: View {
    let module: Module

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(module.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { AccountMenu() }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch module.type {
        case .native:
            NativeModuleView(module: module)
        case .web:
            if let url = module.url {
                WebModuleView(url: url).ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView("Keine URL konfiguriert",
                                       systemImage: "link.badge.plus")
            }
        case .external:
            ExternalModuleView(module: module)
        }
    }
}

/// Konto-Menü (Mandant + Logout), in jedem Modul erreichbar.
private struct AccountMenu: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var modules: ModuleService

    var body: some View {
        Menu {
            if !modules.tenantName.isEmpty {
                Text(modules.tenantName)
            }
            Button(role: .destructive, action: auth.logout) {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "person.crop.circle")
        }
    }
}
