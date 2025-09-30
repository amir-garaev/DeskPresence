import SwiftUI

@main
struct DeskPresenceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea(.container, edges: .top)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: AppConst.introWidth, height: AppConst.introHeight)
    }
}
