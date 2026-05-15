#if os(iOS) || os(visionOS)
import SwiftUI

struct ParametersSectionView: View {
    let params: [String: AnyCodableValue]
    @Environment(\.forgeTheme) private var theme
    @State private var didCopy = false

    private var sortedEntries: [(key: String, value: AnyCodableValue)] {
        params.map { (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            VStack(spacing: 0) {
                ForEach(Array(sortedEntries.enumerated()), id: \.element.key) { idx, kv in
                    ParameterRowView(key: kv.key,
                                     value: kv.value,
                                     isLast: idx == sortedEntries.count - 1)
                }
            }
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("{·}")
                .font(theme.monoFont(10))
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
            Text("PARAMETERS · \(params.count)")
                .font(theme.monoFont(9.5, weight: .bold))
                .tracking(0.7)
                .foregroundColor(theme.text3)
            Spacer()
            Button(action: copyAll) {
                HStack(spacing: 3) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                    Text(didCopy ? "copied" : "copy all")
                        .font(theme.monoFont(10, weight: .semibold))
                }
                .foregroundColor(didCopy ? theme.success : theme.accent)
                .animation(.easeOut(duration: 0.18), value: didCopy)
            }
            .buttonStyle(.plain)
        }
    }

    private func copyAll() {
        let lines = sortedEntries.map { "\($0.key) = \($0.value.display)" }
        #if canImport(UIKit)
        UIPasteboard.general.string = lines.joined(separator: "\n")
        #endif
        withAnimation(.easeOut(duration: 0.18)) { didCopy = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeIn(duration: 0.18)) { didCopy = false }
        }
    }
}
#endif
