# ForgeLog

Structured, pluggable logging for iOS and macOS apps.

![Swift 6.3+](https://img.shields.io/badge/Swift-6.3+-orange.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

---

ForgeLog is the logging library in the **Forge** family of iOS packages. One singleton, one configure call, a small set of focused providers. Log entries are structured (level, message, processes, module, metadata), so they can be filtered, exported, or fanned out to remote endpoints without losing fidelity.

Built on Swift 6 strict concurrency. No `@unchecked Sendable`, no `NSLock` — internal synchronization uses [`LockedState`](https://github.com/stefanprojchev/ForgeCore) (Swift `Mutex` under the hood) and file I/O goes through `SendableFileManager`.

## Features

- **Structured entries** — level, message, class/function/line, module, processes, and arbitrary `Codable` metadata.
- **Pluggable providers** — print, `os.Logger`, JSONL disk, plain text disk, crash-context ring buffer, NotificationCenter, remote HTTP batching, and decorator-based filtering.
- **Automatic purging** — by age, by total size, or both (whichever hits first).
- **Strict concurrency** — `Sendable` end-to-end, no escape hatches.
- **Zero `@unchecked Sendable`** — built on `ForgeCore.LockedState` and `SendableFileManager`.

## Requirements

- **iOS** 18+
- **macOS** 15+
- **Swift** 6.3+ (Xcode 26 or later)

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/stefanprojchev/ForgeLog.git`
3. Set rule to **Up to Next Major** from `1.0.0`

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeLog.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ForgeLog"]
    )
]
```

## Quick Start

```swift
import ForgeLog

@main
struct YourApp: App {
    init() {
        ForgeLog.shared.configure()
    }

    var body: some Scene { … }
}

// Anywhere in your app:
ForgeLog.shared.info("App launched")
ForgeLog.shared.warning("Cache miss", metadata: ["key": .string(cacheKey)])
ForgeLog.shared.error("Sync failed", metadata: error)
```

By default, the logger runs four providers: `PrintLogProvider`, `ConsoleLogProvider`, `DiskLogProvider`, and `CrashContextProvider`.

## Configuration

```swift
ForgeLog.shared.configure(
    LoggerConfiguration(
        providers: ForgeLog.defaultProviders + [
            FileExportLogProvider(),
        ],
        maxAge: .days(14),
        maxTotalSize: .mb(50),
        isDebugEnabled: true
    )
)
```

`maxAge` and `maxTotalSize` are both type-safe enums (`LogAge`, `StorageSize`). The purge runs once on `configure()`.

> The `#if DEBUG` check for `isDebugEnabled` must happen in your **app target**, not in this library — the library's compile configuration is independent of yours.

## Providers

| Provider | What it does |
|---|---|
| `PrintLogProvider` | `print()` to Xcode console |
| `ConsoleLogProvider` | Apple `os.Logger` — visible in Console.app |
| `DiskLogProvider` | Appends JSONL to `Application Support/Logs/` (read back by `LogStore`) |
| `FileExportLogProvider` | Plain text files in `Application Support/Logs/PlainText/` — shareable directly |
| `CrashContextProvider` | In-memory ring buffer for attaching to crash reports |
| `NotificationCenterLogProvider` | Posts an `NSNotification` per entry, for reactive overlays |
| `FilteredLogProvider` | Decorator that applies a custom filter before forwarding to a wrapped provider |
| `RemoteLogProvider` | Batches entries and POSTs them to an HTTP endpoint with retry on 5xx/network errors |

### Filtering example

```swift
let onlyPayments = FilteredLogProvider(
    wrapping: DiskLogProvider(),
    process: "Payments"
)
ForgeLog.shared.addProvider(onlyPayments)
```

### Remote logging example

```swift
let remote = RemoteLogProvider(
    endpoint: URL(string: "https://logs.example.com/ingest")!,
    headers: ["Authorization": "Bearer \(token)"],
    batchSize: 50,
    flushInterval: 30
)
ForgeLog.shared.addProvider(remote)
```

## Metadata

Pass an `Error`, any `Encodable`, or an arbitrary dictionary as metadata:

```swift
ForgeLog.shared.error("Network call failed", metadata: error)
ForgeLog.shared.info("User updated", metadata: user)            // user is Encodable
ForgeLog.shared.debug("Cache hit", metadata: ["key": .string("posts")])

// Merge multiple sources:
ForgeLog.shared.error("Update failed", metadata: error.asMetadata + user.asLogMetadata)
```

## Reading and exporting logs

```swift
let store = LogStore()
let dates = try await store.availableLogDates()
let today = try await store.loadEntries(for: Date())

let exporter = LogExporter()
let exportURL = try await exporter.export(today, format: .json)
// Hand exportURL to UIActivityViewController, etc.
```

## UI

Log-viewing UI is delivered separately and is not bundled with this package. The handoff design package owns visual identity for the Forge family.

## License

MIT — see [LICENSE](LICENSE).
