#if os(iOS) || os(visionOS)
import SwiftUI

struct HistogramBucket {
    var total: Int
    /// Per-severity counts, indexed by `LogLevel.rawValue` (debug=0…error=3).
    var perLevel: [Int]

    static let empty = HistogramBucket(total: 0, perLevel: [0, 0, 0, 0])

    mutating func add(_ level: LogLevel) {
        total += 1
        perLevel[level.rawValue] += 1
    }
}

/// Interactive bar chart with two draggable range markers. Each bar stacks
/// per-severity sub-bars from most-severe at the top. Bars outside the
/// selected range are dimmed.
///
/// **Interaction model**
///
/// `DragGesture(minimumDistance: 0)` covers the whole chart. On first touch
/// we pick the marker (start or end) closer to the finger and lock it as the
/// "active handle" for the gesture. Subsequent movement snaps to the nearest
/// day boundary; the active handle's binding updates and the parent's date
/// follows.
struct HistogramView: View {
    // MARK: - Properties

    let buckets: [HistogramBucket]
    @Binding var rangeStartIndex: Int
    @Binding var rangeEndIndex: Int

    @Environment(\.forgeTheme) private var theme
    @State private var activeHandle: Handle?
    @State private var lastSnappedIndex: Int = -1

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let count = buckets.count
            let gap: CGFloat = 1.5
            let barWidth = max(2, (geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count))
            let maxTotal = max(1, buckets.map(\.total).max() ?? 1)

            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(buckets.indices, id: \.self) { i in
                        bar(
                            bucket: buckets[i],
                            barWidth: barWidth,
                            maxTotal: maxTotal,
                            chartHeight: geo.size.height,
                            inRange: i >= rangeStartIndex && i <= rangeEndIndex
                        )
                    }
                }

                rangeMarker(
                    at: rangeStartIndex,
                    handle: .start,
                    barWidth: barWidth,
                    gap: gap,
                    height: geo.size.height
                )
                if rangeEndIndex != rangeStartIndex {
                    rangeMarker(
                        at: rangeEndIndex,
                        handle: .end,
                        barWidth: barWidth,
                        gap: gap,
                        height: geo.size.height
                    )
                }

                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(width: geo.size.width, barWidth: barWidth, gap: gap, count: count))
            .sensoryFeedback(.selection, trigger: lastSnappedIndex)
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func bar(bucket: HistogramBucket, barWidth: CGFloat, maxTotal: Int, chartHeight: CGFloat, inRange: Bool) -> some View {
        let totalHeight = bucket.total == 0
            ? CGFloat(1)
            : max(2, chartHeight * CGFloat(bucket.total) / CGFloat(maxTotal))

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
                            .frame(width: barWidth,
                                   height: totalHeight * CGFloat(count) / CGFloat(bucket.total))
                    }
                }
            }
        }
        .opacity(inRange ? 1 : 0.45)
    }

    private func rangeMarker(at index: Int, handle: Handle, barWidth: CGFloat, gap: CGFloat, height: CGFloat) -> some View {
        let x = CGFloat(index) * (barWidth + gap) + barWidth / 2
        let isActive = activeHandle == handle
        let circleSize: CGFloat = isActive ? 18 : 14
        return ZStack {
            Rectangle()
                .fill(theme.accent.opacity(isActive ? 1.0 : 0.85))
                .frame(width: isActive ? 3 : 2, height: height)
                .position(x: x, y: height / 2)
            Circle()
                .fill(theme.accent)
                .frame(width: circleSize, height: circleSize)
                .overlay(Circle().stroke(theme.bg, lineWidth: 2))
                .shadow(color: isActive ? theme.accent.opacity(0.4) : .clear, radius: isActive ? 4 : 0)
                .position(x: x, y: circleSize / 2)
            Circle()
                .fill(theme.accent)
                .frame(width: circleSize, height: circleSize)
                .overlay(Circle().stroke(theme.bg, lineWidth: 2))
                .shadow(color: isActive ? theme.accent.opacity(0.4) : .clear, radius: isActive ? 4 : 0)
                .position(x: x, y: height - circleSize / 2)
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.12), value: isActive)
    }

    // MARK: - Private

    enum Handle: Equatable { case start, end }

    private func dragGesture(width: CGFloat, barWidth: CGFloat, gap: CGFloat, count: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeHandle == nil {
                    activeHandle = pickHandle(forStartX: value.startLocation.x,
                                              barWidth: barWidth,
                                              gap: gap)
                }
                let newIndex = bucketIndex(forX: value.location.x,
                                           width: width,
                                           count: count)
                apply(newIndex: newIndex)
            }
            .onEnded { _ in
                activeHandle = nil
            }
    }

    private func pickHandle(forStartX startX: CGFloat, barWidth: CGFloat, gap: CGFloat) -> Handle {
        let startMarkerX = CGFloat(rangeStartIndex) * (barWidth + gap) + barWidth / 2
        let endMarkerX = CGFloat(rangeEndIndex) * (barWidth + gap) + barWidth / 2
        return abs(startX - startMarkerX) <= abs(startX - endMarkerX) ? .start : .end
    }

    private func bucketIndex(forX x: CGFloat, width: CGFloat, count: Int) -> Int {
        let clamped = max(0, min(width, x))
        let normalized = clamped / max(1, width)
        return min(count - 1, max(0, Int(normalized * CGFloat(count))))
    }

    private func apply(newIndex: Int) {
        switch activeHandle {
        case .start:
            let clamped = min(newIndex, rangeEndIndex)
            if clamped != rangeStartIndex {
                rangeStartIndex = clamped
                lastSnappedIndex = clamped
            }
        case .end:
            let clamped = max(newIndex, rangeStartIndex)
            if clamped != rangeEndIndex {
                rangeEndIndex = clamped
                lastSnappedIndex = clamped + 1_000
            }
        case .none:
            break
        }
    }
}
#endif
