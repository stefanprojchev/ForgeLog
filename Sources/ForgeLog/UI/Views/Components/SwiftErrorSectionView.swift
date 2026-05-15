#if os(iOS) || os(visionOS)
import SwiftUI

struct SwiftErrorSectionView: View {
    let error: LoggedError
    @Environment(\.forgeTheme) private var theme

    private var severity: ForgeLogTheme.Severity { theme.severity[.error]! }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            VStack(spacing: 0) {
                domainHeader
                description
                if !error.userInfo.isEmpty { userInfoSection }
            }
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(severity.bd, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("NSError")
                .font(theme.monoFont(9, weight: .bold))
                .tracking(0.5)
                .foregroundColor(severity.fg)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(severity.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(severity.bd, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Text("SWIFT ERROR")
                .font(theme.monoFont(9.5, weight: .bold))
                .tracking(0.7)
                .foregroundColor(theme.text3)
            Spacer()
            Button(action: copyAll) {
                Text("copy")
                    .font(theme.monoFont(10, weight: .semibold))
                    .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var domainHeader: some View {
        HStack(spacing: 8) {
            Text(error.domain)
                .font(theme.monoFont(12, weight: .bold))
                .foregroundColor(severity.fg)
            Spacer()
            Text("CODE")
                .font(theme.monoFont(10, weight: .bold))
                .tracking(0.4)
                .foregroundColor(theme.text3)
            Text("\(error.code)")
                .font(theme.monoFont(12, weight: .bold))
                .foregroundColor(theme.text1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(severity.bg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(severity.bd).frame(height: 0.5)
        }
    }

    private var description: some View {
        Text(error.description)
            .font(theme.monoFont(12.5))
            .foregroundColor(theme.text1)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                if !error.userInfo.isEmpty {
                    Rectangle().fill(theme.border).frame(height: 0.5)
                }
            }
    }

    private var userInfoSection: some View {
        let sorted = error.userInfo.map { (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
        return VStack(alignment: .leading, spacing: 0) {
            Text("USERINFO · \(error.userInfo.count)")
                .font(theme.monoFont(9.5, weight: .bold))
                .tracking(0.5)
                .foregroundColor(theme.text3)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
            ForEach(Array(sorted.enumerated()), id: \.element.key) { idx, kv in
                ParameterRowView(key: kv.key, value: kv.value, isLast: idx == sorted.count - 1)
            }
        }
        .background(theme.bgAlt)
    }

    private func copyAll() {
        var out = "\(error.domain) (code \(error.code))\n\(error.description)\n"
        for (k, v) in error.userInfo.sorted(by: { $0.key < $1.key }) {
            out += "\(k) = \(v.display)\n"
        }
        #if canImport(UIKit)
        UIPasteboard.general.string = out
        #endif
    }
}
#endif
