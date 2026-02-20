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
            playingCount: 2,
            playingFirstTitle: "Zelda: TOTK",
            playingFirstPlatform: "Switch",
            radarGenreCounts: [1, 3, 2, 5, 1, 2]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VGBWidgetEntry) -> Void) {
        logger.debug("getSnapshot() called")
        let holder = SnapshotCompletionHolder(completion)
        Task { @MainActor in
            let entry = fetchEntry()
            logger.debug("getSnapshot() returning entry totalGames=\(entry.totalGames)")
            holder.completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<VGBWidgetEntry>) -> Void) {
        logger.debug("getTimeline() called")
        Task { @MainActor in
            let entry = fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            logger.debug("getTimeline() returning timeline with entry totalGames=\(entry.totalGames)")
            completion(timeline)
        }
    }

    @MainActor
    private func fetchEntry() -> VGBWidgetEntry {
        logger.debug("fetchEntry() called")
        // Prefer App Group UserDefaults (written by the app)
        if let summary = WidgetSummaryStorage.read() {
            logger.debug("fetchEntry() using UserDefaults summary — total=\(summary.totalGames) nextUp=\(summary.nextUpTitle ?? "nil")")
            return VGBWidgetEntry(
                date: Date(),
                nextUpTitle: summary.nextUpTitle,
                nextUpPlatform: summary.nextUpPlatform,
                totalGames: summary.totalGames,
                completedGames: summary.completedGames,
                playingCount: summary.playingCount,
                playingFirstTitle: summary.playingFirstTitle,
                playingFirstPlatform: summary.playingFirstPlatform,
                radarGenreCounts: summary.radarGenreCounts
            )
        }

        logger.debug("fetchEntry() no UserDefaults summary, trying SwiftData")
        let container: ModelContainer
        do {
            container = try StoreConfiguration.sharedContainer()
        } catch {
            logger.error("fetchEntry() SwiftData failed: \(error.localizedDescription) — returning empty entry")
            return VGBWidgetEntry(date: Date(), nextUpTitle: nil, nextUpPlatform: nil, totalGames: 0, completedGames: 0, playingCount: 0, playingFirstTitle: nil, playingFirstPlatform: nil, radarGenreCounts: [])
        }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.priorityPosition)])
        guard let games = try? context.fetch(descriptor) else {
            logger.error("fetchEntry() SwiftData fetch failed — returning empty entry")
            return VGBWidgetEntry(date: Date(), nextUpTitle: nil, nextUpPlatform: nil, totalGames: 0, completedGames: 0, playingCount: 0, playingFirstTitle: nil, playingFirstPlatform: nil, radarGenreCounts: [])
        }

        let nextUp = games.first { $0.status == .backlog }
        let playing = games.filter { $0.status == .playing }.sorted { $0.priorityPosition < $1.priorityPosition }
        let playingFirst = playing.first
        let genreStrings = games.compactMap(\.genre).filter { !$0.isEmpty }
        let radarData = RadarGenreCategories.completedCountsByCategory(from: genreStrings)
        let radarCounts = radarData.map(\.value)
        let entry = VGBWidgetEntry(
            date: Date(),
            nextUpTitle: nextUp?.title,
            nextUpPlatform: nextUp?.platform.isEmpty == false ? nextUp?.displayPlatform : nil,
            totalGames: games.count,
            completedGames: games.filter { $0.status == .completed }.count,
            playingCount: playing.count,
            playingFirstTitle: playingFirst?.title,
            playingFirstPlatform: playingFirst?.platform.isEmpty == false ? playingFirst?.displayPlatform : nil,
            radarGenreCounts: radarCounts
        )
        logger.debug("fetchEntry() using SwiftData — total=\(entry.totalGames) nextUp=\(entry.nextUpTitle ?? "nil")")
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
    let playingFirstTitle: String?
    let playingFirstPlatform: String?
    /// Six genre category counts for the radar chart.
    let radarGenreCounts: [Double]
}

// MARK: - Widget View

