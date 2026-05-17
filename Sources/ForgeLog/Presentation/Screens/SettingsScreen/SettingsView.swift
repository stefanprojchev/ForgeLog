#if os(iOS) || os(visionOS)
import SwiftUI

/// Settings — icon-tile rows in custom sections.
struct SettingsView: View {
    // MARK: - Properties

    @Bindable var viewModel: SettingsViewModel
    @Environment(\.forgeTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @AppStorage("forgeShowModuleTag") private var showModuleTag: Bool = true
    @AppStorage("forgeShowProcessTags") private var showProcessTags: Bool = true

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                appHeader

                section(SettingsContent.captureSection) {
                    minLevelRow
                    Divider().background(theme.border)
                    inMemoryLimitRow
                }

                section(SettingsContent.appearanceSection) {
                    themeRow
                    Divider().background(theme.border)
                    moduleToggleRow
                    Divider().background(theme.border)
                    processTagsToggleRow
                }

                section("\(SettingsContent.providersSectionPrefix) · \(viewModel.providers.count)") {
                    if viewModel.providers.isEmpty {
                        emptyProviders
                    } else {
                        ForEach(Array(viewModel.providers.enumerated()), id: \.element.id) { idx, p in
                            providerRow(p)
                            if idx < viewModel.providers.count - 1 {
                                Divider().background(theme.border)
                            }
                        }
                    }
                }

                section(SettingsContent.storageSection) {
                    clearSessionRow
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(SettingsContent.navTitle)
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
        .alert(SettingsContent.clearAlertTitle, isPresented: Binding(
            get: { viewModel.state.isShowingClearConfirmation },
            set: { if !$0 { viewModel.cancelClearSession() } }
        )) {
            Button(SettingsContent.clearAlertConfirm, role: .destructive) { viewModel.confirmClearSession() }
            Button(SettingsContent.clearAlertCancel, role: .cancel) {}
        } message: {
            Text(SettingsContent.clearAlertMessage(count: viewModel.entryCount))
        }
    }

    // MARK: - Sections

    private var appHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accentBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.accentBd, lineWidth: 1)
                    )
                Text(SettingsContent.appShortCode)
                    .font(theme.monoFont(14, weight: .bold))
                    .foregroundColor(theme.accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(SettingsContent.appName)
                    .font(theme.sansFont(17, weight: .bold))
                    .foregroundColor(theme.text1)
                Text(viewModel.headerMeta)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var minLevelRow: some View {
        rowChrome {
            iconTile(systemName: "circle.fill", tint: theme.severity[.error]!.fg)
            Text("Min level")
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            badge(text: viewModel.minLevel.displayName.uppercased())
        }
    }

    private var inMemoryLimitRow: some View {
        rowChrome {
            iconTile(systemName: "chart.bar.fill", tint: theme.severity[.info]!.fg)
            Text("In-memory limit")
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            Text("\(viewModel.inMemoryLimit) entries")
                .font(theme.monoFont(12))
                .foregroundColor(theme.text2)
        }
    }

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

    private var clearSessionRow: some View {
        Button {
            viewModel.requestClearSession()
        } label: {
            rowChrome {
                iconTile(systemName: "trash.fill", tint: theme.danger)
                Text("Clear session")
                    .font(theme.sansFont(15, weight: .medium))
                    .foregroundColor(theme.danger)
                Spacer()
                Text("\(viewModel.entryCount) entries")
                    .font(theme.monoFont(12))
                    .foregroundColor(theme.text2)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyProviders: some View {
        Text("No providers registered")
            .font(theme.sansFont(13))
            .foregroundColor(theme.text3)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 14)
    }

    // MARK: - Components

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

    // MARK: - Private

    private var themeLabel: String {
        switch themePref {
        case "dark":  return "Dark"
        case "light": return "Light"
        default:      return "System"
        }
    }
}
#endif
