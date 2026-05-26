import Foundation

public struct PipelineInput: Equatable, Sendable {
    public var topicName: String
    public var fields: [Field]
    public var partitionKey: String
    public var cardinality: Int
    public var skew: SkewLevel
    public var throughputEventsPerSec: Int
    public var peakMultiplier: Double
    public var avgEventSizeBytes: Int
    public var latencySLOms: Int

    public init(
        topicName: String,
        fields: [Field],
        partitionKey: String,
        cardinality: Int,
        skew: SkewLevel,
        throughputEventsPerSec: Int,
        peakMultiplier: Double,
        avgEventSizeBytes: Int,
        latencySLOms: Int
    ) {
        self.topicName = topicName
        self.fields = fields
        self.partitionKey = partitionKey
        self.cardinality = cardinality
        self.skew = skew
        self.throughputEventsPerSec = throughputEventsPerSec
        self.peakMultiplier = peakMultiplier
        self.avgEventSizeBytes = avgEventSizeBytes
        self.latencySLOms = latencySLOms
    }
}
