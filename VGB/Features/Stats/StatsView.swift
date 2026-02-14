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

    private var genreCounts: [(String, Int)] {
        let grouped = Dictionary(grouping: games.compactMap(\.genre).filter { !$0.isEmpty }, by: { $0 })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .prefix(8)
            .map { ($0.0, $0.1) }
    }

    /// Completed games per radar category (always 6 categories for a consistent chart).
    private var completedPerGenre: [(label: String, value: Double)] {
        let completed = games.filter { $0.status == .completed }
        let genreStrings = completed.compactMap { $0.genre }.filter { !$0.isEmpty }
        return RadarGenreCategories.completedCountsByCategory(from: genreStrings)
    }

    private var completedWithRating: [Game] {
        games.filter { $0.status == .completed && $0.igdbRating != nil }
    }

    private var averageCriticScore: Double? {
        let rated = completedWithRating.compactMap(\.igdbRating).map(Double.init)
        guard !rated.isEmpty else { return nil }
        return rated.reduce(0, +) / Double(rated.count)
    }

    @State private var heroRingTrim: CGFloat = 0

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            heroSection
                            statusDonutSection
                            barChartsSection
                            averageCriticSection
                            radarSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Stats")
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    heroRingTrim = completionRate
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: 12)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: heroRingTrim)
                    .stroke(GameStatus.completed.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.title2.weight(.bold))
                    Text("complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text("You've completed **\(completedCount)** of **\(totalCount)** games")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Status donut

    private var statusDonutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("By status", systemImage: "chart.pie")
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

    // MARK: - Bar charts

    private var barChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("By genre", systemImage: "tag")
            if genreCounts.isEmpty {
                Text("No genre data")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(genreCounts, id: \.0) { item in
                    BarMark(
                        x: .value("Genre", item.0),
                        y: .value("Games", item.1)
                    )
                    .foregroundStyle(.mint.gradient)
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: - Average critic

    private var averageCriticSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Completed games — critic score", systemImage: "star.fill")
            if let avg = averageCriticScore {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", avg))
                        .font(.title.weight(.semibold))
                    Text("average")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("(\(completedWithRating.count) rated)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("No critic scores for completed games yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Radar

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Completed by genre", systemImage: "point.3.connected.trianglepath.dotted")
            if completedPerGenre.allSatisfy({ $0.value == 0 }) {
                Text("Complete games with genres to see your radar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    RadarChartView(
                        data: completedPerGenre,
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
