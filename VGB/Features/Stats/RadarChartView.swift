import SwiftUI

/// A single-series radar (spider) chart. Each axis is a category; value = magnitude.
/// Designed so a second series (e.g. friend's stats) can be overlaid later for comparison.
struct RadarChartView: View {
    /// (Axis label, value). Values are drawn scaled to max; empty data shows empty polygon.
    let data: [(label: String, value: Double)]
    /// Fill color for the polygon.
    var fillColor: Color = .accentColor
    /// Max value for scale (nil = use max of data).
    var scaleMax: Double?

    private static let gridLevels = 3

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = (size / 2) * 0.75
            let maxVal = scaleMax ?? data.map(\.value).max() ?? 1

            ZStack {
                // Grid and axes
                radarGrid(center: center, radius: radius, count: data.count)
                // Axis labels
                axisLabels(center: center, radius: radius)
                // Data polygon
                if !data.isEmpty {
                    radarPolygon(center: center, radius: radius, maxVal: maxVal > 0 ? maxVal : 1)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func radarGrid(center: CGPoint, radius: CGFloat, count: Int) -> some View {
        let n = max(2, count)
        return ZStack {
            // Concentric circles
            ForEach(1..<(Self.gridLevels + 1), id: \.self) { level in
                let r = radius * CGFloat(level) / CGFloat(Self.gridLevels)
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                    .frame(width: r * 2, height: r * 2)
                    .position(center)
            }
            // Spokes
            ForEach(0..<n, id: \.self) { i in
                let angle = angleForIndex(i, count: n)
                let end = pointOnCircle(center: center, radius: radius, angle: angle)
                Path { p in
                    p.move(to: center)
                    p.addLine(to: end)
                }
                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
            }
        }
    }

    private func axisLabels(center: CGPoint, radius: CGFloat) -> some View {
        let items = Array(data)
        let n = max(2, items.count)
        return ForEach(Array(items.enumerated()), id: \.offset) { index, item in
            let angle = angleForIndex(index, count: n)
            let labelRadius = radius + 14
            let pos = pointOnCircle(center: center, radius: labelRadius, angle: angle)
            Text(item.label)
                .font(.caption2)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .position(pos)
        }
    }

    private func radarPolygon(center: CGPoint, radius: CGFloat, maxVal: Double) -> some View {
        let items = Array(data)
        let n = max(2, items.count)
        let points: [CGPoint] = items.enumerated().map { index, item in
            let angle = angleForIndex(index, count: n)
            let ratio = maxVal > 0 ? CGFloat(item.value / maxVal) : 0
            let r = radius * min(1, ratio)
            return pointOnCircle(center: center, radius: r, angle: angle)
        }
        return PolygonShape(points: points)
            .fill(fillColor.opacity(0.35))
            .overlay {
                PolygonShape(points: points)
                    .stroke(fillColor, lineWidth: 2)
            }
    }

    private func angleForIndex(_ index: Int, count: Int) -> CGFloat {
        // First axis at top (12 o'clock), then clockwise.
        let step = (2 * CGFloat.pi) / CGFloat(count)
        return -.pi / 2 + CGFloat(index) * step
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

private struct PolygonShape: Shape {
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

#Preview {
    RadarChartView(data: [
        ("RPG", 5),
        ("Action", 3),
        ("Adventure", 4),
        ("Puzzle", 1),
        ("Racing", 2),
    ])
    .frame(width: 200, height: 200)
    .padding()
}
