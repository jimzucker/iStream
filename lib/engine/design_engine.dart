import 'dart:math' as math;

import '../models/pipeline_design.dart';
import '../models/pipeline_input.dart';
import '../models/skew_level.dart';
import 'markdown_renderer.dart';
import 'mermaid_renderer.dart';

class DesignEngine {
  static const int targetEventsPerPartitionPerSec = 10000;
  static const int targetBytesPerPartitionPerSec = 10000000;

  static PipelineDesign design(PipelineInput input) {
    final peakEPS = input.throughputEventsPerSec * input.peakMultiplier;
    final peakBPS = peakEPS * input.avgEventSizeBytes;

    final byEvents = (peakEPS / targetEventsPerPartitionPerSec).ceil();
    final byBytes = (peakBPS / targetBytesPerPartitionPerSec).ceil();
    final basePartitions = math.max(math.max(byEvents, byBytes), 3);

    final skewMultiplier = switch (input.skew) {
      SkewLevel.none => 1,
      SkewLevel.mild => 2,
      SkewLevel.heavy => 4,
    };
    var partitions = basePartitions * skewMultiplier;

    if (input.cardinality > 0) {
      partitions = math.min(partitions, math.max(input.cardinality, 3));
    }

    final parallelism = partitions;
    final useRocksDB = peakEPS > 50000 ||
        partitions > 24 ||
        input.skew == SkewLevel.heavy;
    final stateBackend = useRocksDB
        ? 'RocksDB (incremental checkpoints)'
        : 'HashMap (in-memory)';

    final checkpointIntervalMs = math.max(10000, input.latencySLOms * 5);
    final watermarkBoundMs = math.max(100, input.latencySLOms ~/ 2);
    final allowedLatenessMs = input.latencySLOms;

    final topic = TopicConfig(
      name: input.topicName,
      partitions: partitions,
      replicationFactor: 3,
      minInSyncReplicas: 2,
      retentionMs: 7 * 24 * 3600 * 1000,
      cleanupPolicy: 'delete',
      compressionType: peakBPS > 50000000 ? 'zstd' : 'lz4',
    );

    final flink = FlinkConfig(
      parallelism: parallelism,
      stateBackend: stateBackend,
      checkpointIntervalMs: checkpointIntervalMs,
      checkpointMode: 'EXACTLY_ONCE',
      watermarkBoundMs: watermarkBoundMs,
      allowedLatenessMs: allowedLatenessMs,
    );

    final skewMitigation = <String>[];
    switch (input.skew) {
      case SkewLevel.none:
        skewMitigation.add(
          'No skew expected — straight `keyBy(${input.partitionKey})` is safe.',
        );
        break;
      case SkewLevel.mild:
        skewMitigation.add(
          'Add a local pre-aggregator (combiner) before `keyBy(${input.partitionKey})` to reduce shuffle volume.',
        );
        skewMitigation.add(
          'Use `.rebalance()` for stateless map/filter stages so partitions stay balanced.',
        );
        break;
      case SkewLevel.heavy:
        skewMitigation.add(
          'Two-stage aggregation: keyBy(${input.partitionKey} ++ salt[0..8]) → partial agg → keyBy(${input.partitionKey}) → final agg.',
        );
        skewMitigation.add(
          "Pre-aggregate inside a `KeyedProcessFunction` with TTL'd ValueState.",
        );
        skewMitigation.add(
          'Isolate hot subtasks with slot-sharing groups; watch backpressure per task-manager.',
        );
        break;
    }

    final notes = <String>[];
    notes.add(
      'Producers: `enable.idempotence=true`, `acks=all`, `max.in.flight.requests.per.connection<=5`.',
    );
    notes.add(
      'Flink Kafka source: `isolation.level=read_committed` to honor EXACTLY_ONCE.',
    );
    if (input.cardinality > 0 && input.cardinality < partitions) {
      notes.add(
        '⚠️ Key cardinality (${input.cardinality}) < partitions ($partitions) — some partitions will be idle. Lower partition count or rely on salting.',
      );
    }
    if (input.peakMultiplier >= 5) {
      notes.add(
        'Peak multiplier ≥ 5× — enable Flink reactive mode or pre-scale TMs; budget Kafka broker headroom.',
      );
    }
    if (peakBPS > 100000000) {
      notes.add(
        'Throughput > 100 MB/s — consider tiered storage on Kafka and SSD-backed RocksDB on Flink TMs.',
      );
    }

    final mermaid = MermaidRenderer.render(
      input: input,
      topic: topic,
      flink: flink,
    );
    final markdown = MarkdownRenderer.render(
      input: input,
      topic: topic,
      flink: flink,
      skewMitigation: skewMitigation,
      notes: notes,
      mermaid: mermaid,
    );

    return PipelineDesign(
      input: input,
      topic: topic,
      flink: flink,
      skewMitigation: skewMitigation,
      notes: notes,
      mermaid: mermaid,
      markdown: markdown,
    );
  }
}
