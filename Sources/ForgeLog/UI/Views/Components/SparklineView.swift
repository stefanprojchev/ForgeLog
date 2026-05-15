#if os(iOS) || os(visionOS)
import SwiftUI

/// Bar-chart sparkline showing log volume across the time range of the
/// supplied entries. Each bar is **stacked** per-severity from most severe at
/// the top down to least severe at the bottom, so the actual distribution is
/// visible at a glance — a bucket with one error and many infos shows mostly
/// blue with a thin red sliver, not solid red.
///
/// The window adapts to the data: if entries span months the sparkline shows
/// that span; if they span seconds it zooms in. Empty data renders flat.
struct SparklineView: View {
    let entries: [LogEntry]
    var bucketCount: Int = 60
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        GeometryReader { geo in
            let buckets = computeBuckets()
            let maxCount = max(1, buckets.map(\.total).max() ?? 1)
            let gap: CGFloat = 1.5
            let barWidth = max(1, (geo.size.width - gap * CGFloat(bucketCount - 1)) / CGFloat(bucketCount))

            HStack(alignment: .bottom, spacing: gap) {
                ForEach(buckets.indices, id: \.self) { i in
                    bar(bucket: buckets[i],
                        barWidth: barWidth,
                        maxCount: maxCount,
                        chartHeight: geo.size.height)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topLeading) {
                Text(leftLabel)
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.leading, 2)
            }
            .overlay(alignment: .topTrailing) {
                Text(rightLabel)
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

    // MARK: - Bar

    @ViewBuilder
    private func bar(bucket: Bucket, barWidth: CGFloat, maxCount: Int, chartHeight: CGFloat) -> some View {
        let totalHeight = bucket.total == 0
            ? CGFloat(1)
            : max(2, chartHeight * CGFloat(bucket.total) / CGFloat(maxCount))

        VStack(spacing: 0) {
            if bucket.total == 0 {
                Rectangle()
                    .fill(theme.text4)
                    .frame(width: barWidth, height: totalHeight)
            } else {
                // Stack severity sub-bars from top (most severe) to bottom.
                ForEach((0..<4).reversed(), id: \.self) { raw in
                    let count = bucket.perLevel[raw]
                    if count > 0 {
                        Rectangle()
                            .fill(theme.severity[LogLevel(rawValue: raw)!]!.fg)
                            .frame(
                                width: barWidth,
                                height: totalHeight * CGFloat(count) / CGFloat(bucket.total)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Labels

    private var leftLabel: String {
        guard let oldest = entries.map(\.timestamp).min() else { return "—" }
        return Self.relativeLabel(for: oldest)
    }

    private var rightLabel: String {
        guard let newest = entries.map(\.timestamp).max() else { return "—" }
        if Date().timeIntervalSince(newest) < 5 { return "NOW" }
        return Self.relativeLabel(for: newest)
    }

    /// "5s", "2m", "3h", "4d", "2w", "3mo" — short relative-to-now label.
    private static func relativeLabel(for date: Date) -> String {
        let secs = max(0, Date().timeIntervalSince(date))
        switch secs {
        case 0..<60:                   return "\(Int(secs))s"
        case 60..<3_600:               return "\(Int(secs / 60))m"
        case 3_600..<86_400:           return "\(Int(secs / 3_600))h"
        case 86_400..<7 * 86_400:      return "\(Int(secs / 86_400))d"
        case 7 * 86_400..<30 * 86_400: return "\(Int(secs / (7 * 86_400)))w"
        default:                       return "\(Int(secs / (30 * 86_400)))mo"
        }
    }

    // MARK: - Bucketing

    private struct Bucket {
        var total: Int = 0
        /// Indexed by `LogLevel.rawValue` (debug=0…error=3).
        var perLevel: [Int] = [0, 0, 0, 0]

        mutating func add(_ level: LogLevel) {
            total += 1
            perLevel[level.rawValue] += 1
        }
    }

    private func computeBuckets() -> [Bucket] {
        var buckets: [Bucket] = Array(repeating: Bucket(), count: bucketCount)
        guard !entries.isEmpty else { return buckets }

        let timestamps = entries.map(\.timestamp)
        let oldest = timestamps.min()!
        let newest = timestamps.max()!
        let span = max(1, newest.timeIntervalSince(oldest))
        let bucketDuration = span / Double(bucketCount)

        for entry in entries {
            let offset = entry.timestamp.timeIntervalSince(oldest)
            var idx = Int(offset / bucketDuration)
            if idx >= bucketCount { idx = bucketCount - 1 }
            if idx < 0 { idx = 0 }
            buckets[idx].add(entry.level)
        }
        return buckets
    }
}
#endif
