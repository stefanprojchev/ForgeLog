#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

/// Per-status-family counts — explicit named fields so the cards row can
/// never silently mis-key (same lesson as `LevelCounts` in ForgeLog).
struct StatusFamilyCounts: Equatable {
    var all: Int
    var success: Int
    var redirect: Int
    var clientError: Int
    var serverError: Int
    var failed: Int

    static let zero = StatusFamilyCounts(all: 0, success: 0, redirect: 0,
                                          clientError: 0, serverError: 0, failed: 0)

    static func compute(from entries: [NetworkLogEntry]) -> StatusFamilyCounts {
        var success = 0, redirect = 0, client = 0, server = 0, failed = 0
        for entry in entries {
            switch entry.statusFamily {
            case .success, .informational: success += 1
            case .redirect:                redirect += 1
            case .clientError:             client += 1
            case .serverError:             server += 1
            case .failed:                  failed += 1
            }
        }
        return StatusFamilyCounts(
            all: entries.count,
            success: success,
            redirect: redirect,
            clientError: client,
            serverError: server,
            failed: failed
        )
    }
}

/// Row of 6 cards: All / 2xx / 3xx / 4xx / 5xx / Failed.
struct StatusFamilyCardsView: View {
    @Binding var selected: HTTPStatusFamily?
    let counts: StatusFamilyCounts
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            cell(label: "All",    family: nil,           count: counts.all,         color: theme.allSeverity)
            cell(label: "2xx",    family: .success,      count: counts.success,     color: theme.severity[.info]!)
            cell(label: "3xx",    family: .redirect,     count: counts.redirect,    color: theme.severity[.debug]!)
            cell(label: "4xx",    family: .clientError,  count: counts.clientError, color: theme.severity[.warning]!)
            cell(label: "5xx",    family: .serverError,  count: counts.serverError, color: theme.severity[.error]!)
            cell(label: "Failed", family: .failed,       count: counts.failed,      color: theme.severity[.error]!)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(theme.bg)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    private func cell(label: String, family: HTTPStatusFamily?, count: Int, color: ForgeLogTheme.Severity) -> some View {
        let isActive = selected == family
        return Button(action: { selected = isActive ? nil : family }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(theme.monoFont(8.5, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(color.fg)
                Text("\(count)")
                    .font(theme.monoFont(13, weight: .semibold))
                    .foregroundColor(theme.text1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(isActive ? color.bg : theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? color.bd : theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
#endif
