import XCTest
@testable import iStream

final class DesignEngineTests: XCTestCase {

    private func sampleInput(
        skew: SkewLevel = .none,
        eps: Int = 10_000,
        peak: Double = 1.0,
        size: Int = 512,
        slo: Int = 1_000,
        cardinality: Int = 1_000_000
    ) -> PipelineInput {
        PipelineInput(
            topicName: "events",
            fields: [
                Field(name: "user_id", type: .string),
                Field(name: "amount", type: .decimal),
            ],
            partitionKey: "user_id",
            cardinality: cardinality,
            skew: skew,
            throughputEventsPerSec: eps,
            peakMultiplier: peak,
            avgEventSizeBytes: size,
            latencySLOms: slo
        )
    }

    func test_minimumPartitionsIsThree() {
        let d = DesignEngine.design(sampleInput(eps: 100))
        XCTAssertGreaterThanOrEqual(d.topic.partitions, 3)
    }

    func test_partitionsScaleWithThroughput() {
        let low = DesignEngine.design(sampleInput(eps: 10_000))
        let high = DesignEngine.design(sampleInput(eps: 200_000))
        XCTAssertGreaterThan(high.topic.partitions, low.topic.partitions)
    }

    func test_heavySkewMultipliesPartitionsAndAddsMitigation() {
        let none = DesignEngine.design(sampleInput(skew: .none, eps: 50_000))
        let heavy = DesignEngine.design(sampleInput(skew: .heavy, eps: 50_000))
        XCTAssertGreaterThan(heavy.topic.partitions, none.topic.partitions)
        XCTAssertTrue(heavy.skewMitigation.contains { $0.contains("salt") })
        XCTAssertTrue(heavy.flink.stateBackend.contains("RocksDB"))
    }

    func test_parallelismMatchesPartitions() {
        let d = DesignEngine.design(sampleInput(eps: 100_000, skew: .mild))
        XCTAssertEqual(d.flink.parallelism, d.topic.partitions)
    }

    func test_cardinalityCapsPartitions() {
        let d = DesignEngine.design(sampleInput(eps: 1_000_000, peak: 5.0, cardinality: 10))
        XCTAssertLessThanOrEqual(d.topic.partitions, 10)
        XCTAssertTrue(d.notes.contains { $0.contains("cardinality") } || d.topic.partitions <= 10)
    }

    func test_checkpointIntervalRespectsLatencySLO() {
        let tight = DesignEngine.design(sampleInput(slo: 200))
        let loose = DesignEngine.design(sampleInput(slo: 10_000))
        XCTAssertGreaterThanOrEqual(tight.flink.checkpointIntervalMs, 10_000)
        XCTAssertGreaterThan(loose.flink.checkpointIntervalMs, tight.flink.checkpointIntervalMs)
    }

    func test_mermaidContainsTopicAndKey() {
        let d = DesignEngine.design(sampleInput())
        XCTAssertTrue(d.mermaid.contains("events"))
        XCTAssertTrue(d.mermaid.contains("user_id"))
    }

    func test_markdownContainsAllSections() {
        let d = DesignEngine.design(sampleInput(skew: .heavy))
        for section in ["Kafka Topic", "Flink Job", "Skew Mitigation", "Notes", "Topology"] {
            XCTAssertTrue(d.markdown.contains(section), "missing section: \(section)")
        }
    }

    func test_highThroughputPicksZstdCompression() {
        let d = DesignEngine.design(sampleInput(eps: 500_000, size: 2_000))
        XCTAssertEqual(d.topic.compressionType, "zstd")
    }
}
