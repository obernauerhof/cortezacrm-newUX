import SwiftUI

/// Beispielhaftes natives Kernmodul. In der echten App liest es seine Daten
/// über den `APIClient` aus der Knoio-API; hier zeigt es statische Beispiel-
/// werte als Grundgerüst.
struct DashboardView: View {
    var body: some View {
        List {
            Section("Übersicht") {
                StatRow(title: "Offene Aufgaben", value: "12", icon: "checklist")
                StatRow(title: "Neue Nachrichten", value: "4", icon: "envelope.badge")
                StatRow(title: "Termine heute", value: "3", icon: "calendar")
            }
            Section("Schnellzugriff") {
                Label("Kontakt anlegen", systemImage: "person.badge.plus")
                Label("Notiz erfassen", systemImage: "square.and.pencil")
            }
        }
    }
}

private struct StatRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(.tint)
        }
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
