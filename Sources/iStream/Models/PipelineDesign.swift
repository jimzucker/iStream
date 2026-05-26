import Foundation

public struct TopicConfig: Equatable, Sendable {
    public var name: String
    public var partitions: Int
    public var replicationFactor: Int
    public var minInSyncReplicas: Int
    public var retentionMs: Int64
    public var cleanupPolicy: String
    public var compressionType: String
}

public struct FlinkConfig: Equatable, Sendable {
    public var parallelism: Int
    public var stateBackend: String
    public var checkpointIntervalMs: Int
    public var checkpointMode: String
    public var watermarkBoundMs: Int
    public var allowedLatenessMs: Int
}

public struct PipelineDesign: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var input: PipelineInput
    public var topic: TopicConfig
    public var flink: FlinkConfig
    public var skewMitigation: [String]
    public var notes: [String]
    public var mermaid: String
    public var markdown: String

    public init(
        id: UUID = UUID(),
        input: PipelineInput,
        topic: TopicConfig,
        flink: FlinkConfig,
        skewMitigation: [String],
        notes: [String],
        mermaid: String,
        markdown: String
    ) {
        self.id = id
        self.input = input
        self.topic = topic
        self.flink = flink
        self.skewMitigation = skewMitigation
        self.notes = notes
        self.mermaid = mermaid
        self.markdown = markdown
    }
}
