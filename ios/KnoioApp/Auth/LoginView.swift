import SwiftUI

/// Login-Bildschirm. Startet den OIDC-Flow im AuthService.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Knoio.ai")
                .font(.largeTitle.bold())
            Text("Melde dich an, um deine Module zu sehen.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()

            if auth.state == .authenticating {
                ProgressView()
            } else {
                Button(action: auth.login) {
                    Text("Anmelden")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(32)
    }
}

#Preview {
    LoginView().environmentObject(AuthService())
}
