import 'dart:io';

import 'package:istream/cli/runner.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args, stdout, stderr);
}
