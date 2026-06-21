import SwiftUI

/// Haupt-UI: baut die Tab-Bar **dynamisch** aus dem Modul-Manifest auf.
/// Nichts ist hart codiert — ändert sich die Provisionierung, ändert sich
/// die Navigation beim nächsten Laden.
struct MainTabView: View {
    @EnvironmentObject private var modules: ModuleService

    var body: some View {
        Group {
            if modules.modules.isEmpty {
                loadingOrEmpty
            } else {
                TabView {
                    ForEach(modules.modules) { module in
                        ModuleHostView(module: module)
                            .tabItem { Label(module.title, systemImage: module.icon) }
                    }
                }
            }
        }
        .task { await modules.load() }
    }

    @ViewBuilder
    private var loadingOrEmpty: some View {
        if modules.isLoading {
            ProgressView("Module werden geladen…")
        } else if let error = modules.error {
            ContentUnavailableView("Module konnten nicht geladen werden",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text(error))
        } else {
            ContentUnavailableView("Keine Module provisioniert",
                                   systemImage: "square.dashed")
        }
    }
}
