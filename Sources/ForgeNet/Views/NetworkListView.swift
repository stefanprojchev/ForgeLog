#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Master list for the network viewer.
struct NetworkListView: View {
    @ObservedObject var store: NetworkLogStore
    @State private var sheet: ListSheet?
    @State private var exportingFormat: LogExportFormat?
    @State private var exportedFile: ExportResult?
    @Environment(\.forgeTheme) private var theme

    private let exporter = LogExporter()

    enum ListSheet: Identifiable {
        case detail(NetworkLogEntry)
        case filter(FilterKind)
        case info
        var id: String {
            switch self {
            case .detail(let e): return "detail-\(e.id)"
            case .filter(let k): return "filter-\(k.rawValue)"
            case .info:          return "info"
            }
        }
    }

    enum FilterKind: String { case method, host, caller }

    var body: some View {
        VStack(spacing: 0) {
            NetStatsStrip(store: store)
            NetSparkline(entries: store.entries)
            StatusFamilyCardsView(
                selected: $store.filter.statusFamily,
                counts: StatusFamilyCounts.compute(from: store.entries)
            )
            SearchBar(query: $store.filter.query)
            FilterChipsRow(
                filter: $store.filter,
                onOpenMethod: { sheet = .filter(.method) },
                onOpenHost:   { sheet = .filter(.host)   },
                onOpenCaller: { sheet = .filter(.caller) }
            )
            list
        }
        .background(theme.bg.ignoresSafeArea())
        .toolbar { toolbarContent }
        .toolbarBackground(theme.bgAlt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(theme.accent)
        .navigationTitle("Network")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheet) { s in
            switch s {
            case .detail(let entry):
                NetworkDetailView(entry: entry)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .filter(let kind):
                NetworkFilterPickerView(kind: kind, store: store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .info:
                NetworkConceptsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $exportedFile) { result in
            ExportShareSheet(result: result)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Network Viewer")
                .font(.headline)
                .foregroundColor(theme.text1)
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 14) {
                Button(action: { sheet = .info }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(theme.accent)
                }
                exportMenu
                NavigationLink(destination: NetworkSettingsView(store: store)) {
                    Image(systemName: "gearshape")
                        .foregroundColor(theme.accent)
                }
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if store.filteredEntries.isEmpty {
            networkEmpty
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.filteredEntries) { entry in
                        Button(action: { sheet = .detail(entry) }) {
                            NetworkRowView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var networkEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "network")
                .font(.system(size: 28))
                .foregroundColor(theme.text3)
                .frame(width: 64, height: 64)
                .background(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(store.filter.hasActiveFilters || store.filter.statusFamily != nil
                 ? "No requests match your filters"
                 : "No requests yet")
                .font(theme.sansFont(16, weight: .bold))
                .foregroundColor(theme.text1)
            Text(store.filter.hasActiveFilters || store.filter.statusFamily != nil
                 ? "Try clearing filters or widening the status family."
                 : "Make any URLSession request — ForgeNet captures it automatically.")
                .font(theme.monoFont(12))
                .foregroundColor(theme.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            if store.filter.hasActiveFilters || store.filter.statusFamily != nil {
                Button {
                    store.filter.clear()
                } label: {
                    Text("Clear all filters")
                        .font(theme.sansFont(14, weight: .semibold))
                        .foregroundColor(theme.mode == .light ? .white : Color(hex: "#0B0B0E"))
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Export menu

    @ViewBuilder
    private var exportMenu: some View {
        Menu {
            Section {
                Text("Export \(store.filteredEntries.count) filtered request\(store.filteredEntries.count == 1 ? "" : "s")")
            }
            ForEach(LogExportFormat.allCases) { format in
                Button {
                    runExport(format: format)
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text(format.displayName)
                            Text(format.subtitle)
                        }
                    } icon: {
                        Image(systemName: format.iconName)
                    }
                }
                .disabled(store.filteredEntries.isEmpty)
            }
        } label: {
            if exportingFormat != nil {
                ProgressView().scaleEffect(0.75)
            } else {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(store.filteredEntries.isEmpty ? theme.text4 : theme.accent)
            }
        }
        .disabled(store.filteredEntries.isEmpty || exportingFormat != nil)
    }

    private func runExport(format: LogExportFormat) {
        guard exportingFormat == nil else { return }
        let snapshot = store.filteredEntries
        guard !snapshot.isEmpty else { return }
        exportingFormat = format
        Task { @MainActor in
            defer { exportingFormat = nil }
            do {
                let url = try await exporter.exportRaw(
                    text: Self.serializedText(snapshot, format: format),
                    fileName: "network-export.\(format.fileExtension)"
                )
                exportedFile = ExportResult(url: url, format: format, entryCount: snapshot.count)
            } catch {
                #if DEBUG
                print("[ForgeNet] Export failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Serializes a snapshot of network entries in the requested format. We
    /// can't reuse `LogExporter` directly because it works on `LogEntry`; we
    /// produce text and write it to a temp file via the same primitive.
    static func serializedText(_ entries: [NetworkLogEntry], format: LogExportFormat) -> String {
        switch format {
        case .plainText:
            return entries.map(Self.plainTextLine(_:)).joined(separator: "\n")
        case .markdown:
            return Self.markdown(entries)
        case .csv:
            return Self.csv(entries)
        case .json:
            return Self.json(entries, pretty: true)
        case .jsonl:
            return Self.json(entries, pretty: false)
        }
    }

    private static func plainTextLine(_ e: NetworkLogEntry) -> String {
        let status = e.status.map { "\($0)" } ?? "FAILED"
        return "\(e.formattedTime) \(e.method.rawValue) \(status) \(e.scheme)://\(e.host)\(e.path) · \(e.formattedDuration)"
    }

    private static func markdown(_ entries: [NetworkLogEntry]) -> String {
        var out = "# ForgeNet Export\n\n"
        out += "_Exported \(Date()) · \(entries.count) request\(entries.count == 1 ? "" : "s")_\n\n---\n\n"
        for e in entries {
            let status = e.status.map { "\($0)" } ?? "FAILED"
            out += "## \(e.method.rawValue) \(status) · `\(e.formattedTime)`\n\n"
            out += "**`\(e.scheme)://\(e.host)\(e.path)`**\n\n"
            out += "| | |\n|---|---|\n"
            out += "| Duration | `\(e.formattedDuration)` |\n"
            out += "| ↑ Request | `\(e.requestBytes)` B |\n"
            out += "| ↓ Response | `\(e.responseBytes)` B |\n"
            if let mod = e.callerModule { out += "| Caller | `\(mod)` |\n" }
            out += "\n---\n\n"
        }
        return out
    }

    private static func csv(_ entries: [NetworkLogEntry]) -> String {
        var out = "timestamp,method,status,scheme,host,path,duration_ms,request_bytes,response_bytes,mime,caller\n"
        for e in entries {
            let row = [
                ISO8601DateFormatter().string(from: e.timestamp),
                e.method.rawValue,
                e.status.map(String.init) ?? "FAILED",
                e.scheme,
                e.host,
                e.path,
                String(e.durationMs),
                String(e.requestBytes),
                String(e.responseBytes),
                e.mime,
                e.callerModule ?? "",
            ].map(csvField).joined(separator: ",")
            out += row + "\n"
        }
        return out
    }

    private static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(where: { ",\"\n\r".contains($0) })
        guard needsQuoting else { return raw }
        return "\"" + raw.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func json(_ entries: [NetworkLogEntry], pretty: Bool) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(entries),
                  let str = String(data: data, encoding: .utf8) else { return "[]" }
            return str
        } else {
            encoder.outputFormatting = [.sortedKeys]
            var out = ""
            for e in entries {
                guard let data = try? encoder.encode(e),
                      let str = String(data: data, encoding: .utf8) else { continue }
                out += str + "\n"
            }
            return out
        }
    }
}

// MARK: - Stats strip (REC pill + count + size + pause)

private struct NetStatsStrip: View {
    @ObservedObject var store: NetworkLogStore
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(store.isPaused ? theme.text3 : theme.success)
                    .frame(width: 7, height: 7)
                    .shadow(color: store.isPaused ? .clear : theme.success.opacity(0.7),
                            radius: 3)
                Text(store.isPaused ? "PAUSED" : "REC")
                    .font(theme.monoFont(11, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(store.isPaused ? theme.text3 : theme.success)
            }
            Rectangle().fill(theme.border).frame(width: 1, height: 14)
            (
                Text("\(store.entries.count)").foregroundColor(theme.text1).fontWeight(.semibold) +
                Text(" requests · ").foregroundColor(theme.text2) +
                Text(formatTransferred(store.totalBytes)).foregroundColor(theme.text1).fontWeight(.semibold)
            )
            .font(theme.monoFont(12.5))
            .tracking(-0.1)
            .lineLimit(1)
            Spacer(minLength: 0)
            Button(action: { store.togglePause() }) {
                HStack(spacing: 5) {
                    Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 10))
                    Text(store.isPaused ? "resume" : "pause")
                }
                .font(theme.monoFont(11.5, weight: .semibold))
                .foregroundColor(theme.text1)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            Rectangle().fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    private func formatTransferred(_ n: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file)
    }
}

// MARK: - Sparkline (per-second, family-tinted)

private struct NetSparkline: View {
    let entries: [NetworkLogEntry]
    var bucketCount: Int = 60
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        GeometryReader { geo in
            let buckets = computeBuckets()
            let maxCount = max(1, buckets.map(\.total).max() ?? 1)
            let gap: CGFloat = 1.5
            let barWidth = max(1, (geo.size.width - gap * CGFloat(bucketCount - 1)) / CGFloat(bucketCount))
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(buckets.indices, id: \.self) { i in
                    bar(bucket: buckets[i],
                        barWidth: barWidth,
                        maxCount: maxCount,
                        chartHeight: geo.size.height)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topLeading) {
                Text(leftLabel)
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.leading, 2)
            }
            .overlay(alignment: .topTrailing) {
                Text(rightLabel)
                    .font(theme.monoFont(9))
                    .foregroundColor(theme.text3)
                    .tracking(0.3)
                    .padding(.trailing, 2)
            }
        }
        .frame(height: 32)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Rectangle().fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    @ViewBuilder
    private func bar(bucket: Bucket, barWidth: CGFloat, maxCount: Int, chartHeight: CGFloat) -> some View {
        let totalHeight = bucket.total == 0
            ? CGFloat(1)
            : max(2, chartHeight * CGFloat(bucket.total) / CGFloat(maxCount))

        VStack(spacing: 0) {
            if bucket.total == 0 {
                Rectangle()
                    .fill(theme.text4)
                    .frame(width: barWidth, height: totalHeight)
            } else {
                // Stack from worst at the top to best at the bottom.
                ForEach(barOrder, id: \.self) { fam in
                    let count = bucket.perFamily[fam] ?? 0
                    if count > 0 {
                        Rectangle()
                            .fill(color(for: fam))
                            .frame(width: barWidth,
                                   height: totalHeight * CGFloat(count) / CGFloat(bucket.total))
                    }
                }
            }
        }
    }

    private let barOrder: [HTTPStatusFamily] = [.serverError, .failed, .clientError, .redirect, .success, .informational]

    private func color(for family: HTTPStatusFamily) -> Color {
        switch family {
        case .clientError:                 return theme.severity[.warning]!.fg
        case .serverError, .failed:        return theme.severity[.error]!.fg
        case .redirect:                    return theme.severity[.debug]!.fg
        case .success, .informational:     return theme.severity[.info]!.fg
        }
    }

    private var leftLabel: String {
        guard let oldest = entries.map(\.timestamp).min() else { return "—" }
        return Self.relativeLabel(for: oldest)
    }

    private var rightLabel: String {
        guard let newest = entries.map(\.timestamp).max() else { return "—" }
        if Date().timeIntervalSince(newest) < 5 { return "NOW" }
        return Self.relativeLabel(for: newest)
    }

    private static func relativeLabel(for date: Date) -> String {
        let secs = max(0, Date().timeIntervalSince(date))
        switch secs {
        case 0..<60:                    return "\(Int(secs))s"
        case 60..<3_600:                return "\(Int(secs / 60))m"
        case 3_600..<86_400:            return "\(Int(secs / 3_600))h"
        case 86_400..<7 * 86_400:       return "\(Int(secs / 86_400))d"
        case 7 * 86_400..<30 * 86_400:  return "\(Int(secs / (7 * 86_400)))w"
        default:                        return "\(Int(secs / (30 * 86_400)))mo"
        }
    }

    private struct Bucket {
        var total: Int = 0
        var perFamily: [HTTPStatusFamily: Int] = [:]

        mutating func add(_ family: HTTPStatusFamily) {
            total += 1
            perFamily[family, default: 0] += 1
        }
    }

    private func computeBuckets() -> [Bucket] {
        var buckets: [Bucket] = Array(repeating: Bucket(), count: bucketCount)
        guard !entries.isEmpty else { return buckets }
        let timestamps = entries.map(\.timestamp)
        let oldest = timestamps.min()!
        let newest = timestamps.max()!
        let span = max(1, newest.timeIntervalSince(oldest))
        let bucketDuration = span / Double(bucketCount)
        for e in entries {
            let offset = e.timestamp.timeIntervalSince(oldest)
            var idx = Int(offset / bucketDuration)
            if idx >= bucketCount { idx = bucketCount - 1 }
            if idx < 0 { idx = 0 }
            buckets[idx].add(e.statusFamily)
        }
        return buckets
    }
}

// MARK: - Search bar

private struct SearchBar: View {
    @Binding var query: String
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(theme.text3)
            TextField("", text: $query,
                      prompt: Text("Search URL, host, class…")
                          .foregroundColor(theme.text3))
                .textFieldStyle(.plain)
                .font(theme.sansFont(13.5))
                .foregroundColor(theme.text1)
                .tint(theme.accent)
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(theme.text3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Filter chips

private struct FilterChipsRow: View {
    @Binding var filter: NetworkFilterState
    let onOpenMethod: () -> Void
    let onOpenHost:   () -> Void
    let onOpenCaller: () -> Void
    @Environment(\.forgeTheme) private var theme

    private var activeCount: Int {
        (filter.methods.isEmpty ? 0 : 1) +
        (filter.hosts.isEmpty ? 0 : 1) +
        (filter.callers.isEmpty ? 0 : 1)
    }

    var body: some View {
        HStack(spacing: 6) {
            chip(label: "Method", value: display(filter.methods.map(\.rawValue)),
                 isActive: !filter.methods.isEmpty, action: onOpenMethod)
            chip(label: "Host", value: display(Array(filter.hosts)),
                 isActive: !filter.hosts.isEmpty, action: onOpenHost)
            chip(label: "Caller", value: display(Array(filter.callers)),
                 isActive: !filter.callers.isEmpty, action: onOpenCaller)
            if activeCount > 0 {
                Button(action: { filter.clearChipFilters() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.danger)
                        .frame(width: 36, height: 48)
                        .background(theme.danger.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(theme.danger.opacity(0.28), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func display(_ arr: [String]) -> String {
        guard !arr.isEmpty else { return "All" }
        let sorted = arr.sorted()
        if sorted.count == 1 { return sorted[0] }
        return "\(sorted[0]) +\(sorted.count - 1)"
    }

    private func chip(label: String, value: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(isActive ? theme.accent.opacity(0.85) : theme.text3)
                HStack(spacing: 4) {
                    Text(value)
                        .font(theme.sansFont(13, weight: .semibold))
                        .foregroundColor(isActive ? theme.accent : theme.text1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(isActive ? theme.accent : theme.text3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 48)
            .background(isActive ? theme.accentBg : theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isActive ? theme.accentBd : theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LogExporter helper

extension LogExporter {
    fileprivate func exportRaw(text: String, fileName: String) async throws -> URL {
        let url = URL.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
#endif
