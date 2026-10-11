import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import '../src/sfx.dart';
import 'init.dart';
import 'pages.dart';
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
        ..addCommand(_Voice())
        ..addCommand(_Map())
        ..addCommand(_Looks())
        ..addCommand(_Storyboard());
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
    final dir = Directory('${project.out}/studio/describe');
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
      'Every reel and rendered video in the browser: preview one live '
      '(re-rendered on save), watch finished videos, scrub, step frames, '
      'take stills, render finals.';

  @override
  String get invocation => 'blaq_reel studio [<reel>]';

  @override
  Future<int> run() async {
    final project = Project.find();
    final r = argResults!;
    var reel = r.rest.isEmpty ? null : r.rest.first;
    if (reel == null) {
      // No reel named: read them all and open on the first.
      stdout.writeln('Reading the reels…');
      await project.renderTest({'BLAQ_REEL_TASK': 'describe'}, quiet: true);
      final dir = Directory('${project.out}/studio/describe');
      final names = dir.existsSync()
          ? (dir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.json'))
                .map(
                  (f) => '${(jsonDecode(f.readAsStringSync()) as Map)['name']}',
                )
                .toSet()
                .toList()
              ..sort())
          : <String>[];
      if (names.isEmpty) throw const CliError('No reels found in app_reels/.');
      reel = names.first;
    }
    final studio = Studio(
      project,
      reel: reel,
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

String _stem(Project p, String reel, String format) =>
    format == p.format ? reel : '$reel-$format';

class _Map extends _ReelCommand {
  @override
  String get name => 'map';

  @override
  String get description =>
      'Show every screen in a reel with each part that could be featured '
      'numbered; choose them on the page.';

  @override
  String get invocation => 'blaq_reel map <reel>';

  @override
  Future<int> run() async {
    final project = Project.find();
    final reel = reelName();
    final r = argResults!;
    stdout.writeln('Mapping the screens in $reel…');
    final code = await project.renderTest({
      'BLAQ_REEL_TASK': 'map',
      'BLAQ_REEL_NAME': reel,
      if (_formats(r).isNotEmpty) 'BLAQ_REEL_FORMATS': _formats(r),
    });
    if (code != 0) return code;
    final dir = '${project.out}/map/$reel';
    final map =
        jsonDecode(File('$dir/map.json').readAsStringSync())
            as Map<String, Object?>;
    File('$dir/index.html').writeAsStringSync(mapPage(map, app: project.name));
    stdout.writeln('Map: $dir/index.html');
    await _open('$dir/index.html');
    return 0;
  }
}

/// Glass Layers' grounds, with a line on each for the page.
const _lookBlurbs = {
  'ink': 'The brand ink with the accent glowing.',
  'mesh': 'Light: soft drifting fields of the accent and its neighbours.',
  'butter': 'The accent, whole, as the ground.',
  'studio': "A photo studio's pale sweep, wall into floor.",
  'grid': 'Dark, with a floor of lines in 3D under the phone.',
  'echo': 'Dark, with the screen itself huge and blurred behind.',
};

class _Looks extends _ReelCommand {
  _Looks() {
    argParser
      ..addOption(
        'at',
        defaultsTo: '4.2',
        help: 'Seconds to compare at, comma-separated.',
      )
      ..addOption(
        'looks',
        defaultsTo: _lookBlurbs.keys.join(','),
        help: 'Which grounds to compare.',
      );
  }

  @override
  String get name => 'looks';

  @override
  String get description =>
      "Render a reel's moments on each Glass Layers ground, side by side, "
      'to choose one.';

  @override
  String get invocation => 'blaq_reel looks <reel> --at 4.2';

  @override
  Future<int> run() async {
    final project = Project.find();
    final reel = reelName();
    final r = argResults!;
    final format = _formats(r).isEmpty ? project.format : _formats(r);
    final looks = (r['looks'] as String).split(',');
    final times = [
      for (final t in (r['at'] as String).split(',')) double.parse(t.trim()),
    ];
    final dir = Directory('${project.out}/looks/$reel')
      ..createSync(recursive: true);
    for (final look in looks) {
      stdout.writeln('  $look…');
      final code = await project.renderTest({
        'BLAQ_REEL_TASK': 'stills',
        'BLAQ_REEL_NAME': reel,
        'BLAQ_REEL_FORMATS': format,
        'BLAQ_REEL_AT': r['at'] as String,
        'BLAQ_REEL_LOOK': look,
      }, quiet: true);
      if (code != 0) {
        stderr.writeln('$look failed: ${project.out}/last.log');
        return code;
      }
      for (final t in times) {
        File(
          '${project.out}/stills/${_stem(project, reel, format)}-${t}s.png',
        ).renameSync('${dir.path}/$look-${t}s.png');
      }
    }
    final page = File('${dir.path}/index.html')
      ..writeAsStringSync(
        looksPage(
          reel: reel,
          app: project.name,
          looks: looks,
          times: times,
          blurbs: _lookBlurbs,
        ),
      );
    stdout.writeln('Looks: ${page.path}');
    await _open(page.path);
    return 0;
  }
}

class _Storyboard extends _ReelCommand {
  @override
  String get name => 'storyboard';

  @override
  String get description =>
      'A frame from every scene with its timing, words and sounds, and room '
      'for notes: approve it before rendering.';

  @override
  String get invocation => 'blaq_reel storyboard <reel>';

  @override
  Future<int> run() async {
    final project = Project.find();
    final reel = reelName();
    final r = argResults!;
    final format = _formats(r).isEmpty ? project.format : _formats(r);
    stdout.writeln('Reading $reel…');
    var code = await project.renderTest({
      'BLAQ_REEL_TASK': 'describe',
      'BLAQ_REEL_NAME': reel,
      'BLAQ_REEL_FORMATS': format,
    }, quiet: true);
    if (code != 0) return code;
    final meta =
        jsonDecode(
              File(
                '${project.out}/studio/describe/$reel-$format.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final scenes = (meta['scenes']! as List).cast<Map<String, Object?>>();
    // Each scene's telling moment: just after its words land, or its middle.
    final times = <double>[];
    for (final s in scenes) {
      final start = (s['start']! as num).toDouble();
      final end = (s['end']! as num).toDouble();
      final words = (s['words']! as List).cast<Map<String, Object?>>();
      final t = words.isEmpty
          ? (start + end) / 2
          : ((words.first['at']! as num).toDouble() + 1.0).clamp(
              start + 0.3,
              end - 0.4,
            );
      times.add(double.parse(t.toStringAsFixed(2)));
    }
    stdout.writeln('Rendering ${times.length} frames…');
    code = await project.renderTest({
      'BLAQ_REEL_TASK': 'stills',
      'BLAQ_REEL_NAME': reel,
      'BLAQ_REEL_FORMATS': format,
      'BLAQ_REEL_AT': times.join(','),
    });
    if (code != 0) return code;
    final dir = Directory('${project.out}/storyboard/$reel')
      ..createSync(recursive: true);
    final frames = <Map<String, Object?>>[];
    for (final (i, t) in times.indexed) {
      final name = 'scene-$i.png';
      File(
        '${project.out}/stills/${_stem(project, reel, format)}-${t}s.png',
      ).copySync('${dir.path}/$name');
      frames.add({'at': t, 'image': name});
    }
    final page = File('${dir.path}/index.html')
      ..writeAsStringSync(
        storyboardPage(reel: meta, app: project.name, frames: frames),
      );
    stdout.writeln('Storyboard: ${page.path}');
    await _open(page.path);
    return 0;
  }
}
