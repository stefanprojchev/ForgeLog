#if os(iOS) || os(visionOS)
import SwiftUI

/// Date range picker — matches the Claude Design "D · Full canvas + Timeline
/// scrubber" mock: a status row, a FROM → TO tile pair, a 30-day histogram
/// colored by severity with markers for the selected range, preset chips,
/// and a decorative Time of Day section.
///
/// Functionally only the date range is wired (`filter.dateRange`). Time of
/// Day is decorative for now — the design is shown but does not filter, so
/// behavior is unchanged from the previous implementation.
struct DateRangePickerView: View {
    @Binding var filter: FilterState
    let entries: [LogEntry]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    @State private var startDate: Date
    @State private var endDate: Date

    /// Which tile is currently being edited. `nil` when no edit sheet is up.
    @State private var editing: Endpoint?

    enum Endpoint: Identifiable {
        case from, to
        var id: String { self == .from ? "from" : "to" }
    }

    private static let histogramDays = 30

    init(filter: Binding<FilterState>, entries: [LogEntry] = []) {
        _filter = filter
        self.entries = entries
        let now = Date()
        let initialStart = filter.wrappedValue.dateRange?.lowerBound
            ?? Calendar.current.date(byAdding: .day, value: -3, to: now)
            ?? now
        let initialEnd = filter.wrappedValue.dateRange?.upperBound ?? now
        _startDate = State(initialValue: initialStart)
        _endDate = State(initialValue: initialEnd)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusRow
                    dateTilesRow
                    histogramSection
                    presetsRow
                    if filter.dateRange != nil {
                        clearButton
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .principal) {
                    Text("Date range")
                        .font(.headline)
                        .foregroundColor(theme.text1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        filter.dateRange = startDate...endDate
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accent)
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { endpoint in
                endpointEditor(for: endpoint)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Endpoint editor sheet

    @ViewBuilder
    private func endpointEditor(for endpoint: Endpoint) -> some View {
        // Normalize the picked date to a day boundary: FROM → start of day,
        // TO → end of day. The filter compares full timestamps, so without
        // normalization a TO date picked at 10:00 would silently drop the
        // rest of that day's entries.
        let binding = Binding<Date>(
            get: { endpoint == .from ? startDate : endDate },
            set: { newValue in
                let cal = Calendar.current
                let dayStart = cal.startOfDay(for: newValue)
                let normalized: Date
                switch endpoint {
                case .from:
                    normalized = dayStart
                case .to:
                    normalized = cal.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) ?? newValue
                }
                if endpoint == .from { startDate = normalized } else { endDate = normalized }
            }
        )
        let range: ClosedRange<Date> = {
            // Constrain the endpoint so the selection stays valid.
            let distantPast = Date(timeIntervalSince1970: 0)
            let distantFuture = Date(timeIntervalSinceNow: 10 * 365 * 24 * 3600)
            switch endpoint {
            case .from: return distantPast...endDate
            case .to:   return startDate...distantFuture
            }
        }()
        NavigationStack {
            VStack(spacing: 12) {
                // Custom calendar so the month/year header isn't tappable —
                // SwiftUI's `DatePicker(.graphical)` lets the user collapse
                // the grid into a year picker, which is what the user asked
                // us to disable.
                MonthCalendarView(selection: binding, in: range)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 14)
                Spacer()
            }
            .padding(.top, 12)
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { editing = nil }
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .principal) {
                    Text(endpoint == .from ? "Edit FROM" : "Edit TO")
                        .font(.headline)
                        .foregroundColor(theme.text1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { editing = nil }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Status row

    private var statusRow: some View {
        HStack(alignment: .firstTextBaseline) {
            (
                Text("\(formattedNumber(matchedCount))")
                    .font(theme.monoFont(15, weight: .bold))
                    .foregroundColor(theme.text1) +
                Text(" entries match")
                    .font(theme.monoFont(12))
                    .foregroundColor(theme.text3)
            )
            Spacer()
            Text(durationLabel)
                .font(theme.monoFont(12))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 2)
    }

    private var matchedCount: Int {
        entries.lazy.filter { (startDate...endDate).contains($0.timestamp) }.count
    }

    private var durationLabel: String {
        let secs = max(0, endDate.timeIntervalSince(startDate))
        if secs < 60 { return "\(Int(secs))s" }
        if secs < 3600 { return "\(Int(secs / 60))m" }
        if secs < 86_400 { return "\(Int(secs / 3600))h" }
        let days = secs / 86_400
        if days < 1.5 { return "1 day" }
        return "\(Int(days.rounded())) days"
    }

    private func formattedNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Date tiles row

    private var dateTilesRow: some View {
        HStack(spacing: 10) {
            dateTile(label: "FROM", date: startDate, endpoint: .from)
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(theme.text3)
            dateTile(label: "TO", date: endDate, endpoint: .to)
        }
    }

    private func dateTile(label: String, date: Date, endpoint: Endpoint) -> some View {
        Button {
            editing = endpoint
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(theme.monoFont(9.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(theme.text3)
                Text(Self.dayMonthFormatter.string(from: date))
                    .font(theme.monoFont(18, weight: .bold))
                    .foregroundColor(theme.text1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 70)
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(editing == endpoint ? theme.accent : theme.accentBd,
                            lineWidth: editing == endpoint ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Histogram

    private var histogramSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PAST \(Self.histogramDays) DAYS")
                    .font(theme.monoFont(10, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(theme.text3)
                Spacer()
                Text("BY SEVERITY · LOG VOLUME")
                    .font(theme.monoFont(9.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(theme.text3)
            }
            HistogramView(
                buckets: histogramBuckets,
                rangeStartIndex: Binding(
                    get: { rangeStartIndex },
                    set: { newIndex in
                        startDate = date(forBucketIndex: newIndex, endOfDay: false)
                    }
                ),
                rangeEndIndex: Binding(
                    get: { rangeEndIndex },
                    set: { newIndex in
                        endDate = date(forBucketIndex: newIndex, endOfDay: true)
                    }
                )
            )
            .frame(height: 130)

            HStack {
                Text(Self.shortMonthDay.string(from: histogramStartOfDay))
                    .font(theme.monoFont(9.5))
                    .foregroundColor(theme.text4)
                Spacer()
                Text(Self.shortMonthDay.string(from: Date()))
                    .font(theme.monoFont(9.5))
                    .foregroundColor(theme.text4)
            }
            legend
        }
        .padding(12)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendSwatch(color: theme.severity[.debug]!.fg, label: "debug")
            legendSwatch(color: theme.severity[.info]!.fg, label: "info")
            legendSwatch(color: theme.severity[.warning]!.fg, label: "warn")
            legendSwatch(color: theme.severity[.error]!.fg, label: "error")
            Spacer()
        }
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(theme.monoFont(10))
                .foregroundColor(theme.text2)
        }
    }

    // MARK: - Histogram data

    private var histogramStartOfDay: Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: -(Self.histogramDays - 1), to: start) ?? start
    }

    private var histogramBuckets: [HistogramBucket] {
        let cal = Calendar.current
        let startOfWindow = histogramStartOfDay
        var buckets: [HistogramBucket] = (0..<Self.histogramDays).map { _ in HistogramBucket.empty }
        for entry in entries {
            let dayStart = cal.startOfDay(for: entry.timestamp)
            let offset = cal.dateComponents([.day], from: startOfWindow, to: dayStart).day ?? -1
            guard offset >= 0, offset < Self.histogramDays else { continue }
            buckets[offset].add(entry.level)
        }
        return buckets
    }

    private var rangeStartIndex: Int {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: startDate)
        let offset = cal.dateComponents([.day], from: histogramStartOfDay, to: dayStart).day ?? 0
        return max(0, min(Self.histogramDays - 1, offset))
    }

    private var rangeEndIndex: Int {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: endDate)
        let offset = cal.dateComponents([.day], from: histogramStartOfDay, to: dayStart).day ?? 0
        return max(0, min(Self.histogramDays - 1, offset))
    }

    /// Converts a histogram bucket index back to a date. `endOfDay=false`
    /// returns midnight (start of that day); `endOfDay=true` returns the
    /// last instant of that day. Used by the histogram drag handles to
    /// translate finger position → startDate/endDate.
    private func date(forBucketIndex index: Int, endOfDay: Bool) -> Date {
        let cal = Calendar.current
        let clamped = max(0, min(Self.histogramDays - 1, index))
        let dayStart = cal.date(byAdding: .day, value: clamped, to: histogramStartOfDay) ?? histogramStartOfDay
        if endOfDay {
            return cal.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) ?? dayStart
        }
        return dayStart
    }

    // MARK: - Presets

    private var presetsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                preset("Today",  days: 0)
                preset("24h",    days: 1)
                preset("3d",     days: 3)
                preset("7d",     days: 7)
                preset("14d",    days: 14)
                preset("30d",    days: 30)
            }
            .padding(.horizontal, 2)
        }
    }

