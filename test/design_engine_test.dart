import 'package:flutter_test/flutter_test.dart';
import 'package:istream/engine/design_engine.dart';
import 'package:istream/models/field.dart';
import 'package:istream/models/pipeline_input.dart';
import 'package:istream/models/skew_level.dart';

PipelineInput sampleInput({
  SkewLevel skew = SkewLevel.none,
  int eps = 10000,
  double peak = 1.0,
  int size = 512,
  int slo = 1000,
  int cardinality = 1000000,
}) {
  return PipelineInput(
    topicName: 'events',
    fields: [
      Field(name: 'user_id', type: FieldType.stringType),
      Field(name: 'amount', type: FieldType.decimalType),
    ],
    partitionKey: 'user_id',
    cardinality: cardinality,
    skew: skew,
    throughputEventsPerSec: eps,
    peakMultiplier: peak,
    avgEventSizeBytes: size,
    latencySLOms: slo,
  );
}

void main() {
  group('DesignEngine', () {
    test('minimum partitions is three', () {
      final d = DesignEngine.design(sampleInput(eps: 100));
      expect(d.topic.partitions, greaterThanOrEqualTo(3));
    });

    test('partitions scale with throughput', () {
      final low = DesignEngine.design(sampleInput(eps: 10000));
      final high = DesignEngine.design(sampleInput(eps: 200000));
      expect(high.topic.partitions, greaterThan(low.topic.partitions));
    });

    test('heavy skew multiplies partitions and adds mitigation', () {
      final none = DesignEngine.design(
        sampleInput(skew: SkewLevel.none, eps: 50000),
      );
      final heavy = DesignEngine.design(
        sampleInput(skew: SkewLevel.heavy, eps: 50000),
      );
      expect(heavy.topic.partitions, greaterThan(none.topic.partitions));
      expect(
        heavy.skewMitigation.any((s) => s.contains('salt')),
        isTrue,
      );
      expect(heavy.flink.stateBackend.contains('RocksDB'), isTrue);
    });

    test('parallelism matches partitions', () {
      final d = DesignEngine.design(
        sampleInput(eps: 100000, skew: SkewLevel.mild),
      );
      expect(d.flink.parallelism, equals(d.topic.partitions));
    });

    test('cardinality caps partitions', () {
      final d = DesignEngine.design(
        sampleInput(eps: 1000000, peak: 5.0, cardinality: 10),
      );
      expect(d.topic.partitions, lessThanOrEqualTo(10));
    });

    test('checkpoint interval respects latency SLO', () {
      final tight = DesignEngine.design(sampleInput(slo: 200));
      final loose = DesignEngine.design(sampleInput(slo: 10000));
      expect(tight.flink.checkpointIntervalMs, greaterThanOrEqualTo(10000));
      expect(
        loose.flink.checkpointIntervalMs,
        greaterThan(tight.flink.checkpointIntervalMs),
      );
    });

    test('mermaid contains topic and key', () {
      final d = DesignEngine.design(sampleInput());
      expect(d.mermaid.contains('events'), isTrue);
      expect(d.mermaid.contains('user_id'), isTrue);
    });

    test('markdown contains all sections', () {
      final d = DesignEngine.design(sampleInput(skew: SkewLevel.heavy));
      for (final section in [
        'Kafka Topic',
        'Flink Job',
        'Skew Mitigation',
        'Notes',
        'Topology',
      ]) {
        expect(d.markdown.contains(section), isTrue, reason: 'missing $section');
      }
    });

    test('high throughput picks zstd compression', () {
      final d = DesignEngine.design(sampleInput(eps: 500000, size: 2000));
      expect(d.topic.compressionType, equals('zstd'));
    });
  });
}
