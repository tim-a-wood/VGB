import SwiftUI
import SwiftData

@main
struct VGBApp: App {
    var body: some Scene {
        WindowGroup {
            BacklogListView()
        }
        .modelContainer(for: Game.self)
    }
}
