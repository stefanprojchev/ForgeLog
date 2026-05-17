#if os(iOS) || os(visionOS)
import SwiftUI

struct LogConceptsView: View {
    // MARK: - Properties

    @Bindable var viewModel: LogConceptsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    introBlock
                    ForEach(Array(LogConceptsContent.concepts.enumerated()), id: \.offset) { idx, c in
                        conceptCard(idx: idx, concept: c)
                    }
                }
                .padding(14)
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LogConceptsContent.navTitle)
                        .font(.headline)
                        .foregroundColor(theme.text1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var introBlock: some View {
        Text(LogConceptsContent.intro)
            .font(theme.sansFont(14))
            .foregroundColor(theme.text2)
            .lineSpacing(4)
            .padding(.bottom, 6)
    }

    // MARK: - Components

    private func conceptCard(idx: Int, concept: LogConceptsContent.Concept) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(idx + 1)")
                    .font(theme.monoFont(11, weight: .bold))
                    .foregroundColor(theme.accent)
                    .frame(width: 22, height: 22)
                    .background(theme.accentBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(theme.accentBd, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(concept.title)
                    .font(theme.sansFont(16, weight: .bold))
                    .foregroundColor(theme.text1)
            }
            Text(concept.blurb)
                .font(theme.sansFont(13))
                .foregroundColor(theme.text2)
                .lineSpacing(4)
            Text(concept.example)
                .font(theme.sansFont(12))
                .foregroundColor(theme.text3)
                .lineSpacing(3)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.bgAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
#endif
