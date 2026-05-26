import '../models/pipeline_design.dart';
import '../models/pipeline_input.dart';
import '../models/skew_level.dart';

class MermaidRenderer {
  static String render({
    required PipelineInput input,
    required TopicConfig topic,
    required FlinkConfig flink,
  }) {
    final saltSuffix = input.skew == SkewLevel.heavy ? ' ++ salt[0..8]' : '';
    final stateLabel =
        flink.stateBackend.contains('RocksDB') ? 'RocksDB' : 'heap';

    final secondStage = input.skew == SkewLevel.heavy
        ? '''    AGG1 --> KB2{{"keyBy(${input.partitionKey})"}}
    KB2 --> AGG2["Final aggregate<br/>state: $stateLabel"]
    AGG2 --> SINK["Flink Kafka Sink<br/>EXACTLY_ONCE"]'''
        : '    AGG1 --> SINK["Flink Kafka Sink<br/>EXACTLY_ONCE"]';

    return '''flowchart LR
    P[Producers] --> K1[("Kafka: ${topic.name}<br/>partitions: ${topic.partitions}<br/>RF: ${topic.replicationFactor}")]
    K1 --> SRC["Flink Kafka Source<br/>parallelism: ${flink.parallelism}"]
    SRC --> WM["Watermarks<br/>bound: ${flink.watermarkBoundMs}ms"]
    WM --> KB1{{"keyBy(${input.partitionKey}$saltSuffix)"}}
    KB1 --> AGG1["Window / Aggregate<br/>state: $stateLabel"]
$secondStage
    SINK --> K2[("Kafka: ${topic.name}-out<br/>partitions: ${topic.partitions}")]''';
  }
}
