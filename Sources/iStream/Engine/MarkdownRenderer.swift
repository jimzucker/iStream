import Foundation

public enum MarkdownRenderer {
    public static func render(
        input: PipelineInput,
        topic: TopicConfig,
        flink: FlinkConfig,
        skewMitigation: [String],
        notes: [String],
        mermaid: String
    ) -> String {
        let fieldsTable = input.fields
            .map { "| `\($0.name)` | `\($0.type.rawValue)` |" }
            .joined(separator: "\n")

        let stateBackendKey = flink.stateBackend.contains("RocksDB") ? "rocksdb" : "hashmap"
        let peakEPS = Int((Double(input.throughputEventsPerSec) * input.peakMultiplier).rounded())

        let skewBlock = skewMitigation.map { "- \($0)" }.joined(separator: "\n")
        let notesBlock = notes.map { "- \($0)" }.joined(separator: "\n")

        return """
        # Kafka + Flink Pipeline Design

        _Generated for `\(input.topicName)` keyed on `\(input.partitionKey)` (skew: \(input.skew.rawValue))_

        ## Inputs

        | Field | Type |
        |---|---|
        \(fieldsTable)

        - Partition key: `\(input.partitionKey)`
        - Cardinality: \(input.cardinality)
        - Base throughput: \(input.throughputEventsPerSec) events/sec
        - Peak: ×\(String(format: "%.1f", input.peakMultiplier)) → \(peakEPS) events/sec
        - Avg event size: \(input.avgEventSizeBytes) bytes
        - Latency SLO: \(input.latencySLOms) ms

        ## Kafka Topic

        ```bash
        kafka-topics.sh --create \\
          --topic \(topic.name) \\
          --partitions \(topic.partitions) \\
          --replication-factor \(topic.replicationFactor) \\
          --config min.insync.replicas=\(topic.minInSyncReplicas) \\
          --config retention.ms=\(topic.retentionMs) \\
          --config cleanup.policy=\(topic.cleanupPolicy) \\
          --config compression.type=\(topic.compressionType)
        ```

        ## Flink Job

        ```yaml
        parallelism.default: \(flink.parallelism)
        state.backend: \(stateBackendKey)
        state.backend.incremental: true
        execution.checkpointing.interval: \(flink.checkpointIntervalMs)ms
        execution.checkpointing.mode: \(flink.checkpointMode)
        ```

        - Watermark bound: \(flink.watermarkBoundMs) ms
        - Allowed lateness: \(flink.allowedLatenessMs) ms

        ## Skew Mitigation

        \(skewBlock)

        ## Notes

        \(notesBlock)

        ## Topology

        ```mermaid
        \(mermaid)
        ```
        """
    }
}
