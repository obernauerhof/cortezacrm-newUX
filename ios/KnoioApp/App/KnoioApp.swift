import SwiftUI

/// App-Einstiegspunkt. Komponiert die zentralen Services und reicht sie
/// als EnvironmentObjects in die View-Hierarchie.
@main
struct KnoioApp: App {
    @StateObject private var auth: AuthService
    @StateObject private var modules: ModuleService

    init() {
        let auth = AuthService()
        // Der APIClient bezieht das OIDC-Access-Token lazy vom AuthService.
        let api = APIClient(tokenProvider: { [auth] in await auth.currentAccessToken() })
        _auth = StateObject(wrappedValue: auth)
        _modules = StateObject(wrappedValue: ModuleService(api: api))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(modules)
        }
    }
}
