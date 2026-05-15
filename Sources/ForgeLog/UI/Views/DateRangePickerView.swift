#if os(iOS) || os(visionOS)
import SwiftUI

/// Date range picker. Quick presets up top, then two full graphical calendars
/// (From / To) in themed cards. The graphical style is far easier to read
/// than the compact pill from the handoff.
struct DateRangePickerView: View {
    @Binding var filter: FilterState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    @State private var startDate: Date
    @State private var endDate: Date

    init(filter: Binding<FilterState>) {
        _filter = filter
        let now = Date()
        let initialStart = filter.wrappedValue.dateRange?.lowerBound
            ?? Calendar.current.date(byAdding: .day, value: -7, to: now)
            ?? now
        let initialEnd = filter.wrappedValue.dateRange?.upperBound ?? now
        _startDate = State(initialValue: initialStart)
        _endDate = State(initialValue: initialEnd)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    presetsRow
                    section(title: "FROM",
                            badge: dayFormatter.string(from: startDate)) {
                        DatePicker("From", selection: $startDate,
                                   in: ...endDate,
                                   displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(theme.accent)
                    }
                    section(title: "TO",
                            badge: dayFormatter.string(from: endDate)) {
                        DatePicker("To", selection: $endDate,
                                   in: startDate...,
                                   displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(theme.accent)
                    }
                    if filter.dateRange != nil {
                        clearButton
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
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
        }
    }

    // MARK: - Presets

    private var presetsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                preset("Today",  days: 0)
                preset("24h",    days: 1)
                preset("3d",     days: 3)
                preset("7d",     days: 7)
                preset("30d",    days: 30)
                preset("90d",    days: 90)
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
                .font(theme.monoFont(11.5, weight: .semibold))
                .foregroundColor(theme.text1)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section

    @ViewBuilder
    private func section<Content: View>(title: String, badge: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(theme.monoFont(9.5, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(theme.text3)
                Spacer()
                Text(badge)
                    .font(theme.monoFont(11, weight: .semibold))
                    .foregroundColor(theme.text1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.accentBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(theme.accentBd, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            content()
                .padding(8)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }
}
#endif
