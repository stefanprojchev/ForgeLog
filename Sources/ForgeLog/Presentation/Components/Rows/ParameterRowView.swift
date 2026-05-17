#if os(iOS) || os(visionOS)
import SwiftUI

/// Single key/value row used by both `ParametersSectionView` and inside the
/// Swift Error's `userInfo` table. Long keys switch to a stacked layout so
/// localized descriptions don't overflow.
struct ParameterRowView: View {
    let key: String
    let value: AnyCodableValue
    let isLast: Bool
    @Environment(\.forgeTheme) private var theme

    private var valueColor: Color {
        switch value.kind {
        case .null:                       return theme.text3
        case .bool:                       return theme.severity[.warning]!.fg
        case .number:                     return theme.severity[.info]!.fg
        case .string, .array, .dictionary:return theme.text1
        }
    }

    private var isLongKey: Bool { key.count > 14 }
    private var isLongString: Bool {
        if case .string(let s) = value, s.count > 32 { return true }
        return false
    }

    var body: some View {
        Group {
            if isLongKey {
                stackedLayout
            } else {
                inlineLayout
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(theme.border).frame(height: 0.5)
            }
        }
    }

    private var inlineLayout: some View {
        HStack(alignment: isLongString ? .top : .center, spacing: 10) {
            Text(key)
                .font(theme.monoFont(11))
                .foregroundColor(theme.text3)
                .frame(width: 92, alignment: .leading)
            Text(value.display)
                .font(theme.monoFont(12))
                .foregroundColor(valueColor)
                .lineLimit(isLongString ? nil : 1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "doc.on.doc")
                .font(.system(size: 12))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var stackedLayout: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
                    .multilineTextAlignment(.leading)
                Text(value.display)
                    .font(theme.monoFont(12))
                    .foregroundColor(valueColor)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "doc.on.doc")
                .font(.system(size: 12))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}
#endif
