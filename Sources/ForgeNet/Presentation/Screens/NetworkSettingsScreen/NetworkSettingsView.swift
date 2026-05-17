#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Network viewer settings — icon-tile rows in custom sections matching the
/// log-side `SettingsView` look.
struct NetworkSettingsView: View {
    // MARK: - Properties

    @Bindable var viewModel: NetworkSettingsViewModel
    @Environment(\.forgeTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @AppStorage("forgeNetHighlightSlow") private var highlightSlow: Bool = true

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                appHeader

                section(NetworkSettingsContent.captureSection) {
                    captureRow(icon: "antenna.radiowaves.left.and.right",
                               tint: theme.severity[.info]!.fg,
                               title: "Capture request body",
                               value: viewModel.configuration.captureRequestBody ? "ON" : "OFF")
                    Divider().background(theme.border)
                    captureRow(icon: "antenna.radiowaves.left.and.right",
                               tint: theme.severity[.info]!.fg,
                               title: "Capture response body",
                               value: viewModel.configuration.captureResponseBody ? "ON" : "OFF")
                    Divider().background(theme.border)
                    captureRow(icon: "ruler",
                               tint: theme.severity[.warning]!.fg,
                               title: "Max body size",
                               value: bodyLimitLabel)
                }

                section(NetworkSettingsContent.appearanceSection) {
                    themeRow
                    Divider().background(theme.border)
                    highlightSlowRow
                }

                section(NetworkSettingsContent.redactionSection) {
                    redactionRow(icon: "key.fill",
                                 title: "Auto-redact Authorization",
                                 enabled: viewModel.configuration.autoRedactAuthHeaders)
                    Divider().background(theme.border)
                    redactionRow(icon: "circle.dashed",
                                 title: "Auto-redact Cookie / Set-Cookie",
                                 enabled: viewModel.configuration.autoRedactAuthHeaders)
                    Divider().background(theme.border)
                    redactionRow(icon: "eye.slash.fill",
                                 title: "Auto-redact tokens in body",
                                 enabled: viewModel.configuration.autoRedactSensitiveBody)
                }

                section(NetworkSettingsContent.storageSection) {
                    clearSessionRow
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(NetworkSettingsContent.navTitle)
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
        .alert(NetworkSettingsContent.clearAlertTitle, isPresented: Binding(
            get: { viewModel.state.isShowingClearConfirmation },
            set: { if !$0 { viewModel.cancelClearSession() } }
        )) {
            Button(NetworkSettingsContent.clearAlertConfirm, role: .destructive) { viewModel.confirmClearSession() }
            Button(NetworkSettingsContent.clearAlertCancel, role: .cancel) {}
        } message: {
            Text(NetworkSettingsContent.clearAlertMessage(count: viewModel.entryCount))
        }
    }

    // MARK: - Sections

    private var appHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accentBg)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.accentBd, lineWidth: 1))
                Text(NetworkSettingsContent.appShortCode)
                    .font(theme.monoFont(14, weight: .bold))
                    .foregroundColor(theme.accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(NetworkSettingsContent.appName)
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

    private var themeRow: some View {
        Menu {
            Picker("Theme", selection: $themePref) {
                Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                Label("Dark",   systemImage: "moon.fill").tag("dark")
                Label("Light",  systemImage: "sun.max.fill").tag("light")
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

    private var highlightSlowRow: some View {
        rowChrome {
            iconTile(systemName: "speedometer", tint: theme.severity[.warning]!.fg)
            VStack(alignment: .leading, spacing: 2) {
                Text("Highlight slow requests")
                    .font(theme.sansFont(15, weight: .medium))
                    .foregroundColor(theme.text1)
                Text("> \(viewModel.configuration.slowRequestThresholdMs)ms")
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
            Spacer()
            Toggle("", isOn: $highlightSlow)
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
                Text("\(viewModel.entryCount) requests")
                    .font(theme.monoFont(12))
                    .foregroundColor(theme.text2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Components

    private func captureRow(icon: String, tint: Color, title: String, value: String) -> some View {
        rowChrome {
            iconTile(systemName: icon, tint: tint)
            Text(title)
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            badge(text: value)
        }
    }

    private func redactionRow(icon: String, title: String, enabled: Bool) -> some View {
        rowChrome {
            iconTile(systemName: icon, tint: enabled ? theme.success : theme.text3)
            Text(title)
                .font(theme.sansFont(15, weight: .medium))
                .foregroundColor(theme.text1)
            Spacer()
            badge(text: enabled ? "ON" : "OFF")
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
            VStack(spacing: 0) { content() }
                .background(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func rowChrome<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) { content() }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
    }

    private func iconTile(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(theme.mode == .light ? 0.16 : 0.20))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.30), lineWidth: 1))
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
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Private

    private var bodyLimitLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(viewModel.configuration.maxBodyBytes), countStyle: .file)
    }

    private var themeLabel: String {
        switch themePref {
        case "dark":  return "Dark"
        case "light": return "Light"
        default:      return "System"
        }
    }
}
#endif
