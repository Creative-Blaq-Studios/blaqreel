import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import '../src/sfx.dart';
import 'init.dart';
import 'project.dart';
import 'studio.dart';

/// Runs the `blaq_reel` command line with [args]. Returns the exit code.
Future<int> runCli(List<String> args) async {
  final runner =
      CommandRunner<int>(
          'blaq_reel',
          'Promo videos from your Flutter app\'s real screens.',
        )
        ..addCommand(_Init())
        ..addCommand(_Doctor())
        ..addCommand(_List())
        ..addCommand(_Render())
        ..addCommand(_Stills())
        ..addCommand(_Studio())
        ..addCommand(_Sfx())
        ..addCommand(_Voice());
  try {
    return await runner.run(args) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    return 64;
  } on CliError catch (e) {
    stderr.writeln(e.message);
    return 1;
  }
}

String _formats(ArgResults r) => r['format'] as String? ?? '';

Future<void> _open(String path) async {
  if (Platform.isMacOS) {
    await Process.run('open', [path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [path]);
  }
}

class _Init extends Command<int> {
  _Init() {
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Overwrite files that are already there.',
    );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Set up app_reels/: reel.yaml, the host adapter, a first reel, '
      'and the guide.';

  @override
  Future<int> run() async {
    final project = Project.find();
    final survey = AppSurvey.of(project);
    final written = initReels(project, force: argResults!['force'] as bool);
    stdout.writeln('BlaqReel for ${survey.name}');
    for (final f in written) {
      stdout.writeln('  ✓ $f');
    }
    if (written.isEmpty) stdout.writeln('  app_reels/ is already set up.');
    stdout
      ..writeln('  state management: ${survey.state}')
      ..writeln('  screens found: ${survey.screens.length}')
      ..writeln(
        '  colours guessed: ink ${survey.ink}, accent ${survey.accent}, '
        'paper ${survey.paper}',
      )
      ..writeln(
        'Next: fill in app_reels/host.dart, then '
        '`dart run blaq_reel stills first --at 1,3`.',
      );
    final ignore = File('${project.root.path}/.gitignore');
    if (ignore.existsSync() &&
        !ignore.readAsStringSync().contains('app_reels/out')) {
      ignore.writeAsStringSync(
        '\n# BlaqReel output\napp_reels/out/\napp_reels/sound/\n',
        mode: FileMode.append,
      );
      stdout.writeln('  ✓ .gitignore: app_reels/out/, app_reels/sound/');
    }
    return 0;
  }
}

class _Doctor extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check FFmpeg, Flutter and app_reels/.';

  @override
  Future<int> run() async {
    var ok = true;
    final project = Project.find();
    final ffmpeg = project.initialized ? project.ffmpeg : 'ffmpeg';
    try {
      final v = await Process.run(ffmpeg, ['-hide_banner', '-version']);
      final line = '${v.stdout}'.split('\n').first;
      stdout.writeln('✓ $line');
      final enc = await Process.run(ffmpeg, ['-hide_banner', '-encoders']);
      if ('${enc.stdout}'.contains('libx264')) {
        stdout.writeln('✓ libx264');
      } else {
        ok = false;
        stdout.writeln('✗ FFmpeg has no libx264 encoder');
      }
      final filters = await Process.run(ffmpeg, ['-hide_banner', '-filters']);
      for (final f in ['tmix', 'noise', 'loudnorm', 'sidechaincompress']) {
        final has = RegExp('\\s$f\\s').hasMatch('${filters.stdout}');
        stdout.writeln('${has ? '✓' : '✗'} filter $f');
        ok &= has;
      }
    } on ProcessException {
      ok = false;
      stdout.writeln('✗ FFmpeg not found at "$ffmpeg"');
    }
    try {
      final flutter = Platform.environment['FLUTTER'] ?? 'flutter';
      final v = await Process.run(flutter, ['--version']);
      stdout.writeln('✓ ${'${v.stdout}'.split('\n').first}');
    } on ProcessException {
      ok = false;
      stdout.writeln('✗ flutter not on PATH (or set FLUTTER)');
    }
    if (project.initialized) {
      stdout.writeln('✓ app_reels/ in ${project.name}');
    } else {
      ok = false;
      stdout.writeln('✗ no app_reels/: run `dart run blaq_reel init`');
    }
    return ok ? 0 : 1;
  }
}

