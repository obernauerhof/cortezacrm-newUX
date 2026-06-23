import SwiftUI

/// Wurzel-View: schaltet zwischen Login und Haupt-UI je nach Auth-Status.
struct RootView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        switch auth.state {
        case .unauthenticated, .authenticating:
            LoginView()
        case .authenticated:
            MainTabView()
        }
    }
}
