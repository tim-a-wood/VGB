import SwiftUI
import SwiftData

/// Rating source for the rankings list: user's personal rating or critic (IGDB) rating.
enum RankingsRatingSource: String, CaseIterable {
    case yourRating = "Your rating"
    case criticRating = "Critic rating"
}

struct RankingsView: View {
    @Query(sort: \Game.priorityPosition) private var games: [Game]

    @State private var ratingSource: RankingsRatingSource = .yourRating

    /// Games that have the selected rating type, sorted by that rating descending (highest first).
    private var rankedGames: [Game] {
        switch ratingSource {
        case .yourRating:
            let withRating = games.filter { $0.personalRating != nil }
            return withRating.sorted { ($0.personalRating ?? 0) > ($1.personalRating ?? 0) }
        case .criticRating:
            let withRating = games.filter { $0.igdbRating != nil }
            return withRating.sorted { ($0.igdbRating ?? 0) > ($1.igdbRating ?? 0) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if rankedGames.isEmpty {
                    emptyState
                } else {
                    List {
                            ForEach(Array(rankedGames.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(value: game) {
                                    RankingsRowView(
                                        game: game,
                                        rank: index + 1,
                                        ratingSource: ratingSource
                                    )
                                }
                            }
                        }
                        .listStyle(.plain)
                }
            }
            .navigationTitle("Rankings")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Rating type", selection: $ratingSource) {
                        ForEach(RankingsRatingSource.allCases, id: \.self) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }
            }
            .navigationDestination(for: Game.self) { game in
                GameDetailView(game: game)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Rated Games", systemImage: "star")
        } description: {
            Text(
                ratingSource == .yourRating
                    ? "Rate games in the catalog to see your personal rankings here."
                    : "Add games with critic scores (from IGDB) to see critic rankings here."
            )
        }
    }
}

// MARK: - Row

private struct RankingsRowView: View {
    let game: Game
    let rank: Int
    let ratingSource: RankingsRatingSource

    private var ratingValue: Int? {
        switch ratingSource {
        case .yourRating: game.personalRating
        case .criticRating: game.igdbRating
        }
    }

    /// Color by score: 0–99 = dark red → red → orange → yellow → light green → dark green; 100 = gold.
    private static func color(for value: Int) -> Color {
        let clamped = min(100, max(0, value))
        if clamped == 100 {
            return Color(red: 1, green: 0.76, blue: 0) // gold
        }
        // Six stops so 80 vs 97 are clearly different (light green vs dark green)
        let t = Double(clamped) / 99
        let stops: [(pos: Double, r: Double, g: Double, b: Double)] = [
            (0.00, 0.55, 0.08, 0.08),  // dark red
            (0.20, 0.95, 0.20, 0.20), // red
            (0.40, 1.00, 0.45, 0.10), // orange
            (0.60, 1.00, 0.88, 0.15), // yellow
            (0.80, 0.55, 0.95, 0.25), // light green
            (1.00, 0.15, 0.55, 0.15), // dark green
        ]
        for i in 0..<(stops.count - 1) {
            let a = stops[i]
            let b = stops[i + 1]
            if t <= b.pos {
                let u = (t - a.pos) / (b.pos - a.pos)
                let r = a.r + (b.r - a.r) * u
                let g = a.g + (b.g - a.g) * u
                let bl = a.b + (b.b - a.b) * u
                return Color(red: r, green: g, blue: bl)
            }
        }
        return Color(red: stops.last!.r, green: stops.last!.g, blue: stops.last!.b)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)

            // Cover
            if let urlString = game.coverImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                        .overlay { Image(systemName: "gamecontroller").font(.caption).foregroundStyle(.tertiary) }
                }
                .frame(width: 44, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 44, height: 58)
                    .overlay { Image(systemName: "gamecontroller").font(.caption).foregroundStyle(.tertiary) }
            }

            // Title & platform
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.headline)
                    .lineLimit(1)
                if !game.platform.isEmpty {
                    Text(game.displayPlatform)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Rating
            if let value = ratingValue {
                Text("\(value)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Self.color(for: value))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RankingsView()
        .modelContainer(for: Game.self, inMemory: true)
}
