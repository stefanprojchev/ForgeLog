#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class DateRangePickerViewModel {
    // MARK: - Input & State

    let input: DateRangePickerContent.Input
    var state = DateRangePickerContent.State.default

    // MARK: - Init

    init(input: DateRangePickerContent.Input) {
        self.input = input
        let now = Date()
        self.state.startDate = input.initialRange?.lowerBound
            ?? Calendar.current.date(byAdding: .day, value: -3, to: now)
            ?? now
        self.state.endDate = input.initialRange?.upperBound ?? now
    }

    // MARK: - Derived

    var matchedCount: Int {
        let range = state.startDate...state.endDate
        return input.entries.lazy.filter { range.contains($0.timestamp) }.count
    }

    var durationLabel: String {
        let secs = max(0, state.endDate.timeIntervalSince(state.startDate))
        if secs < 60 { return "\(Int(secs))s" }
        if secs < 3600 { return "\(Int(secs / 60))m" }
        if secs < 86_400 { return "\(Int(secs / 3600))h" }
        let days = secs / 86_400
        if days < 1.5 { return "1 day" }
        return "\(Int(days.rounded())) days"
    }

    var hasActiveRange: Bool { input.initialRange != nil }

    var histogramStartOfDay: Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: -(DateRangePickerContent.histogramDays - 1), to: start) ?? start
    }

    var histogramBuckets: [HistogramBucket] {
        let cal = Calendar.current
        let startOfWindow = histogramStartOfDay
        var buckets: [HistogramBucket] = (0..<DateRangePickerContent.histogramDays).map { _ in HistogramBucket.empty }
        for entry in input.entries {
            let dayStart = cal.startOfDay(for: entry.timestamp)
            let offset = cal.dateComponents([.day], from: startOfWindow, to: dayStart).day ?? -1
            guard offset >= 0, offset < DateRangePickerContent.histogramDays else { continue }
            buckets[offset].add(entry.level)
        }
        return buckets
    }

    var rangeStartIndex: Int {
        bucketIndex(for: state.startDate)
    }

    var rangeEndIndex: Int {
        bucketIndex(for: state.endDate)
    }

    // MARK: - Intents

    func setEditing(_ endpoint: DateRangePickerContent.Endpoint?) {
        state.editing = endpoint
    }

    func setStartDate(_ date: Date) {
        state.startDate = normalize(date, endpoint: .from)
    }

    func setEndDate(_ date: Date) {
        state.endDate = normalize(date, endpoint: .to)
    }

    func setStartIndex(_ index: Int) {
        state.startDate = date(forBucketIndex: index, endOfDay: false)
    }

    func setEndIndex(_ index: Int) {
        state.endDate = date(forBucketIndex: index, endOfDay: true)
    }

    func applyPreset(days: Int) {
        state.endDate = Date()
        state.startDate = days == 0
            ? Calendar.current.startOfDay(for: Date())
            : Date().addingTimeInterval(TimeInterval(-days * 24 * 3600))
    }

    func confirm() {
        input.onApply(state.startDate...state.endDate)
        input.router.dismissSheet()
    }

    func clear() {
        input.onApply(nil)
        input.router.dismissSheet()
    }

    func cancel() {
        input.router.dismissSheet()
    }

    // MARK: - Private

    private func bucketIndex(for date: Date) -> Int {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let offset = cal.dateComponents([.day], from: histogramStartOfDay, to: dayStart).day ?? 0
        return max(0, min(DateRangePickerContent.histogramDays - 1, offset))
    }

    private func date(forBucketIndex index: Int, endOfDay: Bool) -> Date {
        let cal = Calendar.current
        let clamped = max(0, min(DateRangePickerContent.histogramDays - 1, index))
        let dayStart = cal.date(byAdding: .day, value: clamped, to: histogramStartOfDay) ?? histogramStartOfDay
        if endOfDay {
            return cal.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) ?? dayStart
        }
        return dayStart
    }

    private func normalize(_ date: Date, endpoint: DateRangePickerContent.Endpoint) -> Date {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        switch endpoint {
        case .from: return dayStart
        case .to:   return cal.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) ?? date
        }
    }
}
#endif
