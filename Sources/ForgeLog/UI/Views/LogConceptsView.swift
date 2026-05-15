#if os(iOS) || os(visionOS)
import SwiftUI

struct LogConceptsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    private struct Concept {
        let title: String
        let blurb: String
        let example: String
    }

    private let concepts: [Concept] = [
        .init(
            title: "Module",
            blurb: "The Swift module (or SPM package) that produced the log entry. Extracted automatically from the source file path at the call site.",
            example: "A log in NetworkKit will show NetworkKit as the module. Filter by module to isolate logs from one package."
        ),
        .init(
            title: "Class",
            blurb: "The Swift file name where the log call was made, without the .swift extension. Despite the name, this is the file rather than a specific class.",
            example: "A log in FeedViewModel.swift shows FeedViewModel as the class. Filter by class to see all logs originating from one file."
        ),
        .init(
            title: "Process",
            blurb: "One or more labels you can attach to a log call to group related operations. A single log can belong to multiple processes. Processes are user-defined.",
            example: "A log about importing Instagram media might be tagged with both #Import and #Instagram. Filter by either and the entry will appear."
        ),
        .init(
            title: "Level",
            blurb: "Severity of the log entry. From lowest to highest: Debug, Info, Warning, Error. Each provider sets a minimum level to control which entries it receives.",
            example: "Use Debug for diagnostics, Info for general events, Warning for recoverable issues, Error for failures."
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ForgeLog organizes every entry by four dimensions. Tap any of these to filter the live log stream.")
                        .font(theme.sansFont(14))
                        .foregroundColor(theme.text2)
                        .lineSpacing(4)
                        .padding(.bottom, 6)

                    ForEach(Array(concepts.enumerated()), id: \.offset) { idx, c in
                        conceptCard(idx: idx, concept: c)
                    }
                }
                .padding(14)
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Log Concepts").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func conceptCard(idx: Int, concept: Concept) -> some View {
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
