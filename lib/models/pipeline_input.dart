import 'field.dart';
import 'skew_level.dart';

class PipelineInput {
  const PipelineInput({
    required this.topicName,
    required this.fields,
    required this.partitionKey,
    required this.cardinality,
    required this.skew,
    required this.throughputEventsPerSec,
    required this.peakMultiplier,
    required this.avgEventSizeBytes,
    required this.latencySLOms,
  });

  final String topicName;
  final List<Field> fields;
  final String partitionKey;
  final int cardinality;
  final SkewLevel skew;
  final int throughputEventsPerSec;
  final double peakMultiplier;
  final int avgEventSizeBytes;
  final int latencySLOms;
}
