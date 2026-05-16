#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

struct NetworkDetailView: View {
    let entry: NetworkLogEntry
    @State private var tab: Tab = .overview
    @State private var exportingFormat: LogExportFormat?
    @State private var exportedFile: ExportResult?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    private let exporter = LogExporter()

    enum Tab: String, CaseIterable, Identifiable {
        case overview, request, response, timing
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                hero
                tabBar
                ScrollView {
                    switch tab {
                    case .overview: OverviewTab(entry: entry,
                                                exportingFormat: $exportingFormat,
                                                onExport: runExport)
                    case .request:  RequestTab(entry: entry)
                    case .response: ResponseTab(entry: entry)
                    case .timing:   TimingTab(entry: entry)
                    }
                }
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .principal) {
                    Text("Request")
                        .font(.headline)
                        .foregroundColor(theme.text1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Text("Share")
                            .fontWeight(.semibold)
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $exportedFile) { result in
                ExportShareSheet(result: result)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                MethodBadgeView(method: entry.method)
                StatusPillView(status: entry.status, statusText: entry.statusText)
                Spacer()
                Text("#\(entry.id.uuidString.prefix(8))")
                    .font(theme.monoFont(10))
                    .foregroundColor(theme.text3)
            }
            (
                Text("\(entry.scheme)://").foregroundColor(theme.text2) +
                Text(entry.host).foregroundColor(theme.text1) +
                Text(entry.path).foregroundColor(theme.text1)
            )
            .font(theme.monoFont(14, weight: .semibold))
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 14) {
                statLabel("time", entry.formattedDuration,
                          color: entry.durationMs > 1000 ? theme.severity[.warning]!.fg : theme.text1)
                statLabel("↑", formatBytes(entry.requestBytes), color: theme.text1)
                statLabel("↓", formatBytes(entry.responseBytes), color: theme.text1)
            }
            .font(theme.monoFont(11))
            .foregroundColor(theme.text2)
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle().fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    private func statLabel(_ k: String, _ v: String, color: Color) -> some View {
        (
            Text(k).foregroundColor(theme.text3) + Text(" ") +
            Text(v).foregroundColor(color).fontWeight(.semibold)
        )
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { t in
                Button(action: { tab = t }) {
                    Text(t.label)
                        .font(.system(size: 12, weight: tab == t ? .semibold : .medium))
                        .foregroundColor(tab == t ? theme.text1 : theme.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(tab == t ? theme.surface : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tab == t ? theme.border : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(theme.surfaceHi)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle().fill(theme.bg)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    // MARK: - Share

    private var shareText: String {
        "\(entry.method.rawValue) \(entry.scheme)://\(entry.host)\(entry.path) → \(entry.status.map(String.init) ?? "FAILED") (\(entry.formattedDuration))"
    }

    // MARK: - Export

    private func runExport(format: LogExportFormat) {
        guard exportingFormat == nil else { return }
        exportingFormat = format
        let curlString = Self.curl(for: entry)
        Task { @MainActor in
            defer { exportingFormat = nil }
            do {
                let url = try await exporter.exportRaw(text: curlString, fileName: "request.\(format.fileExtension)")
                exportedFile = ExportResult(url: url, format: format, entryCount: 1)
            } catch {
                #if DEBUG
                print("[ForgeNet] Detail export failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    static func curl(for entry: NetworkLogEntry) -> String {
        var lines: [String] = []
        lines.append("curl -X \(entry.method.rawValue) \\")
        var urlString = "\(entry.scheme)://\(entry.host)\(entry.path)"
        if !entry.query.isEmpty {
            urlString += "?" + entry.query.map { "\($0.key)=\($0.value ?? "")" }.joined(separator: "&")
        }
        lines.append("  '\(urlString)' \\")
        for (k, v) in entry.requestHeaders.sorted(by: { $0.key < $1.key }) {
            lines.append("  -H '\(k): \(v)' \\")
        }
        if let body = entry.requestBody, let str = String(data: body, encoding: .utf8) {
            lines.append("  --data '\(str.replacingOccurrences(of: "'", with: "\\'"))'")
        } else if let last = lines.last, last.hasSuffix("\\") {
            // Trim trailing backslash on the final header if there's no body.
            lines[lines.count - 1] = String(last.dropLast(2))
        }
        return lines.joined(separator: "\n")
    }

    private func formatBytes(_ n: Int) -> String {
        if n == 0 { return "—" }
        if n < 1024 { return "\(n) B" }
        if n < 1024 * 1024 { return String(format: "%.1f KB", Double(n) / 1024.0) }
        return String(format: "%.1f MB", Double(n) / 1_048_576.0)
    }
}

// MARK: - Tabs

private struct OverviewTab: View {
    let entry: NetworkLogEntry
    @Binding var exportingFormat: LogExportFormat?
    let onExport: (LogExportFormat) -> Void
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let chain = entry.redirectChain, chain.count > 1 {
                NetSectionLabel("Redirect chain · \(chain.count) hops")
                RedirectChainView(chain: chain)
            }
            NetSectionLabel("Called from")
            CallerCard(entry: entry)
            NetSectionLabel("Summary")
            SummaryCard(entry: entry)
            if let err = entry.error {
                NetSectionLabel("Network error")
                NetworkErrorCard(error: err)
            }
            actions
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private var actions: some View {
        VStack(spacing: 6) {
            ActionRowNet(icon: "doc.on.doc",
                         label: "Copy cURL",
                         hint: "Reproduce",
                         confirmationLabel: "cURL copied",
                         action: copyCurl)
            ActionRowNet(icon: "doc.on.doc",
                         label: "Copy URL",
                         hint: "Plain",
                         confirmationLabel: "URL copied",
                         action: copyURL)
            exportMenu
            ShareLink(item: NetworkDetailView.curl(for: entry)) {
                ActionRowNet.chrome(icon: "square.and.arrow.up",
                                    label: "Share cURL",
                                    hint: nil,
                                    theme: theme)
            }
            .buttonStyle(.plain)
        }
    }

    private var exportMenu: some View {
        Menu {
            Section { Text("Export this request") }
            ForEach(LogExportFormat.allCases) { format in
                Button {
                    onExport(format)
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
            }
        } label: {
            ActionRowNet.chrome(
                icon: exportingFormat == nil ? "square.and.arrow.up.on.square" : "ellipsis",
                label: exportingFormat == nil ? "Export as…" : "Exporting…",
                hint: exportingFormat?.displayName,
                theme: theme
            )
        }
        .disabled(exportingFormat != nil)
    }

    private func copyCurl() {
        let s = NetworkDetailView.curl(for: entry)
        #if canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
    }

    private func copyURL() {
        let s = "\(entry.scheme)://\(entry.host)\(entry.path)"
        #if canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
    }
}

private struct RequestTab: View {
    let entry: NetworkLogEntry
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NetSectionLabel("URL")
            CodeBlockNet(text: urlBlock)
            NetSectionLabel("Headers · \(entry.requestHeaders.count)")
            HeadersCard(headers: entry.requestHeaders)
            if !entry.query.isEmpty {
                NetSectionLabel("Query · \(entry.query.count)")
                QueryCard(query: entry.query)
            }
            if let body = entry.requestBody, !body.isEmpty {
                NetSectionLabel("Body · \(formatBytes(body.count))")
                CodeBlockNet(text: prettyBody(body))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private var urlBlock: String {
        let q = entry.query.isEmpty
            ? ""
            : "?" + entry.query.map { "\($0.key)=\($0.value ?? "null")" }.joined(separator: "&")
        return "\(entry.method.rawValue) \(entry.path)\(q)\nHost: \(entry.host)"
    }

    private func prettyBody(_ data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return String(data: data, encoding: .utf8) ?? "<binary>"
    }

    private func formatBytes(_ n: Int) -> String {
        if n < 1024 { return "\(n) B" }
        if n < 1024 * 1024 { return String(format: "%.1f KB", Double(n) / 1024.0) }
        return String(format: "%.1f MB", Double(n) / 1_048_576.0)
    }
}

private struct ResponseTab: View {
    let entry: NetworkLogEntry
    @State private var bodyMode: BodyMode = .pretty
    @Environment(\.forgeTheme) private var theme

    enum BodyMode { case pretty, raw, preview }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NetSectionLabel("Status")
            statusCard
            NetSectionLabel("Headers · \(entry.responseHeaders.count)")
            HeadersCard(headers: entry.responseHeaders)
            if entry.isGzip {
                gzipNotice
            }
            if let body = entry.responseBody, !body.isEmpty {
                NetSectionLabel(bodyLabel)
                bodyTabs
                bodyContent(body)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 24)
        .onAppear { if entry.isImage { bodyMode = .preview } }
    }

    private var statusCard: some View {
        let s = theme.statusStyle(entry.status)
        return HStack {
            Text(entry.failed
                 ? "FAILED"
                 : "\(entry.status!) \(entry.statusText ?? "")")
                .font(theme.monoFont(14, weight: .bold))
                .foregroundColor(s.fg)
            Spacer()
            Text(entry.formattedDuration)
                .font(theme.monoFont(11))
                .foregroundColor(theme.text2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(s.bg)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(s.bd, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var gzipNotice: some View {
        let s = theme.severity[.info]!
        let encoding = (entry.responseHeaders["Content-Encoding"] ?? "").uppercased()
        let saved: Int = {
            guard let decoded = entry.responseBytesDecoded, decoded > 0 else { return 0 }
            return Int((1.0 - Double(entry.responseBytes) / Double(decoded)) * 100.0)
        }()
        return HStack(spacing: 8) {
            Text(encoding)
                .font(theme.monoFont(9, weight: .bold))
                .tracking(0.5)
                .foregroundColor(s.fg)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(s.bg)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(s.bd, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Text("Decompressed automatically\(saved > 0 ? " · saved \(saved)%" : "")")
                .font(theme.monoFont(11))
                .foregroundColor(theme.text2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(s.bg)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(s.bd, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var bodyLabel: String {
        let main = "Body · \(formatBytes(entry.responseBytes))"
        if let decoded = entry.responseBytesDecoded {
            return main + " (\(formatBytes(decoded)) decoded)"
        }
        return main
    }

    private var bodyTabs: some View {
        let tabs: [(BodyMode, String)] = entry.isImage
            ? [(.pretty, "Pretty"), (.raw, "Raw"), (.preview, "Preview")]
            : [(.pretty, "Pretty"), (.raw, "Raw")]
        return HStack(spacing: 4) {
            ForEach(tabs.indices, id: \.self) { i in
                let (m, label) = tabs[i]
                Button(action: { bodyMode = m }) {
                    Text(label)
                        .font(theme.monoFont(10.5, weight: bodyMode == m ? .semibold : .medium))
                        .foregroundColor(bodyMode == m ? theme.accent : theme.text2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(bodyMode == m ? theme.accentBg : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(bodyMode == m ? theme.accentBd : theme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func bodyContent(_ data: Data) -> some View {
        if bodyMode == .preview, entry.isImage, let img = uiImage(from: data) {
            VStack(spacing: 0) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                Divider().background(theme.border)
                HStack(spacing: 12) {
                    Text("dim").foregroundColor(theme.text3)
                    Text("\(Int(img.size.width))×\(Int(img.size.height))").foregroundColor(theme.text1)
                    Text("size").foregroundColor(theme.text3)
                    Text(formatBytes(entry.responseBytes)).foregroundColor(theme.text1)
                }
                .font(theme.monoFont(11))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            CodeBlockNet(text: bodyText(data))
        }
    }

    private func uiImage(from data: Data) -> UIImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #else
        return nil
        #endif
    }

    private func bodyText(_ data: Data) -> String {
        if entry.isImage { return "<binary · \(formatBytes(data.count)) · \(entry.mime)>" }
        if bodyMode == .raw {
            return String(data: data, encoding: .utf8) ?? "<binary>"
        }
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return String(data: data, encoding: .utf8) ?? "<binary>"
    }

    private func formatBytes(_ n: Int) -> String {
        if n < 1024 { return "\(n) B" }
        if n < 1024 * 1024 { return String(format: "%.1f KB", Double(n) / 1024.0) }
        return String(format: "%.1f MB", Double(n) / 1_048_576.0)
    }
}

private struct TimingTab: View {
    let entry: NetworkLogEntry
    @Environment(\.forgeTheme) private var theme

    private struct Phase {
        let label: String
        let ms: Int
        let color: Color
    }

    private var phases: [Phase] {
        [
            Phase(label: "DNS lookup",    ms: entry.timing.dnsMs,      color: Color(hex: "#B68CFF")),
            Phase(label: "TCP connect",   ms: entry.timing.tcpMs,      color: Color(hex: "#5BA8FF")),
            Phase(label: "TLS handshake", ms: entry.timing.tlsMs,      color: Color(hex: "#FFB547")),
            Phase(label: "Waiting (TTFB)", ms: entry.timing.ttfbMs,    color: Color(hex: "#3ED07A")),
            Phase(label: "Download",      ms: entry.timing.transferMs, color: Color(hex: "#FF7AB8")),
        ]
    }

    private var total: Int { max(1, entry.durationMs) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                NetSectionLabel("Total")
                Text(entry.formattedDuration)
                    .font(theme.monoFont(11, weight: .bold))
                    .foregroundColor(theme.text1)
            }
            waterfall
            NetSectionLabel("Breakdown")
            breakdown
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    /// Cumulative start offset (ms) for each phase. Pure — derived from
    /// `phases` instead of a side-effecting `var` mutated inside `ForEach`,
    /// which could mis-align bars when SwiftUI re-evaluates rows.
    private var phaseStarts: [Int] {
        var out: [Int] = []
        out.reserveCapacity(phases.count)
        var running = 0
        for p in phases {
            out.append(running)
            running += p.ms
        }
        return out
    }

    private var waterfall: some View {
        VStack(spacing: 10) {
            ForEach(phases.indices, id: \.self) { i in
                let p = phases[i]
                let startPct = CGFloat(phaseStarts[i]) / CGFloat(total)
                let widthPct = max(0.005, CGFloat(p.ms) / CGFloat(total))
                HStack(spacing: 8) {
                    Text(p.label)
                        .font(theme.monoFont(11))
                        .foregroundColor(theme.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .truncationMode(.tail)
                        .frame(width: 108, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.mode == .light ? Color.black.opacity(0.04) : Color.white.opacity(0.04))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(p.color)
                                .opacity(p.ms == 0 ? 0.25 : 1)
                                .frame(width: max(1, min(geo.size.width - geo.size.width * startPct,
                                                         geo.size.width * widthPct)),
                                       height: 8)
                                .offset(x: min(geo.size.width, geo.size.width * startPct))
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 14)
                    Text(p.ms == 0 ? "—" : "\(p.ms)ms")
                        .font(theme.monoFont(11, weight: .semibold))
                        .foregroundColor(theme.text1)
                        .lineLimit(1)
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var breakdown: some View {
        VStack(spacing: 0) {
            ForEach(phases.indices, id: \.self) { i in
                let p = phases[i]
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .opacity(p.ms == 0 ? 0.3 : 1)
                        .frame(width: 10, height: 10)
                    Text(p.label)
                        .font(theme.sansFont(13))
                        .foregroundColor(theme.text1)
                    Spacer()
                    if p.ms == 0 {
                        Text("cached / N/A")
                            .font(theme.monoFont(12))
                            .foregroundColor(theme.text3)
                    } else {
                        Text("\(p.ms)ms")
                            .font(theme.monoFont(12))
                            .foregroundColor(theme.text2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if i != phases.count - 1 {
                        Rectangle().fill(theme.border).frame(height: 0.5)
                    }
                }
            }
        }
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Sub-components

private struct NetSectionLabel: View {
    let text: String
    @Environment(\.forgeTheme) private var theme
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.7)
            .textCase(.uppercase)
            .foregroundColor(theme.text3)
    }
}

private struct CallerCard: View {
    let entry: NetworkLogEntry
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        VStack(spacing: 0) {
            if let mod = entry.callerModule {
                MetaRowNet(key: "module", value: nil, mono: false) { ModuleTagView(module: mod) }
                Rectangle().fill(theme.border).frame(height: 0.5)
            }
            if let cls = entry.callerClass {
                MetaRowNet(key: "class", value: cls, mono: true, color: theme.text1)
                Rectangle().fill(theme.border).frame(height: 0.5)
            }
            if let fn = entry.callerFunction {
                MetaRowNet(key: "function", value: "\(fn)()", mono: true, color: theme.accent)
                Rectangle().fill(theme.border).frame(height: 0.5)
            }
            if let ln = entry.callerLine {
                MetaRowNet(key: "line", value: "\(ln)", mono: true, color: theme.text1)
            }
            if entry.callerModule == nil, entry.callerClass == nil,
               entry.callerFunction == nil, entry.callerLine == nil {
                Text("Call site not attached — pass a Caller through your networking layer to populate this.")
                    .font(theme.monoFont(11))
                    .foregroundColor(theme.text3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SummaryCard: View {
    let entry: NetworkLogEntry
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        VStack(spacing: 0) {
            MetaRowNet(key: "started",
                       value: ISO8601DateFormatter().string(from: entry.timestamp),
                       mono: true)
            Rectangle().fill(theme.border).frame(height: 0.5)
            MetaRowNet(key: "duration",
                       value: entry.formattedDuration,
                       mono: true,
                       color: entry.durationMs > 1000 ? theme.severity[.warning]!.fg : theme.text1)
            Rectangle().fill(theme.border).frame(height: 0.5)
            MetaRowNet(key: "mime",
                       value: entry.mime.isEmpty ? "—" : entry.mime,
                       mono: true,
                       color: theme.text2)
        }
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct NetworkErrorCard: View {
    let error: LoggedError
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        let s = theme.severity[.error]!
        VStack(spacing: 0) {
            HStack {
                Text(error.domain)
                    .font(theme.monoFont(12, weight: .bold))
                    .foregroundColor(s.fg)
                Spacer()
                Text("CODE")
                    .font(theme.monoFont(10, weight: .bold))
                    .tracking(0.4)
                    .foregroundColor(theme.text3)
                Text("\(error.code)")
                    .font(theme.monoFont(12, weight: .bold))
                    .foregroundColor(theme.text1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(s.bg)
            .overlay(alignment: .bottom) {
                Rectangle().fill(s.bd).frame(height: 0.5)
            }
            Text(error.description)
                .font(theme.monoFont(12.5))
                .foregroundColor(theme.text1)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
        }
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(s.bd, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct HeadersCard: View {
    let headers: [String: String]
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        let sorted = headers.sorted { $0.key < $1.key }
        VStack(spacing: 0) {
            ForEach(Array(sorted.enumerated()), id: \.element.key) { i, kv in
                MetaRowNet(key: kv.key,
                           value: kv.value,
                           mono: true,
                           color: kv.value == "<redacted>" ? theme.text3 : theme.text1,
                           truncate: true)
                if i != sorted.count - 1 {
                    Rectangle().fill(theme.border).frame(height: 0.5)
                }
            }
        }
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct QueryCard: View {
    let query: [String: String?]
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        let sorted = query.sorted { $0.key < $1.key }
        VStack(spacing: 0) {
            ForEach(Array(sorted.enumerated()), id: \.element.key) { i, kv in
                let valueStr = kv.value ?? "null"
                MetaRowNet(key: kv.key,
                           value: valueStr,
                           mono: true,
                           color: kv.value == nil ? theme.text3 : theme.text1,
                           truncate: true)
                if i != sorted.count - 1 {
                    Rectangle().fill(theme.border).frame(height: 0.5)
                }
            }
        }
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct RedirectChainView: View {
    let chain: [RedirectHop]
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(chain.indices, id: \.self) { i in
                let hop = chain[i]
                let s = theme.statusStyle(hop.status)
                let isLast = i == chain.count - 1
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(s.fg)
                            .frame(width: 10, height: 10)
                        if !isLast {
                            Rectangle().fill(theme.border).frame(width: 1).frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            StatusPillView(status: hop.status, statusText: nil, compact: true)
                            if !isLast {
                                Text("→ FOLLOWED")
                                    .font(theme.monoFont(9.5, weight: .bold))
                                    .tracking(0.4)
                                    .foregroundColor(theme.text3)
                            } else {
                                Text("← FINAL")
                                    .font(theme.monoFont(9.5, weight: .bold))
                                    .tracking(0.4)
                                    .foregroundColor(theme.success)
                            }
                        }
                        Text(hop.url)
                            .font(theme.monoFont(11.5))
                            .foregroundColor(theme.text1)
                            .padding(.bottom, isLast ? 0 : 8)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct CodeBlockNet: View {
    let text: String
    @Environment(\.forgeTheme) private var theme
    var body: some View {
        Text(text)
            .font(theme.monoFont(12))
            .foregroundColor(theme.text1)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .textSelection(.enabled)
    }
}

private struct ActionRowNet: View {
    let icon: String
    let label: String
    var hint: String? = nil
    var confirmationLabel: String? = nil
    let action: () -> Void
    @Environment(\.forgeTheme) private var theme
    @State private var confirmed: Bool = false

    var body: some View {
        Button {
            action()
            if confirmationLabel != nil {
                withAnimation(.snappy(duration: 0.18)) { confirmed = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.4))
                    withAnimation(.snappy(duration: 0.22)) { confirmed = false }
                }
            }
        } label: {
            if confirmed, let confirmationLabel {
                Self.chrome(icon: "checkmark", label: confirmationLabel, hint: nil,
                            theme: theme, accentOverride: theme.success)
            } else {
                Self.chrome(icon: icon, label: label, hint: hint, theme: theme)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: confirmed) { _, new in new }
    }

    static func chrome(icon: String, label: String, hint: String?, theme: ForgeLogTheme,
                       accentOverride: Color? = nil) -> some View {
        let tint = accentOverride ?? theme.accent
        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(tint)
                .contentTransition(.symbolEffect(.replace))
            Text(label)
                .font(theme.sansFont(13, weight: .medium))
                .foregroundColor(accentOverride ?? theme.text1)
            Spacer()
            if let hint {
                Text(hint)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentOverride == nil ? theme.surface : tint.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentOverride == nil ? theme.border : tint.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct MetaRowNet: View {
    let key: String
    let value: String?
    let mono: Bool
    var color: Color = .primary
    var truncate: Bool = false
    @ViewBuilder var trailing: () -> AnyView

    @Environment(\.forgeTheme) private var theme

    init(key: String, value: String?, mono: Bool, color: Color? = nil, truncate: Bool = false) {
        self.key = key
        self.value = value
        self.mono = mono
        self.color = color ?? .primary
        self.truncate = truncate
        self.trailing = { AnyView(EmptyView()) }
    }

    init<T: View>(key: String, value: String?, mono: Bool, color: Color? = nil, truncate: Bool = false,
                  @ViewBuilder trailing: @escaping () -> T) {
        self.key = key
        self.value = value
        self.mono = mono
        self.color = color ?? .primary
        self.truncate = truncate
        self.trailing = { AnyView(trailing()) }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(key)
                .font(theme.monoFont(10.5))
                .foregroundColor(theme.text3)
                .frame(width: 70, alignment: .leading)
            if let value {
                Text(value)
                    .font(mono ? theme.monoFont(12) : theme.sansFont(12))
                    .foregroundColor(color)
                    .lineLimit(truncate ? 1 : nil)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                trailing()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - LogExporter helper

extension LogExporter {
    /// Writes raw text to a temporary file with the given name and returns the URL.
    /// Used by the network detail export to write a cURL/text file.
    fileprivate func exportRaw(text: String, fileName: String) async throws -> URL {
        let url = URL.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
#endif
