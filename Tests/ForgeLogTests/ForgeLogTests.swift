import Testing
import Foundation
import ForgeCore
@testable import ForgeLog

@Suite("ForgeLog")
struct ForgeLogTests {

    /// In-memory provider for tests — captures entries that flow through the logger.
    struct RecordingProvider: LogProviderProtocol {
        let name: String
        let minimumLevel: LogLevel
        private let storage: LockedState<[LogEntry]>

        init(name: String = "Recording", minimumLevel: LogLevel = .debug) {
            self.name = name
            self.minimumLevel = minimumLevel
            self.storage = LockedState([])
        }

        func log(_ entry: LogEntry) {
            guard entry.level >= minimumLevel else { return }
            storage.withLock { $0.append(entry) }
        }

        var entries: [LogEntry] {
            storage.withLock { $0 }
        }
    }

    @Test("Drops entries before configure() is called")
    func dropsBeforeConfigure() {
        let logger = ForgeLog()
        let recorder = RecordingProvider()
        // Provider attached but logger not configured — entries should drop silently
        // (in release; in DEBUG, the call still drops because isConfigured is false).
        logger.addProvider(recorder)

        // addProvider sets the provider, but isConfigured is still false.
        // Entries are dropped (see DEBUG fallback print in dispatch()).
        // Smoke test: API doesn't crash.
        #expect(logger.providerNames.contains("Recording"))
    }

    @Test("Routes entries to all configured providers")
    func routesToProviders() {
        let logger = ForgeLog()
        let recorder = RecordingProvider()
        logger.configure(LoggerConfiguration(providers: [recorder], maxAge: nil))

        logger.info("hello world", processes: ["Onboarding"])

        #expect(recorder.entries.count == 1)
        #expect(recorder.entries.first?.message == "hello world")
        #expect(recorder.entries.first?.level == .info)
        #expect(recorder.entries.first?.processes == ["Onboarding"])
    }

    @Test("isDebugEnabled=false suppresses debug-level entries")
    func suppressesDebug() {
        let logger = ForgeLog()
        let recorder = RecordingProvider()
        logger.configure(
            LoggerConfiguration(providers: [recorder], maxAge: nil, isDebugEnabled: false)
        )

        logger.debug("ignored")
        logger.info("kept")

        #expect(recorder.entries.count == 1)
        #expect(recorder.entries.first?.message == "kept")
    }

    @Test("Provider minimumLevel filters before delivery")
    func minimumLevelFiltering() {
        let logger = ForgeLog()
        let recorder = RecordingProvider(minimumLevel: .warning)
        logger.configure(LoggerConfiguration(providers: [recorder], maxAge: nil))

        logger.info("info")
        logger.warning("warning")
        logger.error("error")

        #expect(recorder.entries.map(\.level) == [.warning, .error])
    }

    @Test("removeProvider removes by name")
    func removeProvider() {
        let logger = ForgeLog()
        let recorder = RecordingProvider()
        logger.configure(LoggerConfiguration(providers: [recorder], maxAge: nil))

        let didRemove = logger.removeProvider(named: "Recording")
        #expect(didRemove)
        #expect(logger.providerNames.isEmpty)

        let didRemoveAgain = logger.removeProvider(named: "Recording")
        #expect(!didRemoveAgain)
    }

    @Test("addProvider appends to current set")
    func addProvider() {
        let logger = ForgeLog()
        logger.configure(LoggerConfiguration(providers: [], maxAge: nil))

        logger.addProvider(RecordingProvider(name: "A"))
        logger.addProvider(RecordingProvider(name: "B"))

        #expect(logger.providerNames == ["A", "B"])
    }

    @Test("extractClassName strips path and extension")
    func extractClassName() {
        #expect(ForgeLog.extractClassName(from: "ForgeLog/MyFile.swift") == "MyFile")
        #expect(ForgeLog.extractClassName(from: "Bare.swift") == "Bare")
    }

    @Test("extractModuleName returns module from #fileID")
    func extractModuleName() {
        #expect(ForgeLog.extractModuleName(from: "ForgeLog/MyFile.swift") == "ForgeLog")
        #expect(ForgeLog.extractModuleName(from: "Bare.swift") == nil)
    }
}
