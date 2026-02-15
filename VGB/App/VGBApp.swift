import SwiftUI
import SwiftData
import WidgetKit

@MainActor
@main
struct VGBApp: App {
    let container: ModelContainer = {
        do {
            let c = try StoreConfiguration.sharedContainer()
            #if DEBUG
            print("[VGB App] Launched — using shared container")
            #endif
            return c
        } catch {
            fatalError("Failed to configure SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentRoot()
        }
        .modelContainer(container)
    }
}

/// Root view that has access to both `scenePhase` and `modelContext`,
/// allowing us to trigger background sync when the app comes to the foreground.
private struct ContentRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            BacklogListView()
                .tabItem {
                    Label("Game Catalog", systemImage: "books.vertical")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.pie")
                }
        }
        .onAppear {
            pushWidgetSummary(context: modelContext)
            WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await GameSyncService.shared.refreshStaleGames(in: modelContext)
                }
                pushWidgetSummary(context: modelContext)
                WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
            }
        }
    }
}

/// Pushes current backlog summary to App Group UserDefaults so the widget can display it.
private func pushWidgetSummary(context: ModelContext) {
    #if DEBUG
    print("[VGB App] pushWidgetSummary() called")
    #endif
    let descriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.priorityPosition)])
    guard let games = try? context.fetch(descriptor) else {
        #if DEBUG
        print("[VGB App] pushWidgetSummary() fetch failed")
        #endif
        return
    }
    let nextUp = games.first { $0.status == .backlog }
    #if DEBUG
    print("[VGB App] pushWidgetSummary() games.count=\(games.count) nextUp=\(nextUp?.title ?? "nil")")
    #endif
    WidgetSummaryStorage.write(
        nextUpTitle: nextUp?.title,
        nextUpPlatform: nextUp?.platform.isEmpty == false ? nextUp?.displayPlatform : nil,
        totalGames: games.count,
        completedGames: games.filter { $0.status == .completed }.count,
        playingCount: games.filter { $0.status == .playing }.count
    )
    #if DEBUG
    print("[VGB App] pushWidgetSummary() done, reloadTimelines next")
    #endif
}
