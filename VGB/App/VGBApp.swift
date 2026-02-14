import SwiftUI
import SwiftData

@main
struct VGBApp: App {
    @StateObject private var syncService = GameSyncService.shared

    var body: some Scene {
        WindowGroup {
            ContentRoot()
                .environmentObject(syncService)
        }
        .modelContainer(for: Game.self)
    }
}

/// Root view that has access to both `scenePhase` and `modelContext`,
/// allowing us to trigger background sync when the app comes to the foreground.
private struct ContentRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: GameSyncService

    var body: some View {
        BacklogListView()
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await syncService.refreshStaleGames(in: modelContext)
                    }
                }
            }
    }
}
