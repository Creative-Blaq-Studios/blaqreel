import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// The app the CLI is run in: its root, its `app_reels/`, and what
/// reel.yaml says about rendering.
class Project {
  /// The app's root: where its pubspec.yaml is.
  final Directory root;

  /// A project at [root].
  Project(this.root);

  /// The project the working directory is in, looking up from it for a
  /// pubspec.yaml.
  static Project find() {
    var dir = Directory.current.absolute;
    while (true) {
      if (File('${dir.path}/pubspec.yaml').existsSync()) return Project(dir);
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw const CliError(
          'No pubspec.yaml here or above. Run from the app.',
        );
      }
      dir = parent;
    }
  }

  /// `app_reels/`.
  String get reels => '${root.path}/app_reels';

  /// Whether `app_reels/` has been set up.
  bool get initialized => File('$reels/reel.yaml').existsSync();

  YamlMap get _yaml {
    final file = File('$reels/reel.yaml');
    if (!file.existsSync()) {
      throw const CliError('No app_reels/reel.yaml. Run `blaq_reel init`.');
    }
    final doc = loadYaml(file.readAsStringSync());
    return doc is YamlMap ? doc : YamlMap();
  }

  /// Where output goes, absolute.
  String get out => _abs('${_yaml['out'] ?? 'app_reels/out'}');

  /// The FFmpeg binary.
  String get ffmpeg => '${_yaml['ffmpeg'] ?? 'ffmpeg'}';

  /// Where synthesized sounds go, absolute.
  String get sound => _abs('${_yaml['sound'] ?? 'app_reels/sound'}');

  /// The default format.
  String get format => '${_yaml['format'] ?? 'vertical'}';

  /// The brand as reel.yaml gives it: colours by name, and each font's
  /// family (`packages/my_ui/Gabarito` is `Gabarito`), for pages
  /// that draw in the brand's look.
  Map<String, Object?> get brand {
    final b = _yaml['brand'];
    if (b is! YamlMap) return const {};
    final fonts = b['fonts'];
    return {
      for (final k in ['ink', 'accent', 'paper'])
        if (b[k] != null) k: '${b[k]}',
      if (fonts is YamlMap)
        'fonts': {
          for (final e in fonts.entries)
            '${e.key}': '${e.value}'.split('/').last,
        },
    };
  }

  /// The app's name, from pubspec.yaml.
  String get name {
    final doc = loadYaml(File('${root.path}/pubspec.yaml').readAsStringSync());
    return doc is YamlMap ? '${doc['name']}' : 'app';
  }

  /// Whether the packages were resolved after every pubspec above [root]
  /// last changed (a workspace keeps them at its own root).
  bool get _resolved {
    for (
      Directory? d = root;
      d != null;
      d = d.parent.path == d.path ? null : d.parent
    ) {
      final config = File('${d.path}/.dart_tool/package_config.json');
      if (!config.existsSync()) continue;
      final at = config.lastModifiedSync();
      for (
        Directory? e = root;
        e != null;
        e = e.path == d.path ? null : e.parent
      ) {
        for (final name in ['pubspec.yaml', 'pubspec.lock']) {
          final f = File('${e.path}/$name');
          if (f.existsSync() && f.lastModifiedSync().isAfter(at)) return false;
        }
      }
      return true;
    }
    return false;
  }

  String _abs(String path) =>
      path.startsWith('/') ? path : '${root.path}/$path';

  /// Runs `flutter test app_reels/render_test.dart` with [defines], echoing
  /// BlaqReel's progress lines and any error, and keeping the whole log in
  /// `<out>/last.log`. Returns the exit code.
  Future<int> renderTest(
    Map<String, String> defines, {
    void Function(String line)? onLine,
    bool quiet = false,
  }) async {
    final flutter = Platform.environment['FLUTTER'] ?? 'flutter';
    final args = [
      'test',
      'app_reels/render_test.dart',
      // Resolving packages is a third of a short render; skipped while
      // nothing has changed since they were last resolved.
      if (_resolved) '--no-pub',
      '--timeout',
      'none',
      '--reporter',
      'expanded',
      for (final MapEntry(:key, :value) in defines.entries)
        '--dart-define=$key=$value',
    ];
    Directory(out).createSync(recursive: true);
    final log = File('$out/last.log').openWrite();
    final process = await Process.start(
      flutter,
      args,
      workingDirectory: root.path,
    );
    var failing = false;
    void handle(String line) {
      log.writeln(line);
      onLine?.call(line);
      if (quiet) return;
      if (line.contains('blaq_reel:')) {
        stdout.writeln('  ${line.substring(line.indexOf('blaq_reel:') + 11)}');
      } else if (line.contains('EXCEPTION CAUGHT') ||
          line.contains('[E]') ||
          line.contains('Error:')) {
        failing = true;
        stderr.writeln(line);
      } else if (failing && line.trim().isNotEmpty && !line.startsWith('  ')) {
        stderr.writeln(line);
      }
    }

    final done = [
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(handle),
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(handle),
    ];
    final code = await process.exitCode;
    await Future.wait(done);
    await log.close();
    if (code != 0 && !quiet) {
      stderr.writeln('Render failed. Full log: $out/last.log');
    }
    return code;
  }

  /// Starts `render_test.dart` with [defines] and leaves it running: the
  /// studio's render worker.
  Future<Process> startRenderTest(Map<String, String> defines) {
    Directory(out).createSync(recursive: true);
    return Process.start(Platform.environment['FLUTTER'] ?? 'flutter', [
      'test',
      'app_reels/render_test.dart',
      if (_resolved) '--no-pub',
      '--timeout',
      'none',
      '--reporter',
      'expanded',
      for (final MapEntry(:key, :value) in defines.entries)
        '--dart-define=$key=$value',
    ], workingDirectory: root.path);
  }
}

/// A failure to report without a stack trace.
class CliError implements Exception {
  /// What went wrong, and what to do.
  final String message;

  /// An error.
  const CliError(this.message);

  @override
  String toString() => message;
}
