import Foundation

public enum MermaidRenderer {
    public static func render(
        input: PipelineInput,
        topic: TopicConfig,
        flink: FlinkConfig
    ) -> String {
        let saltSuffix = input.skew == .heavy ? " ++ salt[0..8]" : ""
        let stateLabel = flink.stateBackend.contains("RocksDB") ? "RocksDB" : "heap"
        let secondStage: String
        if input.skew == .heavy {
            secondStage = """
                AGG1 --> KB2{{"keyBy(\(input.partitionKey))"}}
                KB2 --> AGG2["Final aggregate<br/>state: \(stateLabel)"]
                AGG2 --> SINK["Flink Kafka Sink<br/>EXACTLY_ONCE"]
            """
        } else {
            secondStage = """
                AGG1 --> SINK["Flink Kafka Sink<br/>EXACTLY_ONCE"]
            """
        }

        return """
        flowchart LR
            P[Producers] --> K1[("Kafka: \(topic.name)<br/>partitions: \(topic.partitions)<br/>RF: \(topic.replicationFactor)")]
            K1 --> SRC["Flink Kafka Source<br/>parallelism: \(flink.parallelism)"]
            SRC --> WM["Watermarks<br/>bound: \(flink.watermarkBoundMs)ms"]
            WM --> KB1{{"keyBy(\(input.partitionKey)\(saltSuffix))"}}
            KB1 --> AGG1["Window / Aggregate<br/>state: \(stateLabel)"]
        \(secondStage)
            SINK --> K2[("Kafka: \(topic.name)-out<br/>partitions: \(topic.partitions)")]
        """
    }
}