/// Sizes tuned for systemSmall (~158pt) and systemMedium (~338×158pt).
private enum WidgetLayout {
    static let paddingSmall: CGFloat = 14
    static let paddingMedium: CGFloat = 16
    static let spacingSmall: CGFloat = 6
    static let spacingMedium: CGFloat = 8
    static let titleFontSmall: CGFloat = 11
    static let titleFontMedium: CGFloat = 12
    static let labelFont: CGFloat = 9
    static let gameTitleFontSmall: CGFloat = 13
    static let gameTitleFontMedium: CGFloat = 14
    static let nextFont: CGFloat = 11
    static let statsFont: CGFloat = 9
    static let radarSizeMedium: CGFloat = 110
}

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

    // MARK: - Small Widget (158×158: playing, next, stats — no chart)

    private var smallWidget: some View {
        let fg = Color.white
        let muted = Color.white.opacity(0.65)
        let dim = Color.white.opacity(0.45)
        return VStack(alignment: .leading, spacing: WidgetLayout.spacingSmall) {
            HStack(spacing: 4) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: WidgetLayout.titleFontSmall, weight: .semibold))
                    .foregroundStyle(fg)
                Text("Checkpoint")
                    .font(.system(size: WidgetLayout.titleFontSmall, weight: .semibold))
                    .foregroundStyle(fg)
            }

            if let title = entry.playingFirstTitle {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Playing")
                        .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                        .foregroundStyle(muted)
                    Text(title)
                        .font(.system(size: WidgetLayout.gameTitleFontSmall, weight: .medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(fg)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Playing")
                        .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                        .foregroundStyle(muted)
                    Text("No games in progress")
                        .font(.system(size: WidgetLayout.nextFont, weight: .regular))
                        .foregroundStyle(dim)
                }
            }

            if let nextTitle = entry.nextUpTitle {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Next")
                        .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                        .foregroundStyle(dim)
                    Text(nextTitle)
                        .font(.system(size: WidgetLayout.nextFont, weight: .regular))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(muted)
                }
            }

            Spacer(minLength: 0)

            Text("\(entry.totalGames) games · \(entry.completedGames) completed")
                .font(.system(size: WidgetLayout.statsFont, weight: .medium))
                .foregroundStyle(dim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(WidgetLayout.paddingSmall)
        .containerBackground(for: .widget) { Color.black }
    }

    // MARK: - Medium Widget (338×158: left = games, right = fixed radar)

    private var mediumWidget: some View {
        let fg = Color.white
        let muted = Color.white.opacity(0.65)
        let dim = Color.white.opacity(0.45)
        return HStack(alignment: .top, spacing: WidgetLayout.paddingMedium) {
            VStack(alignment: .leading, spacing: WidgetLayout.spacingMedium) {
                HStack(spacing: 4) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: WidgetLayout.titleFontMedium, weight: .semibold))
                        .foregroundStyle(fg)
                    Text("Checkpoint")
                        .font(.system(size: WidgetLayout.titleFontMedium, weight: .semibold))
                        .foregroundStyle(fg)
                }

                if let title = entry.playingFirstTitle {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Playing")
                            .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                            .foregroundStyle(muted)
                        Text(title)
                            .font(.system(size: WidgetLayout.gameTitleFontMedium, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(fg)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Playing")
                            .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                            .foregroundStyle(muted)
                        Text("No games in progress")
                            .font(.system(size: WidgetLayout.nextFont))
                            .foregroundStyle(dim)
                    }
                }

                if let nextTitle = entry.nextUpTitle {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Next")
                            .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                            .foregroundStyle(dim)
                        Text(nextTitle)
                            .font(.system(size: WidgetLayout.nextFont))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(muted)
                    }
                }

                Spacer(minLength: 0)

                Text("\(entry.totalGames) games · \(entry.completedGames) completed")
                    .font(.system(size: WidgetLayout.statsFont, weight: .medium))
                    .foregroundStyle(dim)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .center, spacing: 2) {
                Text("Profile")
                    .font(.system(size: WidgetLayout.labelFont, weight: .medium))
                    .foregroundStyle(dim)
                WidgetRadarChart(values: entry.radarGenreCounts, size: WidgetLayout.radarSizeMedium, showLabels: true)
            }
            .frame(width: WidgetLayout.radarSizeMedium + 24, alignment: .center)
        }
        .padding(WidgetLayout.paddingMedium)
        .containerBackground(for: .widget) { Color.black }
    }
}

