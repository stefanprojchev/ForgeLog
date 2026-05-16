#if os(iOS) || os(visionOS)
import SwiftUI

/// Themed single-month calendar — header with month + year + prev/next
/// chevrons, weekday labels, day grid. Used in place of SwiftUI's
/// `DatePicker(.graphical)` so the month/year header can't be tapped to
/// expand into a year picker (SwiftUI has no public knob for that).
struct MonthCalendarView: View {
    @Binding var selection: Date
    let range: ClosedRange<Date>
    @Environment(\.forgeTheme) private var theme

    @State private var displayedMonth: Date
    private let calendar: Calendar

    init(selection: Binding<Date>, in range: ClosedRange<Date>) {
        self._selection = selection
        self.range = range
        let cal = Calendar.current
        self.calendar = cal
        let comps = cal.dateComponents([.year, .month], from: selection.wrappedValue)
        let monthStart = cal.date(from: comps) ?? selection.wrappedValue
        self._displayedMonth = State(initialValue: monthStart)
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            VStack(spacing: 8) {
                weekdayLabels
                daysGrid
            }
        }
        .padding(.vertical, 4)
        .onChange(of: selection) {
            // Keep the displayed month in sync with selection if it lands in
            // another month (preset taps, programmatic changes).
            let target = calendar.date(from: calendar.dateComponents([.year, .month], from: selection))!
            if target != displayedMonth {
                withAnimation(.easeOut(duration: 0.18)) {
                    displayedMonth = target
                }
            }
        }
    }

    // MARK: - Header

    /// Header shows two tappable menus (month and year) for fast jumping plus
    /// prev/next chevrons for one-step navigation. The menus are SwiftUI
    /// `Menu`s (not the SwiftUI DatePicker "tap-to-expand" behavior) — the
    /// calendar grid stays visible, only a dropdown overlays.
    private var header: some View {
        HStack(spacing: 6) {
            monthMenu
            yearMenu
            Spacer()
            chevronButton(systemName: "chevron.left",
                          enabled: canGoPrevious,
                          action: { navigate(by: -1) })
            chevronButton(systemName: "chevron.right",
                          enabled: canGoNext,
                          action: { navigate(by: 1) })
        }
        .padding(.horizontal, 4)
    }

    private var monthMenu: some View {
        Menu {
            Picker("Month", selection: monthSelectionBinding) {
                ForEach(1...12, id: \.self) { month in
                    Text(Self.monthFormatter.standaloneMonthSymbols[month - 1])
                        .tag(month)
                }
            }
        } label: {
            menuLabel(text: Self.monthFormatter.standaloneMonthSymbols[currentMonth - 1])
        }
    }

    private var yearMenu: some View {
        Menu {
            Picker("Year", selection: yearSelectionBinding) {
                ForEach(yearOptions, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
        } label: {
            menuLabel(text: String(currentYear))
        }
    }

    private func menuLabel(text: String) -> some View {
        HStack(spacing: 3) {
            Text(text)
                .font(theme.sansFont(17, weight: .bold))
                .foregroundColor(theme.text1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(theme.surfaceHi)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func chevronButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(enabled ? theme.accent : theme.text4)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }

    // MARK: - Menu bindings

    private var monthSelectionBinding: Binding<Int> {
        Binding(
            get: { currentMonth },
            set: { newMonth in jump(month: newMonth, year: currentYear) }
        )
    }

    private var yearSelectionBinding: Binding<Int> {
        Binding(
            get: { currentYear },
            set: { newYear in jump(month: currentMonth, year: newYear) }
        )
    }

    private var currentMonth: Int { calendar.component(.month, from: displayedMonth) }
    private var currentYear: Int  { calendar.component(.year,  from: displayedMonth) }

    /// Years offered by the year menu — bounded by `range` and clipped to a
    /// reasonable window (±10y around the displayed year) so we don't render
    /// a list of decades for the full `distantPast…distantFuture` span.
    private var yearOptions: [Int] {
        let rangeStartYear = calendar.component(.year, from: range.lowerBound)
        let rangeEndYear   = calendar.component(.year, from: range.upperBound)
        let lower = max(rangeStartYear, currentYear - 10)
        let upper = min(rangeEndYear,   currentYear + 10)
        guard lower <= upper else { return [currentYear] }
        return Array(lower...upper)
    }

    /// Jumps the displayed month to a specific year+month, clamping the
    /// resulting month-first date to the allowed `range`.
    private func jump(month: Int, year: Int) {
        var target = calendar.date(from: DateComponents(year: year, month: month)) ?? displayedMonth
        if target < calendar.date(from: calendar.dateComponents([.year, .month], from: range.lowerBound))! {
            target = calendar.date(from: calendar.dateComponents([.year, .month], from: range.lowerBound))!
        }
        if target > calendar.date(from: calendar.dateComponents([.year, .month], from: range.upperBound))! {
            target = calendar.date(from: calendar.dateComponents([.year, .month], from: range.upperBound))!
        }
        guard target != displayedMonth else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            displayedMonth = target
        }
    }

    private static let monthFormatter: DateFormatter = DateFormatter()

    // MARK: - Weekday labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(theme.monoFont(10.5, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(theme.text3)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Days grid

    private var daysGrid: some View {
        let days = monthDays
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days.indices, id: \.self) { i in
                dayCell(days[i])
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date = date {
            let day = calendar.component(.day, from: date)
            let isInRange = range.contains(date)
            let isSelected = calendar.isDate(date, inSameDayAs: selection)
            let isToday = calendar.isDateInToday(date)

            Button {
                if isInRange {
                    withAnimation(.easeOut(duration: 0.12)) {
                        selection = date
                    }
                }
            } label: {
                Text("\(day)")
                    .font(theme.sansFont(15, weight: isSelected ? .bold : (isToday ? .semibold : .regular)))
                    .foregroundColor(textColor(isSelected: isSelected, isInRange: isInRange, isToday: isToday))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(isSelected ? theme.accent : Color.clear))
                    .overlay(
                        Circle()
                            .stroke(theme.accent, lineWidth: (isToday && !isSelected) ? 1 : 0)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!isInRange)
            .accessibilityLabel(Self.accessibilityFormatter.string(from: date))
        } else {
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func textColor(isSelected: Bool, isInRange: Bool, isToday: Bool) -> Color {
        if isSelected { return theme.mode == .light ? .white : Color(hex: "#0B0B0E") }
        if !isInRange { return theme.text4 }
        if isToday { return theme.accent }
        return theme.text1
    }

    // MARK: - Navigation

    private var canGoPrevious: Bool {
        // We can go back as long as the last day of the previous month is
        // within the allowed range.
        guard
            let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: displayedMonth),
            let prevMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: prevMonthStart)
        else { return false }
        return prevMonthEnd >= range.lowerBound
    }

    private var canGoNext: Bool {
        guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        return nextMonthStart <= range.upperBound
    }

    private func navigate(by months: Int) {
        guard let new = calendar.date(byAdding: .month, value: months, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            displayedMonth = new
        }
    }

    // MARK: - Calendar math

    private var monthYearString: String {
        Self.headerFormatter.string(from: displayedMonth)
    }

    /// Locale-respecting short weekday labels, rotated so the calendar's
    /// `firstWeekday` is the leftmost column.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1   // 0-indexed
        return Array(symbols[first..<symbols.count]) + Array(symbols[0..<first])
    }

    /// Days of the displayed month padded with `nil`s so the grid aligns to
    /// the calendar's `firstWeekday`. Trailing `nil`s fill the last row.
    private var monthDays: [Date?] {
        let monthFirst = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let range = calendar.range(of: .day, in: .month, for: monthFirst)!
        let firstWeekday = calendar.firstWeekday
        let monthFirstWeekday = calendar.component(.weekday, from: monthFirst)
        let leading = (monthFirstWeekday - firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthFirst) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    // MARK: - Formatters

    private static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
}
#endif
