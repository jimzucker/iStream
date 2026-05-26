import 'dart:io';

import 'package:args/command_runner.dart';

import 'config_loader.dart';
import 'design_command.dart';

Future<int> runCli(List<String> args, IOSink out, IOSink err) async {
  final runner = CommandRunner<int>(
    'istream',
    'Designs Kafka + Flink pipelines from event schema and throughput targets.',
  )..addCommand(DesignCommand(out, err));

  try {
    final code = await runner.run(args);
    return code ?? 0;
  } on UsageException catch (e) {
    err.writeln(e);
    return 64;
  } on ConfigError catch (e) {
    err.writeln('Config error: ${e.message}');
    return 65;
  } on FileSystemException catch (e) {
    err.writeln('I/O error: ${e.message}${e.path != null ? ' (${e.path})' : ''}');
    return 66;
  }
}
