# iStream

A Flutter app that designs a Kafka + Flink streaming pipeline from a description of the
input event: its schema, partition key, key distribution, and throughput/latency targets.

The design engine is rule-based and runs entirely on-device — no network, no API keys.
Works on iOS, Android, web, and desktop from a single codebase.

## What it produces

- **Kafka topic config**: partitions, replication factor, min ISR, retention, compression.
- **Flink job config**: parallelism, state backend (heap vs RocksDB), checkpoint
  interval & mode, watermark bound, allowed lateness.
- **Skew mitigation plan**: salting + two-stage aggregation for hot keys.
- **Notes**: producer/consumer settings, capacity warnings.
- **Mermaid topology diagram** and a full **Markdown design doc** you can copy.

## Inputs

- Schema: list of `(name, type)` fields.
- Partition key: one of the fields.
- Cardinality of the key.
- Skew level: `None` / `Mild` / `Heavy`.
- Base throughput (events/sec) and a peak multiplier.
- Average event size (bytes).
- Latency SLO (ms).

## Heuristics

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
pubspec.yaml
analysis_options.yaml
lib/
  main.dart                       # @main entry → MaterialApp → PipelineFormScreen
  models/                         # Field, SkewLevel, PipelineInput, PipelineDesign
  engine/                         # DesignEngine, MermaidRenderer, MarkdownRenderer
  ui/
    pipeline_form_screen.dart     # Form: schema, key/distro, targets
    result_screen.dart            # Cards: topic, flink, skew, notes, mermaid, markdown
    sections/                     # Reusable form sections
test/
  design_engine_test.dart         # Engine coverage
```

## Setup

The repo does not commit the generated `ios/`, `android/`, `web/`, or `macos/`
platform folders. Generate them once:

```bash
flutter create --project-name istream --platforms=ios,android,web .
flutter pub get
```

## Test

```bash
flutter test
```

## Run

```bash
flutter run                       # picks an attached device or simulator
flutter run -d chrome             # web
flutter run -d "iPhone 15 Pro"    # specific iOS simulator
```

Minimum Flutter: **3.24** / Dart **3.5**.
