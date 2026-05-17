#if os(iOS) || os(visionOS)
import Foundation
#if canImport(UIKit)
import UIKit
#endif
@_spi(ForgeLogPrimitives) import ForgeLog

@Observable @MainActor
final class NetworkDetailViewModel {
    // MARK: - Input & State

    let input: NetworkDetailContent.Input
    var state = NetworkDetailContent.State.default

    // MARK: - Init

    init(input: NetworkDetailContent.Input) {
        self.input = input
        if input.entry.isImage {
            self.state.bodyMode = .preview
        }
    }

    // MARK: - Derived

    var entry: NetworkLogEntry { input.entry }

    var curlText: String { Self.curl(for: entry) }

    var shareText: String {
        "\(entry.method.rawValue) \(entry.scheme)://\(entry.host)\(entry.path) → \(entry.status.map(String.init) ?? "FAILED") (\(entry.formattedDuration))"
    }

    var urlText: String {
        "\(entry.scheme)://\(entry.host)\(entry.path)"
    }

    // MARK: - Intents

    func setTab(_ tab: NetworkDetailContent.Tab) {
        state.tab = tab
    }

    func setBodyMode(_ mode: NetworkDetailContent.BodyMode) {
        state.bodyMode = mode
    }

    func copyCurl() {
        copy(curlText)
    }

    func copyURL() {
        copy(urlText)
    }

    func runExport(format: LogExportFormat) {
        guard state.exportingFormat == nil else { return }
        state.exportingFormat = format
        let payload = curlText
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.state.exportingFormat = nil }
            do {
                let url = try await exporter.exportRaw(text: payload, fileName: "request.\(format.fileExtension)")
                let result = ExportResult(url: url, format: format, entryCount: 1)
                self.input.router.presentSheet(.exportResult(result))
            } catch {
                #if DEBUG
                print("[ForgeNet] Detail export failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Private

    @ObservationIgnored private let exporter = LogExporter()

    private func copy(_ s: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
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
            lines[lines.count - 1] = String(last.dropLast(2))
        }
        return lines.joined(separator: "\n")
    }
}
#endif
