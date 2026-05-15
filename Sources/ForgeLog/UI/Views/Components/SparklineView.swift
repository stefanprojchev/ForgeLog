#if os(iOS) || os(visionOS)
import SwiftUI

/// Bar-chart sparkline. Each bar is **stacked** per-severity from most severe
/// at the top down to least severe at the bottom, so the actual distribution
/// is visible at a glance.
///
/// Touch + drag scrubs across the bars. While scrubbing, the hovered bar
/// gets a vertical accent line and the others dim; a small pill at the top
/// of the strip shows the bucket's timestamp, total entry count, and a
/// per-level breakdown. The tooltip fades 1.5s after the finger lifts so a
/// quick tap also reveals info without needing to hold.
struct SparklineView: View {
    let entries: [LogEntry]
    var bucketCount: Int = 60
    @Environment(\.forgeTheme) private var theme

    @State private var hoveredIndex: Int?
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let buckets = computeBuckets()
            let maxCount = max(1, buckets.map(\.total).max() ?? 1)
            let gap: CGFloat = 1.5
            let barWidth = max(1, (geo.size.width - gap * CGFloat(bucketCount - 1)) / CGFloat(bucketCount))

            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(buckets.indices, id: \.self) { i in
                        bar(bucket: buckets[i],
                            barWidth: barWidth,
                            maxCount: maxCount,
                            chartHeight: geo.size.height,
                            isHovered: hoveredIndex == i,
                            anySelected: hoveredIndex != nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let idx = hoveredIndex, idx < buckets.count {
                    accentLine(at: idx, barWidth: barWidth, gap: gap, height: geo.size.height)
                }
            }
            .contentShape(Rectangle())
            .gesture(scrubGesture(width: geo.size.width, barCount: buckets.count))
            .overlay(alignment: .top) { topOverlay(buckets: buckets) }
        }
        .frame(height: 36)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    // MARK: - Bar

    @ViewBuilder
    private func bar(bucket: Bucket, barWidth: CGFloat, maxCount: Int, chartHeight: CGFloat,
                     isHovered: Bool, anySelected: Bool) -> some View {
        let totalHeight = bucket.total == 0
            ? CGFloat(1)
            : max(2, chartHeight * CGFloat(bucket.total) / CGFloat(maxCount))

        VStack(spacing: 0) {
            if bucket.total == 0 {
                Rectangle()
                    .fill(theme.text4)
                    .frame(width: barWidth, height: totalHeight)
            } else {
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
        .opacity(anySelected ? (isHovered ? 1.0 : 0.45) : 1.0)
        .animation(.easeOut(duration: 0.12), value: hoveredIndex)
    }

    // MARK: - Hover line

    private func accentLine(at index: Int, barWidth: CGFloat, gap: CGFloat, height: CGFloat) -> some View {
        let x = CGFloat(index) * (barWidth + gap) + barWidth / 2
        return Rectangle()
            .fill(theme.accent)
            .frame(width: 1.5, height: height)
            .position(x: x, y: height / 2)
            .allowsHitTesting(false)
            .transition(.opacity)
    }

    // MARK: - Top overlay (labels OR tooltip pill)

    @ViewBuilder
    private func topOverlay(buckets: [Bucket]) -> some View {
        if let idx = hoveredIndex, idx < buckets.count {
            tooltipPill(bucket: buckets[idx], index: idx, total: buckets.count)
                .transition(.opacity)
        } else {
            HStack {
                Text(leftLabel)
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.leading, 2)
                Spacer()
                Text(rightLabel)
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.trailing, 2)
            }
        }
    }

    private func tooltipPill(bucket: Bucket, index: Int, total: Int) -> some View {
        let timestamp = timestampFor(bucketIndex: index, of: total)
        return HStack(spacing: 8) {
            Text(timestamp)
                .font(theme.monoFont(10, weight: .semibold))
                .foregroundColor(theme.text1)
            if bucket.total > 0 {
                Rectangle()
                    .fill(theme.border)
                    .frame(width: 1, height: 9)
                Text("\(bucket.total)")
                    .font(theme.monoFont(10, weight: .bold))
                    .foregroundColor(theme.text1)
                ForEach((0..<4).reversed(), id: \.self) { raw in
                    if bucket.perLevel[raw] > 0 {
                        levelDot(level: LogLevel(rawValue: raw)!, count: bucket.perLevel[raw])
                    }
                }
            } else {
                Text("no entries")
                    .font(theme.monoFont(10))
                    .foregroundColor(theme.text3)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(theme.surfaceHi)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(theme.borderHi, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func levelDot(level: LogLevel, count: Int) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(theme.severity[level]!.fg)
                .frame(width: 5, height: 5)
            Text("\(count)")
                .font(theme.monoFont(9, weight: .semibold))
                .foregroundColor(theme.text2)
        }
    }

    // MARK: - Gesture

    private func scrubGesture(width: CGFloat, barCount: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let clamped = max(0, min(width, value.location.x))
                let normalized = clamped / max(1, width)
                let idx = min(barCount - 1, max(0, Int(normalized * CGFloat(barCount))))
                dismissTask?.cancel()
                if hoveredIndex != idx {
                    withAnimation(.easeOut(duration: 0.12)) { hoveredIndex = idx }
                }
            }
            .onEnded { _ in scheduleDismiss() }
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.2)) { hoveredIndex = nil }
            }
        }
    }

    // MARK: - Bucket timestamp

    private func timestampFor(bucketIndex: Int, of total: Int) -> String {
        guard !entries.isEmpty else { return "—" }
        let timestamps = entries.map(\.timestamp)
        let oldest = timestamps.min()!
        let newest = timestamps.max()!
        let span = max(1, newest.timeIntervalSince(oldest))
        let bucketDuration = span / Double(total)
        let centerOffset = (Double(bucketIndex) + 0.5) * bucketDuration
        let date = oldest.addingTimeInterval(centerOffset)
        return Self.tooltipFormatter.string(from: date)
    }

    private static let tooltipFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

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

    fileprivate struct Bucket {
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
