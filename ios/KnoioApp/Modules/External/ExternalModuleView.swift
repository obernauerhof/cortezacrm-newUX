import SwiftUI

/// Einstieg für `external`-Module (Nextcloud, Seafile, Synapse/Matrix).
///
/// Grundgerüst-Stufe: SSO-Launch in den jeweiligen Dienst. Der native Ausbau
/// (Nextcloud via WebDAV/OCS, Seafile via REST, Matrix via matrix-rust-sdk)
/// dockt hier an — siehe Architektur §6.
struct ExternalModuleView: View {
    let module: Module
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: module.icon)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(module.title)
                .font(.title2.bold())
            Text(providerDescription)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let url = launchURL {
                Button {
                    openURL(url)
                } label: {
                    Label("Öffnen", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            Spacer()
        }
        .padding(32)
    }

    private var launchURL: URL? {
        module.url ?? module.homeserver
    }

    private var providerDescription: String {
        switch module.provider {
        case .nextcloud:
            return "Dateien & Zusammenarbeit (Nextcloud).\nNativer Client-Ausbau via WebDAV/OCS folgt."
        case .seafile:
            return "Dateisynchronisation (Seafile).\nNativer Client-Ausbau via Seafile-API folgt."
        case .matrix:
            return "Chat (Matrix/Synapse).\nNativer Ausbau via matrix-rust-sdk folgt."
        case .none:
            return "Externer Dienst."
        }
    }
}
