import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Game.priorityPosition) private var games: [Game]

    private var totalCount: Int { games.count }
    private var completedCount: Int { games.filter { $0.status == .completed }.count }
    private var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    private var statusCounts: [(GameStatus, Int)] {
        GameStatus.allCases.map { status in
            (status, games.filter { $0.status == status }.count)
        }
    }

    /// All games (backlog, wishlist, playing, completed, dropped) per radar genre category (6 axes).
    private var libraryPerGenre: [(label: String, value: Double)] {
        let genreStrings = games.compactMap(\.genre).filter { !$0.isEmpty }
        return RadarGenreCategories.completedCountsByCategory(from: genreStrings)
    }

    private var completedWithCriticRating: [Game] {
        games.filter { $0.status == .completed && $0.igdbRating != nil }
    }

    private var averageCriticScore: Double? {
        let rated = completedWithCriticRating.compactMap(\.igdbRating).map(Double.init)
        guard !rated.isEmpty else { return nil }
        return rated.reduce(0, +) / Double(rated.count)
    }

    private var completedWithUserRating: [Game] {
        games.filter { $0.status == .completed && $0.personalRating != nil }
    }

    private var averageUserRating: Double? {
        let rated = completedWithUserRating.compactMap(\.personalRating).map(Double.init)
        guard !rated.isEmpty else { return nil }
        return rated.reduce(0, +) / Double(rated.count)
    }

    @State private var heroRingTrim: CGFloat = 0
    @State private var criticRingTrim: CGFloat = 0
    @State private var userRingTrim: CGFloat = 0

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 36) {
                            radarSection
                            threeRingsSection
                            statusDonutSection
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    heroRingTrim = completionRate
                    if let avg = averageCriticScore {
                        criticRingTrim = CGFloat(avg / 100)
                    }
                    if let avg = averageUserRating {
                        userRingTrim = CGFloat(avg / 100)
                    }
                }
            }
            .onChange(of: averageCriticScore) { _, newVal in
                withAnimation(.easeOut(duration: 0.5)) {
                    criticRingTrim = newVal.map { CGFloat($0 / 100) } ?? 0
                }
            }
            .onChange(of: averageUserRating) { _, newVal in
                withAnimation(.easeOut(duration: 0.5)) {
                    userRingTrim = newVal.map { CGFloat($0 / 100) } ?? 0
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Stats Yet", systemImage: "chart.pie")
        } description: {
            Text("Add games to your backlog to see your stats and charts.")
        }
    }

    // MARK: - Three rings (Completed %, Critic, User rating)

    private static let ringSize: CGFloat = 76
    private static let ringStroke: CGFloat = 8

    private var threeRingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Completion & ratings", systemImage: "chart.bar.doc.horizontal")
            Text("Share completed, critic average, and your average rating")
                .font(.caption)
                .foregroundStyle(.tertiary)
            HStack(alignment: .top, spacing: 12) {
                completedRingTile
                criticRingTile
                userRatingRingTile
            }
        }
    }

    private var completedRingTile: some View {
        VStack(spacing: 6) {
            Text("Completed %")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: Self.ringStroke)
                    .frame(width: Self.ringSize, height: Self.ringSize)
                Circle()
                    .trim(from: 0, to: heroRingTrim)
                    .stroke(GameStatus.completed.color, style: StrokeStyle(lineWidth: Self.ringStroke, lineCap: .round))
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(completionRate * 100))%")
                    .font(.subheadline.weight(.bold))
            }
            Text("\(completedCount)/\(totalCount)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var criticRingTile: some View {
        VStack(spacing: 6) {
            Text("Critic score")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: Self.ringStroke)
                    .frame(width: Self.ringSize, height: Self.ringSize)
                Circle()
                    .trim(from: 0, to: criticRingTrim)
                    .stroke(Self.criticGold, style: StrokeStyle(lineWidth: Self.ringStroke, lineCap: .round))
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .rotationEffect(.degrees(-90))
                if let avg = averageCriticScore {
                    Text(String(format: "%.1f", avg))
                        .font(.subheadline.weight(.bold))
                } else {
                    Text("—")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            if let _ = averageCriticScore {
                Text("\(completedWithCriticRating.count) rated")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Rate games")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var userRatingRingTile: some View {
        VStack(spacing: 6) {
            Text("Your rating")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: Self.ringStroke)
                    .frame(width: Self.ringSize, height: Self.ringSize)
                Circle()
                    .trim(from: 0, to: userRingTrim)
                    .stroke(Self.userRatingBlue, style: StrokeStyle(lineWidth: Self.ringStroke, lineCap: .round))
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .rotationEffect(.degrees(-90))
                if let avg = averageUserRating {
                    Text(String(format: "%.1f", avg))
                        .font(.subheadline.weight(.bold))
                } else {
                    Text("—")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            if let _ = averageUserRating {
                Text("\(completedWithUserRating.count) rated")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Rate games")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status donut

    private var statusDonutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Library breakdown", systemImage: "chart.pie")
            Text("Where your games live — by status")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Chart(statusCounts, id: \.0.id) { item in
                SectorMark(
                    angle: .value("Count", item.1),
                    innerRadius: .ratio(0.55),
                    angularInset: 1
                )
                .foregroundStyle(item.0.color)
                .cornerRadius(3)
            }
            .frame(height: 180)
            .chartLegend(.hidden)
            statusLegend
        }
    }

    private var statusLegend: some View {
        HStack(spacing: 16) {
            ForEach(GameStatus.allCases, id: \.id) { status in
                let count = games.filter { $0.status == status }.count
                HStack(spacing: 4) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    Text("\(status.rawValue) \(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private static let criticGold = Color(red: 0.95, green: 0.75, blue: 0.2)
    private static let userRatingBlue = Color(red: 0.35, green: 0.45, blue: 0.95)

    // MARK: - Radar

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Your Gamer Profile", systemImage: "point.3.connected.trianglepath.dotted")
            Text("How your whole library breaks down by genre")
                .font(.caption)
                .foregroundStyle(.tertiary)
            if libraryPerGenre.allSatisfy({ $0.value == 0 }) {
                Text("Add games with genres to see your chart.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    RadarChartView(
                        data: libraryPerGenre,
                        axisIcons: RadarGenreCategories.iconNames,
                        fillColor: GameStatus.completed.color
                    )
                    .frame(height: 220)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: Game.self, inMemory: true)
}
