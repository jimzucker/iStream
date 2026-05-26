import 'dart:convert';
import 'dart:io';

import 'package:istream/cli/runner.dart';
import 'package:test/test.dart';

class _Sink implements IOSink {
  final StringBuffer _buf = StringBuffer();
  @override
  Encoding encoding = utf8;

  @override
  void write(Object? obj) => _buf.write(obj);
  @override
  void writeln([Object? obj = '']) {
    _buf.write(obj);
    _buf.write('\n');
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _buf.write(objects.join(separator));
  @override
  void writeCharCode(int charCode) => _buf.writeCharCode(charCode);
  @override
  void add(List<int> data) => _buf.write(utf8.decode(data));
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future close() async {}
  @override
  Future get done async {}
  @override
  Future flush() async {}

  @override
  String toString() => _buf.toString();
}

const _sampleYaml = '''
topic_name: events
fields:
  - { name: user_id, type: string }
  - { name: amount, type: decimal }
partition_key: user_id
cardinality: 1000000
skew: heavy
throughput_eps: 100000
peak_multiplier: 2.0
avg_event_size_bytes: 256
latency_slo_ms: 500
''';

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('istream_cli_test_');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  File writeConfig(String name, String body) {
    final f = File('${tmp.path}/$name')..writeAsStringSync(body);
    return f;
  }

  test('design --format=md writes markdown to stdout', () async {
    final cfg = writeConfig('cfg.yaml', _sampleYaml);
    final out = _Sink();
    final err = _Sink();
    final code = await runCli(['design', cfg.path], out, err);
    expect(code, 0);
    expect(out.toString(), contains('Kafka + Flink Pipeline Design'));
    expect(out.toString(), contains('keyBy(user_id'));
  });

  test('design --format=json emits valid JSON with topic/flink', () async {
    final cfg = writeConfig('cfg.yaml', _sampleYaml);
    final out = _Sink();
    final err = _Sink();
    final code =
        await runCli(['design', '--format=json', cfg.path], out, err);
    expect(code, 0);
    final decoded = jsonDecode(out.toString()) as Map<String, dynamic>;
    expect(decoded['topic']['partitions'], isA<int>());
    expect(decoded['flink']['parallelism'], decoded['topic']['partitions']);
    expect(decoded['skew_mitigation'], isA<List<dynamic>>());
  });

  test('design --format=mermaid emits only the diagram', () async {
    final cfg = writeConfig('cfg.yaml', _sampleYaml);
    final out = _Sink();
    final err = _Sink();
    final code =
        await runCli(['design', '--format=mermaid', cfg.path], out, err);
    expect(code, 0);
    expect(out.toString(), startsWith('flowchart LR'));
    expect(out.toString().contains('# Kafka'), isFalse);
  });

  test('design -o writes to file and skips stdout', () async {
    final cfg = writeConfig('cfg.yaml', _sampleYaml);
    final outFile = '${tmp.path}/out.md';
    final out = _Sink();
    final err = _Sink();
    final code = await runCli(['design', '-o', outFile, cfg.path], out, err);
    expect(code, 0);
    expect(out.toString(), isEmpty);
    expect(File(outFile).readAsStringSync(), contains('Kafka + Flink'));
  });

  test('missing config file returns exit 66', () async {
    final out = _Sink();
    final err = _Sink();
    final code =
        await runCli(['design', '${tmp.path}/nope.yaml'], out, err);
    expect(code, 66);
    expect(err.toString(), contains('not found'));
  });

  test('partition_key not in schema returns exit 65', () async {
    final cfg = writeConfig('bad.yaml', '''
topic_name: events
fields:
  - { name: user_id, type: string }
partition_key: missing_field
cardinality: 100
skew: none
throughput_eps: 1000
peak_multiplier: 1.0
avg_event_size_bytes: 100
latency_slo_ms: 1000
''');
    final out = _Sink();
    final err = _Sink();
    final code = await runCli(['design', cfg.path], out, err);
    expect(code, 65);
    expect(err.toString(), contains('partition_key'));
  });

  test('no args prints usage and returns exit 64', () async {
    final out = _Sink();
    final err = _Sink();
    final code = await runCli(['design'], out, err);
    expect(code, 64);
    expect(err.toString(), contains('config path'));
  });
}