    private func preset(_ label: String, days: Int) -> some View {
        Button(action: {
            endDate = Date()
            startDate = days == 0
                ? Calendar.current.startOfDay(for: Date())
                : Date().addingTimeInterval(TimeInterval(-days * 24 * 3600))
        }) {
            Text(label)
                .font(theme.monoFont(12, weight: .semibold))
                .foregroundColor(theme.text1)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Clear

    private var clearButton: some View {
        Button(action: {
            filter.dateRange = nil
            dismiss()
        }) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                Text("Clear date range")
                    .font(theme.sansFont(13, weight: .semibold))
                Spacer()
            }
            .foregroundColor(theme.danger)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(theme.danger.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.danger.opacity(0.28), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Formatters

    static let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let shortMonthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Histogram primitives

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

/// Interactive bar chart with two draggable range markers (the circles +
/// vertical rods from the design). Each bar stacks per-severity sub-bars
/// from most-severe at the top. Bars outside the selected range are dimmed.
///
/// **Interaction model**
///
/// `DragGesture(minimumDistance: 0)` covers the whole chart. On first touch
/// we pick the marker (start or end) closer to the finger and lock it as
/// the "active handle" for the gesture. Subsequent movement snaps to the
/// nearest day boundary; the active handle's binding updates and the
/// parent's date follows.
///
/// A tap (zero-movement drag) snaps the closer marker to the touched day —
/// handy for quickly jumping to one end of the range.
struct HistogramView: View {
    let buckets: [HistogramBucket]
    @Binding var rangeStartIndex: Int
    @Binding var rangeEndIndex: Int

    @Environment(\.forgeTheme) private var theme
    @State private var activeHandle: Handle?
    @State private var lastSnappedIndex: Int = -1

    enum Handle: Equatable { case start, end }

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

                // Baseline
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

    // MARK: - Bar

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

    // MARK: - Marker

    private func rangeMarker(at index: Int, handle: Handle, barWidth: CGFloat, gap: CGFloat, height: CGFloat) -> some View {
        let x = CGFloat(index) * (barWidth + gap) + barWidth / 2
        let isActive = activeHandle == handle
        let circleSize: CGFloat = isActive ? 18 : 14
        return ZStack {
            // Vertical rod
            Rectangle()
                .fill(theme.accent.opacity(isActive ? 1.0 : 0.85))
                .frame(width: isActive ? 3 : 2, height: height)
                .position(x: x, y: height / 2)
            // Top circle
            Circle()
                .fill(theme.accent)
                .frame(width: circleSize, height: circleSize)
                .overlay(Circle().stroke(theme.bg, lineWidth: 2))
                .shadow(color: isActive ? theme.accent.opacity(0.4) : .clear, radius: isActive ? 4 : 0)
                .position(x: x, y: circleSize / 2)
            // Bottom circle
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

    // MARK: - Drag

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

    /// Pick the handle (start or end) closer to the initial touch x.
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
                lastSnappedIndex = clamped + 1_000   // distinct trigger from start
            }
        case .none:
            break
        }
    }
}
#endif
