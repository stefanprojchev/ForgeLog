#if os(iOS) || os(visionOS)
import SwiftUI

/// Settings — themed `Form`. The **Providers** section is specific to
/// ForgeLog and lists the providers registered on `ForgeLog.shared` (Print,
/// Console, Disk, CrashContext, FileExport, NotificationCenter, Remote,
/// Filtered).
struct SettingsView: View {
    @ObservedObject var store: LogViewerStore
    @Environment(\.forgeTheme) private var theme

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @AppStorage("forgeShowModuleTag") private var showModuleTag: Bool = true
    @AppStorage("forgeShowProcessTags") private var showProcessTags: Bool = true

    var body: some View {
        Form {
            captureSection
            providersSection
            appearanceSection
            storageSection
            footerSection
        }
        .scrollContentBackground(.hidden)
        .background(theme.bg.ignoresSafeArea())
        .tint(theme.accent)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.bgAlt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Capture

    private var captureSection: some View {
        Section {
            row(label: "Min level",     value: store.configuration.minLevel.displayName)
            row(label: "In-memory limit", value: "\(store.configuration.inMemoryLimit) entries")
        } header: {
            sectionHeader("CAPTURE")
        }
        .listRowBackground(theme.surface)
    }

    // MARK: - Providers

    private var providersSection: some View {
        Section {
            if store.providers.isEmpty {
                Text("No providers registered")
                    .font(theme.sansFont(13))
                    .foregroundColor(theme.text3)
                    .listRowBackground(theme.surface)
            } else {
                ForEach(store.providers) { provider in
                    providerRow(provider)
                        .listRowBackground(theme.surface)
                }
            }
        } header: {
            sectionHeader("PROVIDERS · \(store.providers.count)")
        } footer: {
            Text("Active providers attached to ForgeLog.shared. Each provider sets its own minimum level.")
                .font(theme.sansFont(11))
                .foregroundColor(theme.text3)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker(selection: $themePref) {
                Text("System").tag("system")
                Text("Dark").tag("dark")
                Text("Light").tag("light")
            } label: {
                Text("Theme")
                    .foregroundColor(theme.text1)
            }
            Toggle(isOn: $showModuleTag) {
                Text("Show module tag")
                    .foregroundColor(theme.text1)
            }
            Toggle(isOn: $showProcessTags) {
                Text("Show process tags")
                    .foregroundColor(theme.text1)
            }
        } header: {
            sectionHeader("APPEARANCE")
        }
        .listRowBackground(theme.surface)
    }

    // MARK: - Storage

    private var storageSection: some View {
        Section {
            NavigationLink {
                LogConceptsView()
            } label: {
                Text("Log concepts")
                    .foregroundColor(theme.text1)
            }
            Button {
                store.clearSession()
            } label: {
                HStack {
                    Text("Clear session")
                        .foregroundColor(theme.text1)
                    Spacer()
                    Text("\(store.entries.count) entries")
                        .foregroundColor(theme.text2)
                }
            }
        } header: {
            sectionHeader("STORAGE")
        }
        .listRowBackground(theme.surface)
    }

    // MARK: - Footer

    private var footerSection: some View {
        Section {
            EmptyView()
        } footer: {
            Text("ForgeLog · session \(store.sessionID.uuidString.prefix(8))")
                .font(theme.monoFont(10.5))
                .foregroundColor(theme.text3)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Building blocks

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(theme.monoFont(10, weight: .bold))
            .tracking(0.7)
            .foregroundColor(theme.text3)
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(theme.text1)
            Spacer()
            Text(value)
                .foregroundColor(theme.text2)
        }
    }

    @ViewBuilder
    private func providerRow(_ provider: ForgeLog.ProviderInfo) -> some View {
        HStack(spacing: 10) {
            SeverityLetterView(level: provider.minimumLevel, size: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(theme.sansFont(13.5, weight: .medium))
                    .foregroundColor(theme.text1)
                Text("min \(provider.minimumLevel.displayName.lowercased())")
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
#endif