// MARK: - Mini Radar Chart (black/white)

/// Shortened labels for compact widget display.
private let radarAxisLabels = ["Other", "Action", "Shooter", "RPG", "Sports", "Horror"]

private struct WidgetRadarChart: View {
    let values: [Double]
    /// Fixed size (pt) so layout is predictable in widget.
    let size: CGFloat
    var showLabels: Bool = true

    private static let axisCount = 6

    var body: some View {
        GeometryReader { geo in
            let s = min(size, geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = showLabels ? s / 2 * 0.5 : s / 2 * 0.72
            let maxVal = values.max() ?? 1

            ZStack {
                // Grid
                ForEach(1..<(Self.axisCount), id: \.self) { level in
                    let r = radius * CGFloat(level) / CGFloat(Self.axisCount)
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        .frame(width: r * 2, height: r * 2)
                        .position(center)
                }
                ForEach(0..<Self.axisCount, id: \.self) { i in
                    let angle = angleForIndex(i)
                    let end = pointOnCircle(center: center, radius: radius, angle: angle)
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: end)
                    }
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                // Polygon
                if !values.isEmpty {
                    let pts = values.enumerated().map { i, v in
                        let angle = angleForIndex(i)
                        let r = maxVal > 0 ? radius * CGFloat(min(1, v / maxVal)) : 0
                        return pointOnCircle(center: center, radius: r, angle: angle)
                    }
                    if pts.count >= 3 {
                        WidgetPolygonShape(points: pts)
                            .fill(Color.white.opacity(0.5))
                            .overlay {
                                WidgetPolygonShape(points: pts)
                                    .stroke(Color.white, lineWidth: 2)
                            }
                    }
                }
                // Axis labels (outside the chart, along each spoke)
                if showLabels {
                    let fontSize = max(8, min(10, s * 0.09))
                    let labelRadius = radius + s * 0.14
                    ForEach(0..<Self.axisCount, id: \.self) { i in
                        let angle = angleForIndex(i)
                        let labelPos = pointOnCircle(center: center, radius: labelRadius, angle: angle)
                        Text(radarAxisLabels[i])
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 0)
                            .position(labelPos)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func angleForIndex(_ i: Int) -> CGFloat {
        let step = (2 * CGFloat.pi) / CGFloat(Self.axisCount)
        return -.pi / 2 + CGFloat(i) * step
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

private struct WidgetPolygonShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard points.count >= 3, let first = points.first else { return p }
        p.move(to: first)
        for point in points.dropFirst() {
            p.addLine(to: point)
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Widget Configuration

struct VGBWidget: Widget {
    let kind: String = "VGBWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VGBTimelineProvider()) { entry in
            VGBWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Checkpoint")
        .description("Currently playing, gamer profile radar, and backlog stats.")
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
    VGBWidgetEntry(date: .now, nextUpTitle: "Elden Ring", nextUpPlatform: "PS5", totalGames: 12, completedGames: 5, playingCount: 2, playingFirstTitle: "Zelda: TOTK", playingFirstPlatform: "Switch", radarGenreCounts: [1, 3, 2, 5, 1, 2])
}

#Preview(as: .systemMedium) {
    VGBWidget()
} timeline: {
    VGBWidgetEntry(date: .now, nextUpTitle: "Elden Ring", nextUpPlatform: "PS5", totalGames: 24, completedGames: 8, playingCount: 3, playingFirstTitle: "Zelda: Tears of the Kingdom", playingFirstPlatform: "Switch", radarGenreCounts: [2, 5, 3, 8, 2, 4])
}
