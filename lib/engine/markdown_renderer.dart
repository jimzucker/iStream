import '../models/pipeline_design.dart';
import '../models/pipeline_input.dart';

class MarkdownRenderer {
  static String render({
    required PipelineInput input,
    required TopicConfig topic,
    required FlinkConfig flink,
    required List<String> skewMitigation,
    required List<String> notes,
    required String mermaid,
  }) {
    final fieldsTable = input.fields
        .map((f) => '| `${f.name}` | `${f.type.label}` |')
        .join('\n');

    final stateBackendKey =
        flink.stateBackend.contains('RocksDB') ? 'rocksdb' : 'hashmap';
    final peakEPS =
        (input.throughputEventsPerSec * input.peakMultiplier).round();

    final skewBlock = skewMitigation.map((s) => '- $s').join('\n');
    final notesBlock = notes.map((s) => '- $s').join('\n');

    return '''# Kafka + Flink Pipeline Design

_Generated for `${input.topicName}` keyed on `${input.partitionKey}` (skew: ${input.skew.label})_

## Inputs

| Field | Type |
|---|---|
$fieldsTable

- Partition key: `${input.partitionKey}`
- Cardinality: ${input.cardinality}
- Base throughput: ${input.throughputEventsPerSec} events/sec
- Peak: ×${input.peakMultiplier.toStringAsFixed(1)} → $peakEPS events/sec
- Avg event size: ${input.avgEventSizeBytes} bytes
- Latency SLO: ${input.latencySLOms} ms

## Kafka Topic

```bash
kafka-topics.sh --create \\
  --topic ${topic.name} \\
  --partitions ${topic.partitions} \\
  --replication-factor ${topic.replicationFactor} \\
  --config min.insync.replicas=${topic.minInSyncReplicas} \\
  --config retention.ms=${topic.retentionMs} \\
  --config cleanup.policy=${topic.cleanupPolicy} \\
  --config compression.type=${topic.compressionType}
```

## Flink Job

```yaml
parallelism.default: ${flink.parallelism}
state.backend: $stateBackendKey
state.backend.incremental: true
execution.checkpointing.interval: ${flink.checkpointIntervalMs}ms
execution.checkpointing.mode: ${flink.checkpointMode}
```

- Watermark bound: ${flink.watermarkBoundMs} ms
- Allowed lateness: ${flink.allowedLatenessMs} ms

## Skew Mitigation

$skewBlock

## Notes

$notesBlock

## Topology

```mermaid
$mermaid
```
''';
  }
}
