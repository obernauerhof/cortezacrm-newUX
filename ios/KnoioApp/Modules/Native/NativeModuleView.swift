import SwiftUI

/// Einstiegspunkt für native (SwiftUI-)Module. Routet anhand der Modul-ID
/// auf den jeweiligen nativen Screen. Native-first: Kernflows werden hier
/// direkt gegen die REST-API umgesetzt.
struct NativeModuleView: View {
    let module: Module

    var body: some View {
        switch module.id {
        case "dashboard":
            DashboardView()
        default:
            // Platzhalter, bis das native Modul implementiert ist.
            ContentUnavailableView {
                Label(module.title, systemImage: module.icon)
            } description: {
                Text("Natives Modul „\(module.title)“ – Implementierung folgt.")
            }
        }
    }
}
