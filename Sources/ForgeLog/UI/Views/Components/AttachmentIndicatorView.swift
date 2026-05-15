#if os(iOS) || os(visionOS)
import SwiftUI

/// Tiny chips at the end of each row's meta line indicating attached data:
/// `{·} N` for params, `NSError` for Swift errors.
struct AttachmentIndicatorView: View {
    let entry: LogEntry
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 3) {
            if let params = entry.paramsMetadata, !params.isEmpty {
                paramsChip(count: params.count)
            }
            if entry.loggedError != nil {
                errorChip
            }
        }
    }

    private func paramsChip(count: Int) -> some View {
        HStack(spacing: 2) {
            Text("{·}").opacity(0.7)
            Text("\(count)")
        }
        .font(theme.monoFont(9.5, weight: .bold))
        .tracking(0.2)
        .foregroundColor(theme.text2)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(theme.mode == .light
                    ? Color.black.opacity(0.05)
                    : Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(theme.border, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var errorChip: some View {
        let err = theme.severity[.error]!
        return Text("NSError")
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundColor(err.fg)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(err.bg)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(err.bd, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
#endif
