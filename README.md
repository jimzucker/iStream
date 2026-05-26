# iStream

An iPhone app that designs a Kafka + Flink streaming pipeline from a description of the
input event: its schema, partition key, key distribution, and throughput/latency targets.

The design engine is rule-based and runs entirely on-device — no network, no API keys.

## What it produces

- **Kafka topic config**: partitions, replication factor, min ISR, retention, compression.
- **Flink job config**: parallelism, state backend (heap vs RocksDB), checkpoint
  interval & mode, watermark bound, allowed lateness.
- **Skew mitigation plan**: salting + two-stage aggregation for hot keys.
- **Notes**: producer/consumer settings, capacity warnings.
- **Mermaid topology diagram** and a full **Markdown design doc** you can copy or share.

## Inputs

- Schema: list of `(name, type)` fields.
- Partition key: one of the fields.
- Cardinality of the key.
- Skew level: `None` / `Mild` / `Heavy`.
- Base throughput (events/sec) and a peak multiplier.
- Average event size (bytes).
- Latency SLO (ms).

## Heuristics (cheat sheet)

| Decision | Rule |
|---|---|
| Base partitions | `ceil(peak_eps / 10_000)` and `ceil(peak_bytes / 10 MB/s)`, whichever is larger, floor 3 |
| Skew expansion | none ×1, mild ×2, heavy ×4 |
| Cardinality cap | partitions capped at key cardinality (with a floor of 3) |
| Parallelism | equal to partitions |
| State backend | RocksDB if peak > 50k eps OR partitions > 24 OR skew=heavy; else heap |
| Checkpoint interval | `max(10s, latency_SLO × 5)` |
| Watermark bound | `max(100ms, latency_SLO / 2)` |
| Compression | `zstd` if peak > 50 MB/s, else `lz4` |
| Replication | 3 with `min.insync.replicas=2` |

Skew handling:

- **mild**: pre-aggregate before `keyBy`; `.rebalance()` for stateless ops.
- **heavy**: two-stage aggregation — `keyBy(key ++ salt[0..8])` → partial agg →
  `keyBy(key)` → final agg.

## Layout

```
Package.swift              # SwiftPM manifest, library target `iStream`
Sources/iStream/
  Models/                  # Field, SkewLevel, PipelineInput, PipelineDesign
  Engine/                  # DesignEngine, MermaidRenderer, MarkdownRenderer, Clipboard
  UI/                      # SwiftUI views + form view-model
App/iStreamApp.swift       # @main entry — copy into your Xcode app target
Tests/iStreamTests/        # XCTest coverage of the engine
```

## Running the engine tests

The engine is platform-agnostic and runs under SwiftPM on macOS:

```bash
swift test
```

The SwiftUI views are guarded by `#if canImport(SwiftUI)` so the package builds even
where SwiftUI is absent.

## Building the iPhone app

Swift Package Manager can't produce an `.app` bundle on its own. To run on a device or
simulator:

1. Open Xcode 15+ → **File ▸ New ▸ Project… ▸ iOS ▸ App**.
   - Product Name: `iStream`
   - Interface: SwiftUI, Language: Swift
2. **File ▸ Add Package Dependencies… ▸ Add Local…** and pick this repo directory.
   Add `iStream` to your app target.
3. Replace the generated `ContentView.swift` / `iStreamApp.swift` with the contents of
   [`App/iStreamApp.swift`](App/iStreamApp.swift) (or just paste:

   ```swift
   import SwiftUI
   import iStream

   @main
   struct iStreamApp: App {
       var body: some Scene {
           WindowGroup { iStreamRootView() }
       }
   }
   ```
4. Build & run on an iPhone simulator.

Minimum deployment target: **iOS 17** (uses `NavigationStack`, `ShareLink`, `.sheet(item:)`).
