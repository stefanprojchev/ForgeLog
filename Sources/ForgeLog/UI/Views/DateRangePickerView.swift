#if os(iOS) || os(visionOS)
import SwiftUI

/// Date range picker with quick presets.
struct DateRangePickerView: View {
    @Binding var filter: FilterState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    @State private var startDate: Date = Date().addingTimeInterval(-3 * 24 * 3600)
    @State private var endDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                quickPresets
                HStack(spacing: 8) {
                    DatePicker("From", selection: $startDate, in: ...endDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    Text("→").foregroundColor(theme.text3)
                    DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .padding(.horizontal, 12)
                Spacer()
            }
            .padding(.top, 10)
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Date range").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        filter.dateRange = startDate...endDate
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var quickPresets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                preset("Today", days: 0)
                preset("24h", days: 1)
                preset("3d", days: 3)
                preset("7d", days: 7)
                preset("30d", days: 30)
            }
            .padding(.horizontal, 12)
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
                .foregroundColor(theme.text2)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(theme.surfaceHi)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
#endif
