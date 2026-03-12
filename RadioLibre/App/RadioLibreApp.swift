import SwiftUI

@main
struct RadioLibreApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task { await ServerDiscoveryService.shared.resolveIfNeeded() }
        }
    }
}
