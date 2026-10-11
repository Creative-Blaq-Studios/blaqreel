import 'dart:io';

import 'package:blaq_reel/cli/cli.dart';

/// `dart run blaq_reel <command>`, from an app that has blaq_reel as a dev
/// dependency.
Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
  // The studio's server and watchers keep the process alive until Ctrl-C.
  if (args.isEmpty || args.first != 'studio') exit(exitCode);
}
