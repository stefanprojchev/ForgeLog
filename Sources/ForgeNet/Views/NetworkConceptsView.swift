#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

struct NetworkConceptsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    private struct Concept {
        let title: String
        let blurb: String
    }

    private let concepts: [Concept] = [
        .init(title: "Method",
              blurb: "The HTTP verb. Color hints at the verb family — GET (read) info-blue, POST (create) success-green, PUT/PATCH (update) amber, DELETE error-red."),
        .init(title: "Status",
              blurb: "HTTP status code, grouped into 2xx success, 3xx redirect, 4xx client error, 5xx server error. Network failures (no status) appear as red FAILED."),
        .init(title: "Caller",
              blurb: "The module + class + function that issued the request. Pass a `Caller` through your networking layer to populate this; otherwise \"Called from\" shows \"—\"."),
        .init(title: "Edge cases",
              blurb: "Redirect chains, gzip-compressed responses, image bodies, and SSE streams are flagged inline on the row and expanded into purpose-built views in detail."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ForgeNet captures every URLSession request its instrumentation sees. Tap any field to filter the stream.")
                        .font(theme.sansFont(14))
                        .foregroundColor(theme.text2)
                        .lineSpacing(4)
                        .padding(.bottom, 6)

                    ForEach(Array(concepts.enumerated()), id: \.offset) { i, c in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text("\(i + 1)")
                                    .font(theme.monoFont(11, weight: .bold))
                                    .foregroundColor(theme.accent)
                                    .frame(width: 22, height: 22)
                                    .background(theme.accentBg)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.accentBd, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text(c.title)
                                    .font(theme.sansFont(16, weight: .bold))
                                    .foregroundColor(theme.text1)
                            }
                            Text(c.blurb)
                                .font(theme.sansFont(13))
                                .foregroundColor(theme.text2)
                                .lineSpacing(4)
                        }
                        .padding(14)
                        .background(theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(14)
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Network Concepts")
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
}
#endif
