import 'pipeline_input.dart';

class TopicConfig {
  const TopicConfig({
    required this.name,
    required this.partitions,
    required this.replicationFactor,
    required this.minInSyncReplicas,
    required this.retentionMs,
    required this.cleanupPolicy,
    required this.compressionType,
  });

  final String name;
  final int partitions;
  final int replicationFactor;
  final int minInSyncReplicas;
  final int retentionMs;
  final String cleanupPolicy;
  final String compressionType;
}

class FlinkConfig {
  const FlinkConfig({
    required this.parallelism,
    required this.stateBackend,
    required this.checkpointIntervalMs,
    required this.checkpointMode,
    required this.watermarkBoundMs,
    required this.allowedLatenessMs,
  });

  final int parallelism;
  final String stateBackend;
  final int checkpointIntervalMs;
  final String checkpointMode;
  final int watermarkBoundMs;
  final int allowedLatenessMs;
}

class PipelineDesign {
  const PipelineDesign({
    required this.input,
    required this.topic,
    required this.flink,
    required this.skewMitigation,
    required this.notes,
    required this.mermaid,
    required this.markdown,
  });

  final PipelineInput input;
  final TopicConfig topic;
  final FlinkConfig flink;
  final List<String> skewMitigation;
  final List<String> notes;
  final String mermaid;
  final String markdown;
}