class _List extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description => 'The reels, their scenes and lengths.';

  @override
  Future<int> run() async {
    final project = Project.find();
    final dir = Directory('${project.out}/studio');
    final before = DateTime.now();
    final code = await project.renderTest({
      'BLAQ_REEL_TASK': 'describe',
    }, quiet: true);
    if (code != 0) {
      throw CliError('Could not read the reels: ${project.out}/last.log');
    }
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json') && f.lastModifiedSync().isAfter(before),
    );
    for (final f in files.toList()..sort((a, b) => a.path.compareTo(b.path))) {
      final r = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final scenes = (r['scenes']! as List).cast<Map<String, Object?>>();
      stdout.writeln(
        '${r['name']}  ${r['format']}  ${(r['length']! as num).toStringAsFixed(1)}s  '
        '${scenes.length} scenes',
      );
      for (final s in scenes) {
        stdout.writeln(
          '  ${(s['start']! as num).toStringAsFixed(2).padLeft(6)}s  ${s['name']}',
        );
      }
    }
    return 0;
  }
}

abstract class _ReelCommand extends Command<int> {
  _ReelCommand() {
    argParser
      ..addOption(
        'format',
        abbr: 'f',
        help: 'vertical, wide, square, portrait, a comma list, or all.',
      )
      ..addOption('fps', help: 'Frames per second, overriding the reel.')
      ..addFlag('open', negatable: false, help: 'Open the result.');
  }

  String reelName() {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Name a reel.', usage);
    return rest.first;
  }
}

class _Render extends _ReelCommand {
  _Render() {
    argParser.addFlag('audio', defaultsTo: true, help: 'Mix the soundtrack.');
  }

  @override
  String get name => 'render';

  @override
  String get description => 'Render a reel to MP4.';

  @override
  String get invocation => 'blaq_reel render <reel> [--format all]';

  @override
  Future<int> run() async {
    final project = Project.find();
    final reel = reelName();
    final r = argResults!;
    stdout.writeln('Rendering $reel…');
    final code = await project.renderTest({
      'BLAQ_REEL_TASK': 'video',
      'BLAQ_REEL_NAME': reel,
      if (_formats(r).isNotEmpty) 'BLAQ_REEL_FORMATS': _formats(r),
      if (r['fps'] != null) 'BLAQ_REEL_FPS': r['fps'] as String,
      if (!(r['audio'] as bool)) 'BLAQ_REEL_AUDIO': 'off',
    });
    if (code == 0 && r['open'] as bool) {
      await _open('${project.out}/$reel.mp4');
    }
    return code;
  }
}

class _Stills extends _ReelCommand {
  _Stills() {
    argParser.addOption(
      'at',
      defaultsTo: '0.5',
      help: 'Seconds, comma-separated.',
    );
  }

  @override
  String get name => 'stills';

  @override
  String get description => 'Save PNG stills of a reel at given seconds.';

  @override
  String get invocation => 'blaq_reel stills <reel> --at 1,3.5';

  @override
  Future<int> run() async {
    final project = Project.find();
    final reel = reelName();
    final r = argResults!;
    final code = await project.renderTest({
      'BLAQ_REEL_TASK': 'stills',
      'BLAQ_REEL_NAME': reel,
      'BLAQ_REEL_AT': r['at'] as String,
      if (_formats(r).isNotEmpty) 'BLAQ_REEL_FORMATS': _formats(r),
    });
    if (code == 0) {
      stdout.writeln('Stills in ${project.out}/stills/');
      if (r['open'] as bool) await _open('${project.out}/stills');
    }
    return code;
  }
}

class _Studio extends Command<int> {
  _Studio() {
    argParser
      ..addOption('format', abbr: 'f', help: 'The format to preview.')
      ..addOption('port', defaultsTo: '4455')
      ..addFlag('watch', defaultsTo: true, help: 'Re-render on changes.')
      ..addFlag('open', defaultsTo: true, help: 'Open the browser.');
  }

  @override
  String get name => 'studio';

