#if os(iOS) || os(visionOS)
import SwiftUI

/// Settings — icon-tile rows in custom sections. Matches the Claude Design
/// "B · Icon tiles + summary header" mock. Functionality is unchanged from
/// the previous Form-based implementation; only the visuals.
struct SettingsView: View {
    @ObservedObject var store: LogViewerStore
    @Environment(\.forgeTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @AppStorage("forgeShowModuleTag") private var showModuleTag: Bool = true
    @AppStorage("forgeShowProcessTags") private var showProcessTags: Bool = true

    @State private var clearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                appHeader

                section("CAPTURE") {
                    minLevelRow
                    Divider().background(theme.border)
                    inMemoryLimitRow
                }

                section("APPEARANCE") {
                    themeRow
                    Divider().background(theme.border)
                    moduleToggleRow
                    Divider().background(theme.border)
                    processTagsToggleRow
                }

                section("PROVIDERS · \(store.providers.count)") {
                    if store.providers.isEmpty {
                        emptyProviders
                    } else {
                        ForEach(Array(store.providers.enumerated()), id: \.element.id) { idx, p in
                            providerRow(p)
                            if idx < store.providers.count - 1 {
                                Divider().background(theme.border)
                            }
                        }
                    }
                }

                section("STORAGE") {
                    NavigationLink {
                        LogConceptsView()
                    } label: {
                        rowChrome {
                            iconTile(systemName: "book.fill", tint: indigoTint)
                            Text("Log concepts")
                                .font(theme.sansFont(15, weight: .medium))
                                .foregroundColor(theme.text1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(theme.text3)
                        }
                    }
                    .buttonStyle(.plain)
                    Divider().background(theme.border)
                    Button {
                        clearConfirmation = true
                    } label: {
                        rowChrome {
                            iconTile(systemName: "trash.fill", tint: theme.danger)
                            Text("Clear session")
                                .font(theme.sansFont(15, weight: .medium))
                                .foregroundColor(theme.danger)
                            Spacer()
                            Text("\(store.entries.count) entries")
                                .font(theme.monoFont(12))
                                .foregroundColor(theme.text2)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(theme.accent)
                    .fontWeight(.semibold)
            }
        }
        .toolbarBackground(theme.bgAlt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Clear session?", isPresented: $clearConfirmation) {
            Button("Clear", role: .destructive) { store.clearSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the \(store.entries.count) in-memory entries from the viewer. Persisted logs on disk are unaffected.")
        }
    }

    // MARK: - App header

    private var appHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accentBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.accentBd, lineWidth: 1)
                    )
                Text("FL")
                    .font(theme.monoFont(14, weight: .bold))
                    .foregroundColor(theme.accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("ForgeLog")
                    .font(theme.sansFont(17, weight: .bold))
                    .foregroundColor(theme.text1)
                Text(headerMeta)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var headerMeta: String {
        let sessionPrefix = store.sessionID.uuidString.prefix(8)
        let entries = "\(store.entries.count) entr\(store.entries.count == 1 ? "y" : "ies")"
        return "\(entries) · session \(sessionPrefix)"
    }

    // MARK: - Capture rows

    private var minLevelRow: some View {
        rowChrome {
            iconTile(systemName: "circle.fill", tint: theme.severity[.error]!.fg)
            Text("Min level")
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            badge(text: store.configuration.minLevel.displayName.uppercased())
        }
    }

    private var inMemoryLimitRow: some View {
        rowChrome {
            iconTile(systemName: "chart.bar.fill", tint: theme.severity[.info]!.fg)
            Text("In-memory limit")
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            Text("\(store.configuration.inMemoryLimit) entries")
                .font(theme.monoFont(12))
                .foregroundColor(theme.text2)
        }
    }

    // MARK: - Appearance rows

    private var themeRow: some View {
        Menu {
            Picker("Theme", selection: $themePref) {
                Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                Label("Dark", systemImage: "moon.fill").tag("dark")
                Label("Light", systemImage: "sun.max.fill").tag("light")
            }
        } label: {
            rowChrome {
                iconTile(systemName: "moon.fill", tint: theme.severity[.info]!.fg)
                Text("Theme")
                    .font(theme.sansFont(15, weight: .medium))
                    .foregroundColor(theme.text1)
                Spacer()
                Text(themeLabel)
                    .font(theme.monoFont(12))
                    .foregroundColor(theme.text2)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(theme.text3)
            }
        }
    }

    private var themeLabel: String {
        switch themePref {
        case "dark":  return "Dark"
        case "light": return "Light"
        default:      return "System"
        }
    }

    private var moduleToggleRow: some View {
        rowChrome {
            iconTile(systemName: "number", tint: theme.severity[.warning]!.fg)
            Text("Show module tag")
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            Toggle("", isOn: $showModuleTag)
                .labelsHidden()
                .tint(theme.success)
        }
    }

    private var processTagsToggleRow: some View {
        rowChrome {
            iconTile(systemName: "number.square.fill", tint: theme.severity[.warning]!.fg)
            Text("Show process tags")
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            Toggle("", isOn: $showProcessTags)
                .labelsHidden()
                .tint(theme.success)
        }
    }

    // MARK: - Providers

    @ViewBuilder
    private func providerRow(_ provider: ForgeLog.ProviderInfo) -> some View {
        rowChrome {
            iconTile(systemName: "bolt.fill", tint: theme.severity[provider.minimumLevel]?.fg ?? theme.text2)
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(theme.sansFont(14.5, weight: .medium))
                    .foregroundColor(theme.text1)
                Text("min \(provider.minimumLevel.displayName.lowercased())")
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
            Spacer()
            SeverityLetterView(level: provider.minimumLevel, size: 18)
        }
    }

    private var emptyProviders: some View {
        Text("No providers registered")
            .font(theme.sansFont(13))
            .foregroundColor(theme.text3)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 14)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(theme.monoFont(10, weight: .bold))
                .tracking(0.7)
                .foregroundColor(theme.text3)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func rowChrome<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func iconTile(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(theme.mode == .light ? 0.16 : 0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tint.opacity(0.30), lineWidth: 1)
                )
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
        }
        .frame(width: 32, height: 32)
    }

    private func badge(text: String) -> some View {
        Text(text)
            .font(theme.monoFont(10.5, weight: .bold))
            .tracking(0.5)
            .foregroundColor(theme.text2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.surfaceHi)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// Purple-ish tint used by the "Log concepts" tile in the mock.
    private var indigoTint: Color {
        theme.mode == .light ? Color(hex: "#7B4FCC") : Color(hex: "#B68CFF")
    }
}
#endif
