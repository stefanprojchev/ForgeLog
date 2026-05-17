#if os(iOS) || os(visionOS)
import SwiftUI

/// Wrapper that lets us identify an exported file for SwiftUI sheets.
/// SPI-exposed so the `ForgeNet` target can reuse the same export pipeline.
@_spi(ForgeLogPrimitives) public struct ExportResult: Identifiable {
    public let url: URL
    public let format: LogExportFormat
    public let entryCount: Int
    public var id: URL { url }

    public init(url: URL, format: LogExportFormat, entryCount: Int) {
        self.url = url
        self.format = format
        self.entryCount = entryCount
    }
}

/// Small confirmation/share sheet shown after an export completes. Displays
/// the format icon, entry count, on-disk size, and file name; the primary
/// button is a `ShareLink` that hands the file to the system share sheet.
@_spi(ForgeLogPrimitives) public struct ExportShareSheet: View {
    public let result: ExportResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    public init(result: ExportResult) { self.result = result }

    private var fileSizeLabel: String {
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: result.url.path),
            let size = attrs[.size] as? Int64
        else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    public var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.accentBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.accentBd, lineWidth: 1)
                    )
                Image(systemName: result.format.iconName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(theme.accent)
            }
            .frame(width: 84, height: 84)
            .padding(.top, 8)

            VStack(spacing: 4) {
                Text("\(result.format.displayName) export ready")
                    .font(theme.sansFont(17, weight: .bold))
                    .foregroundColor(theme.text1)
                Text("\(result.entryCount) entr\(result.entryCount == 1 ? "y" : "ies") · \(fileSizeLabel)")
                    .font(theme.monoFont(11.5))
                    .foregroundColor(theme.text3)
            }

            Text(result.url.lastPathComponent)
                .font(theme.monoFont(12))
                .foregroundColor(theme.text2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            ShareLink(item: result.url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share file")
                        .font(theme.sansFont(15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.accent)
                .foregroundColor(theme.mode == .light ? .white : Color(hex: "#0B0B0E"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 20)

            Button("Done") { dismiss() }
                .foregroundColor(theme.accent)
                .padding(.bottom, 8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg.ignoresSafeArea())
    }
}
#endif