  @override
  String get description =>
      'Preview a reel in the browser: scrub, step frames, take stills; '
      're-renders when a file changes.';

  @override
  String get invocation => 'blaq_reel studio <reel>';

  @override
  Future<int> run() async {
    final project = Project.find();
    final r = argResults!;
    if (r.rest.isEmpty) throw UsageException('Name a reel.', usage);
    final studio = Studio(
      project,
      reel: r.rest.first,
      format: r['format'] as String? ?? project.format,
      port: int.parse(r['port'] as String),
      watch: r['watch'] as bool,
    );
    await studio.serve(
      onReady: (uri) {
        stdout.writeln('Studio at $uri  (Ctrl-C to stop)');
        if (r['open'] as bool) unawaited(_open('$uri'));
      },
    );
    await ProcessSignal.sigint.watch().first;
    return 0;
  }
}

class _Sfx extends Command<int> {
  _Sfx() {
    argParser.addOption(
      'pad',
      help: 'Also write a placeholder pad this many seconds long.',
    );
  }

  @override
  String get name => 'sfx';

  @override
  String get description =>
      'Write the built-in sounds (${Sfx.sources.keys.join(', ')}) to '
      'reel.yaml\'s sound folder.';

  @override
  Future<int> run() async {
    final project = Project.find();
    for (final name in Sfx.sources.keys) {
      stdout.writeln('  ✓ ${Sfx.resolve(name, project.sound, project.ffmpeg)}');
    }
    final pad = argResults!['pad'] as String?;
    if (pad != null) {
      final seconds = int.parse(pad);
      final path = '${project.sound}/pad-${seconds}s.m4a';
      Sfx.pad(path, Duration(seconds: seconds), project.ffmpeg);
      stdout.writeln('  ✓ $path');
    }
    return 0;
  }
}

class _Voice extends Command<int> {
  _Voice() {
    argParser
      ..addOption('text', help: 'One line to speak.')
      ..addOption('out', help: 'Where to write it (.m4a).')
      ..addOption(
        'script',
        help: 'A YAML map of name: line; writes <name>.m4a beside it.',
      )
      ..addOption('voice', defaultsTo: 'Tessa', help: 'A macOS voice.')
      ..addOption('rate', defaultsTo: '172', help: 'Words per minute.');
  }

  @override
  String get name => 'voice';

  @override
  String get description =>
      'Placeholder voice-over with the macOS speech voices, until real lines '
      'are recorded.';

  @override
  Future<int> run() async {
    final r = argResults!;
    final project = Project.find();
    final jobs = <(String, String)>[];
    final script = r['script'] as String?;
    if (script != null) {
      final file = File(script);
      final doc = loadYaml(file.readAsStringSync());
      if (doc is! YamlMap) throw CliError('$script is not a YAML map');
      for (final MapEntry(:key, :value) in doc.entries) {
        jobs.add(('${file.parent.path}/$key.m4a', '$value'));
      }
    } else {
      final text = r['text'] as String?;
      final out = r['out'] as String?;
      if (text == null || out == null) {
        throw UsageException('Give --text and --out, or --script.', usage);
      }
      jobs.add((out, text));
    }
    for (final (out, text) in jobs) {
      final aiff = '$out.aiff';
      File(out).parent.createSync(recursive: true);
      final said = await Process.run('say', [
        '-v',
        r['voice'] as String,
        '-r',
        r['rate'] as String,
        '-o',
        aiff,
        text,
      ]);
      if (said.exitCode != 0) throw CliError('say failed: ${said.stderr}');
      final enc = await Process.run(project.ffmpeg, [
        '-y',
        '-loglevel',
        'error',
        '-i',
        aiff,
        '-af',
        'highpass=f=80,acompressor=threshold=-18dB:ratio=3,loudnorm=I=-16',
        '-ar',
        '48000',
        '-c:a',
        'aac',
        '-b:a',
        '160k',
        out,
      ]);
      File(aiff).deleteSync();
      if (enc.exitCode != 0) throw CliError('ffmpeg failed: ${enc.stderr}');
      stdout.writeln('  ✓ $out  "$text"');
    }
    return 0;
  }
}
