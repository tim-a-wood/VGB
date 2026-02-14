@preconcurrency import WidgetKit
import SwiftUI
import SwiftData
import os

private let logger = Logger(subsystem: "com.timwood.vgb.widget", category: "Widget")

/// Holds a non-Sendable completion so it can be passed into a @MainActor Task without data race warning.
private final class SnapshotCompletionHolder: @unchecked Sendable {
    let completion: (VGBWidgetEntry) -> Void
    init(_ completion: @escaping (VGBWidgetEntry) -> Void) { self.completion = completion }
}

// MARK: - Timeline Provider

struct VGBTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> VGBWidgetEntry {
        VGBWidgetEntry(
            date: Date(),
            nextUpTitle: "Elden Ring",
            nextUpPlatform: "PS5",
            totalGames: 12,
            completedGames: 5,
            playingCount: 2
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VGBWidgetEntry) -> Void) {
        logger.info("getSnapshot() called")
        let holder = SnapshotCompletionHolder(completion)
        Task { @MainActor in
            let entry = fetchEntry()
            logger.info("getSnapshot() returning entry totalGames=\(entry.totalGames)")
            holder.completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<VGBWidgetEntry>) -> Void) {
        logger.info("getTimeline() called")
        Task { @MainActor in
            let entry = fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            logger.info("getTimeline() returning timeline with entry totalGames=\(entry.totalGames)")
            completion(timeline)
        }
    }

    @MainActor
    private func fetchEntry() -> VGBWidgetEntry {
        logger.info("fetchEntry() called")
        // Prefer App Group UserDefaults (written by the app)
        if let summary = WidgetSummaryStorage.read() {
            logger.info("fetchEntry() using UserDefaults summary — total=\(summary.totalGames) nextUp=\(summary.nextUpTitle ?? "nil")")
            return VGBWidgetEntry(
                date: Date(),
                nextUpTitle: summary.nextUpTitle,
                nextUpPlatform: summary.nextUpPlatform,
                totalGames: summary.totalGames,
                completedGames: summary.completedGames,
                playingCount: summary.playingCount
            )
        }

        logger.info("fetchEntry() no UserDefaults summary, trying SwiftData")
        let container: ModelContainer
        do {
            container = try StoreConfiguration.sharedContainer()
        } catch {
            logger.error("fetchEntry() SwiftData failed: \(error.localizedDescription) — returning empty entry")
            return VGBWidgetEntry(date: Date(), nextUpTitle: nil, nextUpPlatform: nil, totalGames: 0, completedGames: 0, playingCount: 0)
        }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.priorityPosition)])
        guard let games = try? context.fetch(descriptor) else {
            logger.error("fetchEntry() SwiftData fetch failed — returning empty entry")
            return VGBWidgetEntry(date: Date(), nextUpTitle: nil, nextUpPlatform: nil, totalGames: 0, completedGames: 0, playingCount: 0)
        }

        let nextUp = games.first { $0.status == .backlog }
        let entry = VGBWidgetEntry(
            date: Date(),
            nextUpTitle: nextUp?.title,
            nextUpPlatform: nextUp?.platform,
            totalGames: games.count,
            completedGames: games.filter { $0.status == .completed }.count,
            playingCount: games.filter { $0.status == .playing }.count
        )
        logger.info("fetchEntry() using SwiftData — total=\(entry.totalGames) nextUp=\(entry.nextUpTitle ?? "nil")")
        return entry
    }
}

// MARK: - Timeline Entry

struct VGBWidgetEntry: TimelineEntry {
    let date: Date
    let nextUpTitle: String?
    let nextUpPlatform: String?
    let totalGames: Int
    let completedGames: Int
    let playingCount: Int
}

// MARK: - Widget View

struct VGBWidgetEntryView: View {
    var entry: VGBWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .font(.caption)
                    .foregroundStyle(.tint)
                Text("VGB")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tint)
            }

            if let title = entry.nextUpTitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    if let platform = entry.nextUpPlatform, !platform.isEmpty {
                        Text(platform)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No games in backlog")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Label("\(entry.completedGames)", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Label("\(entry.playingCount)", systemImage: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: next up
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .font(.caption)
                        .foregroundStyle(.tint)
                    Text("VGB")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                }

                if let title = entry.nextUpTitle {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Up")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(title)
                            .font(.headline)
                            .lineLimit(2)
                        if let platform = entry.nextUpPlatform, !platform.isEmpty {
                            Text(platform)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Add games to your backlog!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Spacer()

            // Right: stats
            VStack(alignment: .trailing, spacing: 8) {
                Spacer()
                StatRow(icon: "gamecontroller", label: "Total", value: entry.totalGames, color: .primary)
                StatRow(icon: "play.fill", label: "Playing", value: entry.playingCount, color: .blue)
                StatRow(icon: "checkmark.circle.fill", label: "Done", value: entry.completedGames, color: .green)
                Spacer()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Widget Configuration

struct VGBWidget: Widget {
    let kind: String = "VGBWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VGBTimelineProvider()) { entry in
            VGBWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Game Backlog")
        .description("See your next game and quick stats.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct VGBWidgetBundle: WidgetBundle {
    var body: some Widget {
        VGBWidget()
    }
}

#Preview(as: .systemSmall) {
    VGBWidget()
} timeline: {
    VGBWidgetEntry(date: .now, nextUpTitle: "Elden Ring", nextUpPlatform: "PS5", totalGames: 12, completedGames: 5, playingCount: 2)
}

#Preview(as: .systemMedium) {
    VGBWidget()
} timeline: {
    VGBWidgetEntry(date: .now, nextUpTitle: "Zelda: Tears of the Kingdom", nextUpPlatform: "Switch", totalGames: 24, completedGames: 8, playingCount: 3)
}
