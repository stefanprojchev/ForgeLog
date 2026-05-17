# ForgeLog

Structured, pluggable logging for iOS and macOS apps.

![Swift 6.3+](https://img.shields.io/badge/Swift-6.3+-orange.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

---

ForgeLog is the logging library in the **Forge** family of iOS packages. One singleton, one configure call, a small set of focused providers. Log entries are structured (level, message, processes, module, metadata), so they can be filtered, exported, or fanned out to remote endpoints without losing fidelity.

The package ships **two targets**:

- **`ForgeLog`** — the structured logger and its SwiftUI inspector (`ForgeLogFlowView`).
- **`ForgeNet`** — a sibling URL-loading interceptor and SwiftUI inspector (`ForgeNetFlowView`) for capturing every `URLRequest` / `URLResponse` your app issues.

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

ForgeLog ships a full SwiftUI log viewer. It owns its own `NavigationStack` via `ForgeLogFlowRouter` — drop the flow view anywhere:

```swift
import SwiftUI
import ForgeLog

struct DebugMenu: View {
    var body: some View {
        ForgeLogFlowView()
    }
}
```

`ForgeLogFlowView` owns a `LiveLogBuffer` (Data layer) that attaches a `LogViewerProvider` to `ForgeLog.shared` — every entry your app emits from that point on shows up in the viewer live. The `LogListViewModel` derives counts, filters, and sparkline buckets from the buffer. The viewer respects the system color scheme by default and persists a per-user override under `@AppStorage("forgeTheme")` (`"system"` / `"dark"` / `"light"`).

> A `ForgeLogView` typealias for `ForgeLogFlowView` is kept for source compatibility, but new code should prefer `ForgeLogFlowView()`.

To customize buffer size and behavior, pass a `LiveLogBufferConfiguration`:

```swift
ForgeLogFlowView(
    bufferConfiguration: LiveLogBufferConfiguration(maxEntries: 5_000)
)
```

The UI is **iOS-only** (also visionOS). On macOS the package still builds; UI types simply aren't present.

### What the viewer exposes

- Live stats strip — entries/sec, paused/live indicator, pause button
- Sparkline by severity over the last 2 seconds
- Per-level counts (All / Debug / Info / Warning / Error) as tappable cards
- Search across message / class / module with 120ms debounce
- Module / Process / Class filter pickers (multi-select with counts)
- Date range picker with quick presets
- Expandable rows with attachment chips (`{·} N`, `NSError`)
- Detail sheet with structured `Parameters` and `Swift Error` sections
- **Settings → Providers** — lists the providers currently attached to `ForgeLog.shared` with each provider's minimum level

## ForgeNet — network inspector

The sibling `ForgeNet` target captures `URLSession` traffic via a custom `URLProtocol` and exposes the same kind of inspector UI for requests and responses.

### Enable capture

```swift
import ForgeNet

@main
struct YourApp: App {
    init() {
        ForgeNet.shared.start()                  // installs ForgeNetURLProtocol globally
        // …or attach to a specific session configuration:
        // ForgeNet.shared.attach(to: configuration)
    }

    var body: some Scene { … }
}
```

Every captured entry is appended to `ForgeNet.shared.buffer` — a `NetworkLogBuffer` holding the latest N `NetworkLogEntry` values.

### Inspector UI

```swift
import SwiftUI
import ForgeNet

struct DebugMenu: View {
    var body: some View {
        ForgeNetFlowView()
    }
}
```

`ForgeNetFlowView` owns a `ForgeNetFlowRouter` (its own `NavigationStack`) and renders list, detail, filters, settings, and concepts screens. A `ForgeNetView` typealias is kept for source compatibility.

The list groups by HTTP status family (1xx–5xx) with tappable cards, supports filtering by method / host / status, and the detail screen breaks each entry into Request / Response / Timing sections.

## The Forge Family

ForgeLog is part of the **Forge** family of Swift packages for iOS.

| Package | Description |
|---|---|
| [ForgeCore](https://github.com/stefanprojchev/ForgeCore) | Thread-safe primitives for iOS Swift packages. |
| [ForgeInject](https://github.com/stefanprojchev/ForgeInject) | Dependency injection with constructor and property wrapper support. |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers — connectivity, lifecycle, keyboard, and more. |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe key-value, file, and Keychain storage. |
| [ForgeDB](https://github.com/stefanprojchev/ForgeDB) | Type-safe repository pattern and GRDB-backed SQLite persistence. |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Orchestrate app flows — startup gates, data pipelines, and continuous monitors. |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, and routing. |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location triggers — geofencing, significant changes, and visits. |
| [ForgeBackgroundTasks](https://github.com/stefanprojchev/ForgeBackgroundTasks) | Background task scheduling and dispatch. |
| [ForgeNetworking](https://github.com/stefanprojchev/ForgeNetworking) | Typed, async/await-first HTTP networking with auth, retry, and background transfers. |
| **ForgeLog** | Structured logging with pluggable providers and a built-in inspector UI. |
| [ForgeAccess](https://github.com/stefanprojchev/ForgeAccess) | Subscription-aware feature gating with override channels and debug UI. |

## License

MIT — see [LICENSE](LICENSE).
