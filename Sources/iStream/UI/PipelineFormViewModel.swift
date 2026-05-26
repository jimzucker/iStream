#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class PipelineFormViewModel: ObservableObject {
    @Published public var topicName: String = "events"
    @Published public var fields: [Field] = [
        Field(name: "user_id", type: .string),
        Field(name: "event_time", type: .timestamp),
        Field(name: "amount", type: .decimal),
    ]
    @Published public var partitionKey: String = "user_id"
    @Published public var cardinality: Int = 1_000_000
    @Published public var skew: SkewLevel = .mild
    @Published public var throughputEventsPerSec: Int = 50_000
    @Published public var peakMultiplier: Double = 3.0
    @Published public var avgEventSizeBytes: Int = 512
    @Published public var latencySLOms: Int = 1_000

    public init() {}

    public func build() -> PipelineInput {
        PipelineInput(
            topicName: topicName.isEmpty ? "events" : topicName,
            fields: fields,
            partitionKey: partitionKey,
            cardinality: cardinality,
            skew: skew,
            throughputEventsPerSec: throughputEventsPerSec,
            peakMultiplier: peakMultiplier,
            avgEventSizeBytes: avgEventSizeBytes,
            latencySLOms: latencySLOms
        )
    }

    public func addField() {
        fields.append(Field(name: "field_\(fields.count + 1)", type: .string))
    }

    public func removeFields(at offsets: IndexSet) {
        let removedNames = offsets.map { fields[$0].name }
        fields.remove(atOffsets: offsets)
        if removedNames.contains(partitionKey) {
            partitionKey = fields.first?.name ?? ""
        }
    }
}
#endif
