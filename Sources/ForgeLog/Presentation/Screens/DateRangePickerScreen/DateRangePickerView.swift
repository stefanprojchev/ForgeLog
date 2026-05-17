#if os(iOS) || os(visionOS)
import SwiftUI

/// Date range picker — status row, FROM → TO tile pair, 30-day histogram
/// colored by severity with markers for the selected range, preset chips.
struct DateRangePickerView: View {
    // MARK: - Properties

    @Bindable var viewModel: DateRangePickerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusRow
                    dateTilesRow
                    histogramSection
                    presetsRow
                    if viewModel.hasActiveRange {
                        clearButton
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar { toolbarContent }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: Binding(
                get: { viewModel.state.editing },
                set: { viewModel.setEditing($0) }
            )) { endpoint in
                endpointEditor(for: endpoint)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Sections

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { viewModel.cancel() }
                .foregroundColor(theme.accent)
        }
        ToolbarItem(placement: .principal) {
            Text("Date range")
                .font(.headline)
                .foregroundColor(theme.text1)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") { viewModel.confirm() }
                .fontWeight(.semibold)
                .foregroundColor(theme.accent)
        }
    }

    private var statusRow: some View {
        HStack(alignment: .firstTextBaseline) {
            (
                Text("\(formattedNumber(viewModel.matchedCount))")
                    .font(theme.monoFont(15, weight: .bold))
                    .foregroundColor(theme.text1) +
                Text(" entries match")
                    .font(theme.monoFont(12))
                    .foregroundColor(theme.text3)
            )
            Spacer()
            Text(viewModel.durationLabel)
                .font(theme.monoFont(12))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 2)
    }

    private var dateTilesRow: some View {
        HStack(spacing: 10) {
            dateTile(label: "FROM", date: viewModel.state.startDate, endpoint: .from)
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(theme.text3)
            dateTile(label: "TO", date: viewModel.state.endDate, endpoint: .to)
        }
    }

    private var histogramSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PAST \(DateRangePickerContent.histogramDays) DAYS")
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
                buckets: viewModel.histogramBuckets,
                rangeStartIndex: Binding(
                    get: { viewModel.rangeStartIndex },
                    set: { viewModel.setStartIndex($0) }
                ),
                rangeEndIndex: Binding(
                    get: { viewModel.rangeEndIndex },
                    set: { viewModel.setEndIndex($0) }
                )
            )
            .frame(height: 130)

            HStack {
                Text(Self.shortMonthDay.string(from: viewModel.histogramStartOfDay))
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

    private var presetsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                preset("Today", days: 0)
                preset("24h",   days: 1)
                preset("3d",    days: 3)
                preset("7d",    days: 7)
                preset("14d",   days: 14)
                preset("30d",   days: 30)
            }
            .padding(.horizontal, 2)
        }
    }

    private var clearButton: some View {
        Button(action: { viewModel.clear() }) {
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

    // MARK: - Components

    private func dateTile(label: String, date: Date, endpoint: DateRangePickerContent.Endpoint) -> some View {
        Button {
            viewModel.setEditing(endpoint)
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
                    .stroke(viewModel.state.editing == endpoint ? theme.accent : theme.accentBd,
                            lineWidth: viewModel.state.editing == endpoint ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private func preset(_ label: String, days: Int) -> some View {
        Button(action: { viewModel.applyPreset(days: days) }) {
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

    @ViewBuilder
    private func endpointEditor(for endpoint: DateRangePickerContent.Endpoint) -> some View {
        let binding = Binding<Date>(
            get: { endpoint == .from ? viewModel.state.startDate : viewModel.state.endDate },
            set: { newValue in
                if endpoint == .from { viewModel.setStartDate(newValue) } else { viewModel.setEndDate(newValue) }
            }
        )
        let range: ClosedRange<Date> = {
            let distantPast = Date(timeIntervalSince1970: 0)
            let distantFuture = Date(timeIntervalSinceNow: 10 * 365 * 24 * 3600)
            switch endpoint {
            case .from: return distantPast...viewModel.state.endDate
            case .to:   return viewModel.state.startDate...distantFuture
            }
        }()
        NavigationStack {
            VStack(spacing: 12) {
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
                    Button("Cancel") { viewModel.setEditing(nil) }
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .principal) {
                    Text(endpoint == .from ? "Edit FROM" : "Edit TO")
                        .font(.headline)
                        .foregroundColor(theme.text1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { viewModel.setEditing(nil) }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Private

    private func formattedNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

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
#endif
