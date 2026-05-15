#if os(iOS) || os(visionOS)
import SwiftUI

/// Bar-chart sparkline showing log volume across recent buckets, with bars
/// colored by the highest severity that appeared in each bucket.
struct SparklineView: View {
    @ObservedObject var store: LogViewerStore
    var bucketCount: Int = 60
    var windowSeconds: TimeInterval = 2
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        GeometryReader { geo in
            let buckets = computeBuckets()
            let maxCount = max(1, buckets.map(\.count).max() ?? 1)
            let gap: CGFloat = 1.5
            let barWidth = max(1, (geo.size.width - gap * CGFloat(bucketCount - 1)) / CGFloat(bucketCount))
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(buckets.indices, id: \.self) { i in
                    let b = buckets[i]
                    let ratio = CGFloat(b.count) / CGFloat(maxCount)
                    Rectangle()
                        .fill(barColor(for: b.maxLevel))
                        .frame(width: barWidth, height: max(2, ratio * geo.size.height))
                        .opacity(i > bucketCount * 11 / 12 ? 1 : 0.95)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topLeading) {
                Text("−\(Int(windowSeconds))s")
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.leading, 2)
            }
            .overlay(alignment: .topTrailing) {
                Text("NOW")
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.trailing, 2)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    private struct Bucket { let count: Int; let maxLevel: LogLevel? }

    private func computeBuckets() -> [Bucket] {
        let now = Date()
        let bucketDuration = windowSeconds / Double(bucketCount)
        var buckets: [Bucket] = Array(repeating: Bucket(count: 0, maxLevel: nil), count: bucketCount)
        for entry in store.entries.reversed() {
            let age = now.timeIntervalSince(entry.timestamp)
            if age > windowSeconds { break }
            let idx = bucketCount - 1 - Int(age / bucketDuration)
            guard idx >= 0, idx < bucketCount else { continue }
            let prev = buckets[idx]
            let newMax: LogLevel? = {
                guard let prevLvl = prev.maxLevel else { return entry.level }
                return entry.level > prevLvl ? entry.level : prevLvl
            }()
            buckets[idx] = Bucket(count: prev.count + 1, maxLevel: newMax)
        }
        return buckets
    }

    private func barColor(for level: LogLevel?) -> Color {
        guard let level else {
            return theme.mode == .light
                ? Color(hex: "#0058D8").opacity(0.32)
                : Color(hex: "#5BA8FF").opacity(0.32)
        }
        return theme.severity[level]?.fg ?? theme.accent
    }
}
#endif
