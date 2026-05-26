import Foundation

public enum DesignEngine {

    public static let targetEventsPerPartitionPerSec = 10_000
    public static let targetBytesPerPartitionPerSec  = 10_000_000

    public static func design(_ input: PipelineInput) -> PipelineDesign {
        let peakEPS = Double(input.throughputEventsPerSec) * input.peakMultiplier
        let peakBPS = peakEPS * Double(input.avgEventSizeBytes)

        let byEvents = Int((peakEPS / Double(targetEventsPerPartitionPerSec)).rounded(.up))
        let byBytes  = Int((peakBPS / Double(targetBytesPerPartitionPerSec)).rounded(.up))
        let basePartitions = max(byEvents, byBytes, 3)

        let skewMultiplier: Int
        switch input.skew {
        case .none:  skewMultiplier = 1
        case .mild:  skewMultiplier = 2
        case .heavy: skewMultiplier = 4
        }
        var partitions = basePartitions * skewMultiplier

        if input.cardinality > 0 {
            partitions = min(partitions, max(input.cardinality, 3))
        }

        let parallelism = partitions
        let useRocksDB = peakEPS > 50_000 || partitions > 24 || input.skew == .heavy
        let stateBackend = useRocksDB
            ? "RocksDB (incremental checkpoints)"
            : "HashMap (in-memory)"

        let checkpointIntervalMs = max(10_000, input.latencySLOms * 5)
        let watermarkBoundMs = max(100, input.latencySLOms / 2)
        let allowedLatenessMs = input.latencySLOms

        let topic = TopicConfig(
            name: input.topicName,
            partitions: partitions,
            replicationFactor: 3,
            minInSyncReplicas: 2,
            retentionMs: 7 * 24 * 3_600_000,
            cleanupPolicy: "delete",
            compressionType: peakBPS > 50_000_000 ? "zstd" : "lz4"
        )

        let flink = FlinkConfig(
            parallelism: parallelism,
            stateBackend: stateBackend,
            checkpointIntervalMs: checkpointIntervalMs,
            checkpointMode: "EXACTLY_ONCE",
            watermarkBoundMs: watermarkBoundMs,
            allowedLatenessMs: allowedLatenessMs
        )

        var skewMitigation: [String] = []
        switch input.skew {
        case .none:
            skewMitigation.append("No skew expected — straight `keyBy(\(input.partitionKey))` is safe.")
        case .mild:
            skewMitigation.append("Add a local pre-aggregator (combiner) before `keyBy(\(input.partitionKey))` to reduce shuffle volume.")
            skewMitigation.append("Use `.rebalance()` for stateless map/filter stages so partitions stay balanced.")
        case .heavy:
            skewMitigation.append("Two-stage aggregation: keyBy(\(input.partitionKey) ++ salt[0..8]) → partial agg → keyBy(\(input.partitionKey)) → final agg.")
            skewMitigation.append("Pre-aggregate inside a `KeyedProcessFunction` with TTL'd ValueState.")
            skewMitigation.append("Isolate hot subtasks with slot-sharing groups; watch backpressure per task-manager.")
        }

        var notes: [String] = []
        notes.append("Producers: `enable.idempotence=true`, `acks=all`, `max.in.flight.requests.per.connection<=5`.")
        notes.append("Flink Kafka source: `isolation.level=read_committed` to honor EXACTLY_ONCE.")
        if input.cardinality > 0 && input.cardinality < partitions {
            notes.append("⚠️ Key cardinality (\(input.cardinality)) < partitions (\(partitions)) — some partitions will be idle. Lower partition count or rely on salting.")
        }
        if input.peakMultiplier >= 5 {
            notes.append("Peak multiplier ≥ 5× — enable Flink reactive mode or pre-scale TMs; budget Kafka broker headroom.")
        }
        if peakBPS > 100_000_000 {
            notes.append("Throughput > 100 MB/s — consider tiered storage on Kafka and SSD-backed RocksDB on Flink TMs.")
        }

        let mermaid = MermaidRenderer.render(input: input, topic: topic, flink: flink)
        let markdown = MarkdownRenderer.render(
            input: input,
            topic: topic,
            flink: flink,
            skewMitigation: skewMitigation,
            notes: notes,
            mermaid: mermaid
        )

        return PipelineDesign(
            input: input,
            topic: topic,
            flink: flink,
            skewMitigation: skewMitigation,
            notes: notes,
            mermaid: mermaid,
            markdown: markdown
        )
    }
}
