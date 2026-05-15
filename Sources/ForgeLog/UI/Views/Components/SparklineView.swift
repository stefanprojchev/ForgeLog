#if os(iOS) || os(visionOS)
import SwiftUI

/// Bar-chart sparkline showing log volume across the time range of the
/// supplied entries, with bars colored by the highest severity in each bucket.
///
/// The window adapts to the data: if the entries span months, the sparkline
/// shows that span; if they span seconds, it zooms in. Empty data renders a
/// flat baseline of `theme.text4`.
struct SparklineView: View {
    let entries: [LogEntry]
    var bucketCount: Int = 60
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
                    let height = b.count == 0 ? CGFloat(1) : max(2, ratio * geo.size.height)
                    Rectangle()
                        .fill(barColor(for: b.maxLevel))
                        .frame(width: barWidth, height: height)
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

    // MARK: - Labels

    private var leftLabel: String {
        guard let oldest = entries.map(\.timestamp).min() else { return "—" }
        return Self.relativeLabel(for: oldest)
    }

    private var rightLabel: String {
        guard let newest = entries.map(\.timestamp).max() else { return "—" }
        // If the newest entry is within ~5 seconds of now, label as NOW.
        if Date().timeIntervalSince(newest) < 5 { return "NOW" }
        return Self.relativeLabel(for: newest)
    }

    /// "5s", "2m", "3h", "4d", "2w", "3mo" — short relative-to-now label.
    private static func relativeLabel(for date: Date) -> String {
        let secs = max(0, Date().timeIntervalSince(date))
        switch secs {
        case 0..<60:        return "\(Int(secs))s"
        case 60..<3_600:    return "\(Int(secs / 60))m"
        case 3_600..<86_400: return "\(Int(secs / 3_600))h"
        case 86_400..<7 * 86_400:    return "\(Int(secs / 86_400))d"
        case 7 * 86_400..<30 * 86_400: return "\(Int(secs / (7 * 86_400)))w"
        default:            return "\(Int(secs / (30 * 86_400)))mo"
        }
    }

    // MARK: - Bucketing

    private struct Bucket { let count: Int; let maxLevel: LogLevel? }

    private func computeBuckets() -> [Bucket] {
        guard !entries.isEmpty else {
            return Array(repeating: Bucket(count: 0, maxLevel: nil), count: bucketCount)
        }

        let timestamps = entries.map(\.timestamp)
        let oldest = timestamps.min()!
        let newest = timestamps.max()!
        let span = max(1, newest.timeIntervalSince(oldest))
        let bucketDuration = span / Double(bucketCount)

        var buckets: [Bucket] = Array(repeating: Bucket(count: 0, maxLevel: nil), count: bucketCount)

        for entry in entries {
            let offset = entry.timestamp.timeIntervalSince(oldest)
            var idx = Int(offset / bucketDuration)
            if idx >= bucketCount { idx = bucketCount - 1 }
            if idx < 0 { idx = 0 }
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
        guard let level else { return theme.text4 }
        return theme.severity[level]?.fg ?? theme.accent
    }
}
#endif
