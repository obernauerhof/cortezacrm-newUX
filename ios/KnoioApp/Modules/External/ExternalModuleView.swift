import SwiftUI

/// Einstieg für `external`-Module.
///
/// - `matrix` → nativer Chat (mandanten-/admin-wählbare Engine).
/// - `files`  → provider-neutraler Dateibrowser über das Gateway (mit den
///   eingehängten Clouds: Google, Microsoft, Nextcloud, Seafile …).
///
/// Siehe `docs/ios-app/dateien-collaboration.md`.
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
        case .files:
            FilesBrowserView(gateway: module.url ?? AppConfig.apiBaseURL)
        case .none:
            ExternalLaunchView(module: module)
        }
    }
}

/// Generischer SSO-Launch für externe Dienste ohne native Integration.
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
            Text("Externer Dienst.")
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
}
