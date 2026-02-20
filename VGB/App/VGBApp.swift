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
    @AppStorage("VGB.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    /// Splash stays visible until graphics are preloaded (cover images + minimum display time).
    @State private var isSplashComplete = false
    /// Games that were unreleased in Wishlist and are now released after refresh — prompt to move to Backlog.
    @State private var gamesReleasedFromWishlist: [Game] = []

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if isSplashComplete {
                    mainTabs
                } else {
                    SplashView()
                }
            } else {
                OnboardingView(onComplete: { hasCompletedOnboarding = true })
            }
        }
        .onAppear {
            guard hasCompletedOnboarding else { return }
            if ProcessInfo.processInfo.arguments.contains("-SeedDemoData") {
                DemoData.seed(into: modelContext)
            }
            runSplashAndPreload()
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            guard completed else { return }
            if ProcessInfo.processInfo.arguments.contains("-SeedDemoData") {
                DemoData.seed(into: modelContext)
            }
            runSplashAndPreload()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard hasCompletedOnboarding else { return }
            if newPhase == .active {
                Task {
                    let released = await GameSyncService.shared.refreshStaleGames(in: modelContext)
                    if !released.isEmpty {
                        gamesReleasedFromWishlist = released
                    }
                    pushWidgetSummary(context: modelContext)
                    WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
                }
            }
        }
        .confirmationDialog("Games Released", isPresented: Binding(
            get: { !gamesReleasedFromWishlist.isEmpty },
            set: { if !$0 { gamesReleasedFromWishlist = [] } }
        )) {
            Button("Move to Backlog") {
                for game in gamesReleasedFromWishlist {
                    game.status = .backlog
                    game.updatedAt = Date()
                }
                gamesReleasedFromWishlist = []
                pushWidgetSummary(context: modelContext)
                WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
            }
            Button("Keep in Wishlist", role: .cancel) {
                gamesReleasedFromWishlist = []
            }
        } message: {
            let count = gamesReleasedFromWishlist.count
            let names = gamesReleasedFromWishlist.prefix(3).map(\.title).joined(separator: ", ")
            let suffix = count > 3 ? " and \(count - 3) more" : ""
            Text("\(count) game\(count == 1 ? "" : "s") in your wishlist \(count == 1 ? "has" : "have") been released: \(names)\(suffix). Move \(count == 1 ? "it" : "them") to Backlog?")
        }
    }

    /// Shows splash while prefetching cover images and refreshing game data, then transitions to main content.
    private func runSplashAndPreload() {
        let descriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.priorityPosition)])
        let games = (try? modelContext.fetch(descriptor)) ?? []
        ImagePrefetcher.prefetchCoverImages(for: games)

        Task {
            let released = await GameSyncService.shared.refreshStaleGames(in: modelContext)
            if !released.isEmpty {
                gamesReleasedFromWishlist = released
            }
        }

        let hasCoversToPrefetch = games.contains { $0.coverImageURL != nil }
        let minimumSplashTime: TimeInterval = hasCoversToPrefetch ? 0.4 : 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumSplashTime) {
            withAnimation(.easeOut(duration: 0.25)) {
                isSplashComplete = true
            }
            pushWidgetSummary(context: modelContext)
            WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
        }
    }

    private enum AppTab: Int { case catalog = 0, rankings = 1, stats = 2 }

    @State private var selectedTab: AppTab = {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-ScreenshotTab"), idx + 1 < args.count,
           let raw = Int(args[idx + 1]), raw >= 0, raw <= 2,
           let tab = AppTab(rawValue: raw) {
            return tab
        }
        return .catalog
    }()

    private var mainTabs: some View {
        VStack(spacing: 0) {
            CheckpointHeader()
            TabView(selection: Binding(
                get: { selectedTab },
                set: { selectedTab = $0 }
            )) {
                BacklogListView()
                    .tabItem {
                        Label("Game Catalog", systemImage: "books.vertical")
                    }
                    .tag(AppTab.catalog)
                RankingsView()
                    .tabItem {
                        Label("Rankings", systemImage: "list.number")
                    }
                    .tag(AppTab.rankings)
                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.pie")
                    }
                    .tag(AppTab.stats)
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
    let summary = WidgetSummaryBuilder.make(from: games)
    #if DEBUG
    print("[VGB App] pushWidgetSummary() games.count=\(summary.totalGames) nextUp=\(summary.nextUpTitle ?? "nil") playingFirst=\(summary.playingFirstTitle ?? "nil")")
    #endif
    WidgetSummaryStorage.write(summary)
    #if DEBUG
    print("[VGB App] pushWidgetSummary() done, reloadTimelines next")
    #endif
}
