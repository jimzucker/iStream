import 'dart:convert';

import '../models/pipeline_design.dart';

String designToJson(PipelineDesign d) {
  return const JsonEncoder.withIndent('  ').convert({
    'topic': {
      'name': d.topic.name,
      'partitions': d.topic.partitions,
      'replication_factor': d.topic.replicationFactor,
      'min_insync_replicas': d.topic.minInSyncReplicas,
      'retention_ms': d.topic.retentionMs,
      'cleanup_policy': d.topic.cleanupPolicy,
      'compression_type': d.topic.compressionType,
    },
    'flink': {
      'parallelism': d.flink.parallelism,
      'state_backend': d.flink.stateBackend,
      'checkpoint_interval_ms': d.flink.checkpointIntervalMs,
      'checkpoint_mode': d.flink.checkpointMode,
      'watermark_bound_ms': d.flink.watermarkBoundMs,
      'allowed_lateness_ms': d.flink.allowedLatenessMs,
    },
    'skew_mitigation': d.skewMitigation,
    'notes': d.notes,
    'mermaid': d.mermaid,
  });
}
