# iStream

A command-line tool that designs a Kafka + Flink streaming pipeline from a YAML/JSON
description of the input event: schema, partition key, key distribution, and
throughput/latency targets.

The design engine is rule-based and runs locally — no network, no API keys.

## Install

```bash
dart pub get
dart compile exe bin/istream.dart -o istream
./istream --help
```

Or run without compiling:

```bash
dart run istream design examples/sample.yaml
```

## Usage

```bash
istream design [options] <config>

  -f, --format=<md|json|mermaid>   Output format (default: md).
  -o, --output=<path>              Write to file instead of stdout.
```

Examples:

```bash
istream design examples/sample.yaml                            # Markdown to stdout
istream design examples/sample.yaml -f json | jq '.topic.partitions'
istream design examples/sample.yaml -f mermaid > topology.mmd
istream design - < pipe.yaml                                   # read from stdin
```

Exit codes: `0` ok, `64` usage, `65` config error, `66` I/O error.

## Config file

```yaml
topic_name: events
fields:
  - { name: user_id,    type: string }
  - { name: event_time, type: timestamp }
  - { name: amount,     type: decimal }

partition_key: user_id
cardinality: 1000000
skew: mild              # none | mild | heavy

throughput_eps: 50000
peak_multiplier: 3.0
avg_event_size_bytes: 512
latency_slo_ms: 1000
```

Field types: `string`, `int`, `long`, `double`, `decimal`, `timestamp`, `boolean`, `bytes`.

## What it produces

- **Kafka topic config**: partitions, replication, min ISR, retention, compression.
- **Flink job config**: parallelism, state backend, checkpoint interval & mode,
  watermark bound, allowed lateness.
- **Skew mitigation**: salting + two-stage aggregation for hot keys when needed.
- **Notes**: producer/consumer settings, capacity warnings.
- **Mermaid topology diagram**.

## Heuristics

| Decision | Rule |
|---|---|
| Base partitions | `ceil(peak_eps / 10_000)` and `ceil(peak_bytes / 10 MB/s)`, whichever is larger, floor 3 |
| Skew expansion | none ×1, mild ×2, heavy ×4 |
| Cardinality cap | partitions capped at key cardinality |
| Parallelism | equal to partitions |
| State backend | RocksDB if peak > 50k eps OR partitions > 24 OR skew=heavy; else heap |
| Checkpoint interval | `max(10s, latency_SLO × 5)` |
| Watermark bound | `max(100ms, latency_SLO / 2)` |
| Compression | `zstd` if peak > 50 MB/s, else `lz4` |
| Replication | 3 with `min.insync.replicas=2` |

## Layout

```
pubspec.yaml
analysis_options.yaml
bin/istream.dart           # @main entry → runCli
lib/
  models/                  # Field, SkewLevel, PipelineInput, PipelineDesign
  engine/                  # DesignEngine, MermaidRenderer, MarkdownRenderer
  cli/                     # runner, design_command, config_loader, serializer
examples/sample.yaml
test/
  design_engine_test.dart  # engine coverage
  cli_test.dart            # CLI behavior, exit codes, formats
```

## Develop

```bash
dart pub get
dart analyze --fatal-infos
dart test
```
