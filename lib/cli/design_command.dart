import 'dart:io';

import 'package:args/command_runner.dart';

import '../engine/design_engine.dart';
import 'config_loader.dart';
import 'serializer.dart';

class DesignCommand extends Command<int> {
  DesignCommand(this._out, this._err) {
    argParser
      ..addOption(
        'format',
        abbr: 'f',
        allowed: ['md', 'json', 'mermaid'],
        defaultsTo: 'md',
        help: 'Output format.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Write output to file instead of stdout.',
      );
  }

  final IOSink _out;
  final IOSink _err;

  @override
  String get name => 'design';

  @override
  String get description =>
      'Generate a Kafka + Flink pipeline design from a config file.';

  @override
  String get invocation => 'istream design [options] <config>';

  @override
  Future<int> run() async {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 1) {
      _err.writeln('Expected exactly one config path (or - for stdin).');
      _err.writeln(usage);
      return 64;
    }

    final raw = await readInput(rest.first);
    final input = parseConfig(raw);
    final design = DesignEngine.design(input);

    final body = switch (results['format'] as String) {
      'json' => designToJson(design),
      'mermaid' => design.mermaid,
      _ => design.markdown,
    };

    final outputPath = results['output'] as String?;
    if (outputPath != null) {
      await File(outputPath).writeAsString(body);
    } else {
      _out.write(body);
      if (!body.endsWith('\n')) _out.writeln();
    }
    return 0;
  }
}
