import SwiftUI

/// Einstieg für `external`-Module (Nextcloud, Seafile, Synapse/Matrix).
///
/// Matrix wird **nativ** (Matrix Client-Server-API) dargestellt; Nextcloud und
/// Seafile starten per SSO-Launch in den jeweiligen Dienst. Der native Ausbau
/// von Dateien (WebDAV/OCS bzw. Seafile-API) dockt hier an — siehe
/// Architektur §6.
struct ExternalModuleView: View {
    let module: Module

    var body: some View {
        switch module.provider {
        case .matrix:
            if let homeserver = module.homeserver ?? module.url {
                MatrixChatView(homeserver: homeserver, engine: module.engine ?? .native)
            } else {
                ContentUnavailableView("Kein Homeserver konfiguriert",
                                       systemImage: "message.badge.waveform")
            }
        case .seafile:
            if let server = module.url ?? module.homeserver {
                SeafileBrowserView(server: server)
            } else {
                ContentUnavailableView("Kein Server konfiguriert",
                                       systemImage: "externaldrive.badge.xmark")
            }
        default:
            ExternalLaunchView(module: module)
        }
    }
}

/// SSO-Launch-Oberfläche für Drittdienste ohne native Integration.
private struct ExternalLaunchView: View {
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

            if let url = module.url ?? module.homeserver {
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

    private var providerDescription: String {
        switch module.provider {
        case .nextcloud:
            return "Dateien & Zusammenarbeit (Nextcloud).\nNativer Client-Ausbau via WebDAV/OCS folgt."
        case .seafile, .matrix, .none:
            return "Externer Dienst."
        }
    }
}
