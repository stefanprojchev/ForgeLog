#if os(iOS) || os(visionOS)
import SwiftUI

/// Settings — push-navigation, native `Form`. Visual layout matches the
/// handoff prototype. The **Providers** section is specific to ForgeLog and
/// lists the providers registered on `ForgeLog.shared` (Print, Console, Disk,
/// CrashContext, FileExport, NotificationCenter, Remote, Filtered).
struct SettingsView: View {
    @ObservedObject var store: LogViewerStore
    @Environment(\.forgeTheme) private var theme

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @AppStorage("forgeShowModuleTag") private var showModuleTag: Bool = true
    @AppStorage("forgeShowProcessTags") private var showProcessTags: Bool = true

    var body: some View {
        Form {
            Section("Capture") {
                LabeledContent("Min level") {
                    Text(store.configuration.minLevel.displayName)
                        .foregroundColor(theme.text2)
                }
                LabeledContent("In-memory limit") {
                    Text("\(store.configuration.inMemoryLimit) entries")
                        .foregroundColor(theme.text2)
                }
            }

            Section {
                if store.providers.isEmpty {
                    Text("No providers registered")
                        .font(theme.sansFont(13))
                        .foregroundColor(theme.text3)
                } else {
                    ForEach(store.providers) { provider in
                        providerRow(provider)
                    }
                }
            } header: {
                Text("Providers · \(store.providers.count)")
            } footer: {
                Text("Active providers attached to ForgeLog.shared. Each provider sets its own minimum level.")
                    .font(theme.sansFont(11))
                    .foregroundColor(theme.text3)
            }

            Section("Appearance") {
                Picker("Theme", selection: $themePref) {
                    Text("System").tag("system")
                    Text("Dark").tag("dark")
                    Text("Light").tag("light")
                }
                Toggle("Show module tag", isOn: $showModuleTag)
                Toggle("Show process tags", isOn: $showProcessTags)
            }

            Section("Storage") {
                NavigationLink("Log concepts") {
                    LogConceptsView()
                }
                Button {
                    store.clearSession()
                } label: {
                    HStack {
                        Text("Clear session")
                        Spacer()
                        Text("\(store.entries.count) entries")
                            .foregroundColor(theme.text2)
                    }
                }
            }

            Section {
                EmptyView()
            } footer: {
                Text("ForgeLog · session \(store.sessionID.uuidString.prefix(8))")
                    .font(theme.monoFont(10.5))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
