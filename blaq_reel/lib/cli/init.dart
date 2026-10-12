import 'dart:io';
import 'dart:math' as math;

import 'package:yaml/yaml.dart';

import 'project.dart';

/// What `init` reads from an app before writing `app_reels/`.
class AppSurvey {
  /// The package name.
  final String name;

  /// Font families declared in pubspec.yaml.
  final List<String> fonts;

  /// Colours that appear most in lib/, most frequent first, as #RRGGBB.
  final List<String> colors;

  /// Screen classes found in lib/: `(class, import)`.
  final List<(String, String)> screens;

  /// `riverpod`, `bloc`, `get_it`, `provider` or `none`.
  final String state;

  /// A survey.
  const AppSurvey({
    required this.name,
    required this.fonts,
    required this.colors,
    required this.screens,
    required this.state,
  });

  /// Surveys [project].
  factory AppSurvey.of(Project project) {
    final pubspec = loadYaml(
      File('${project.root.path}/pubspec.yaml').readAsStringSync(),
    );
    final name = pubspec is YamlMap ? '${pubspec['name']}' : 'app';
    final fonts = <String>[];
    final deps = <String>{};
    if (pubspec is YamlMap) {
      final flutter = pubspec['flutter'];
      if (flutter is YamlMap && flutter['fonts'] is YamlList) {
        for (final f in flutter['fonts'] as YamlList) {
          if (f is YamlMap) fonts.add('${f['family']}');
        }
      }
      for (final key in ['dependencies', 'dev_dependencies']) {
        final d = pubspec[key];
        if (d is YamlMap) deps.addAll(d.keys.map((k) => '$k'));
      }
    }
    final state =
        deps.contains('hooks_riverpod') || deps.contains('flutter_riverpod')
        ? 'riverpod'
        : deps.contains('flutter_bloc')
        ? 'bloc'
        : deps.contains('get_it')
        ? 'get_it'
        : deps.contains('provider')
        ? 'provider'
        : 'none';

    final counts = <String, int>{};
    final screens = <(String, String)>[];
    final lib = Directory('${project.root.path}/lib');
    if (lib.existsSync()) {
      final color = RegExp(r'Color\(0x[fF]{2}([0-9a-fA-F]{6})\)');
      final screen = RegExp(r'class (\w+Screen) extends');
      for (final f in lib.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
        final text = f.readAsStringSync();
        for (final m in color.allMatches(text)) {
          final hex = '#${m.group(1)!.toUpperCase()}';
          counts[hex] = (counts[hex] ?? 0) + 1;
        }
        for (final m in screen.allMatches(text)) {
          final rel = f.path.substring(lib.path.length + 1);
          screens.add((m.group(1)!, 'package:$name/$rel'));
        }
      }
    }
    final colors = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    screens.sort((a, b) => a.$1.compareTo(b.$1));
    return AppSurvey(
      name: name,
      fonts: fonts,
      colors: colors.take(12).toList(),
      screens: screens,
      state: state,
    );
  }

  static double _luma(String hex) {
    final v = int.parse(hex.substring(1), radix: 16);
    final r = (v >> 16) & 0xFF, g = (v >> 8) & 0xFF, b = v & 0xFF;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _chroma(String hex) {
    final v = int.parse(hex.substring(1), radix: 16);
    final r = (v >> 16) & 0xFF, g = (v >> 8) & 0xFF, b = v & 0xFF;
    return (math.max(r, math.max(g, b)) - math.min(r, math.min(g, b))) / 255;
  }

  /// The darkest of the common colours.
  String get ink => colors.isEmpty
      ? '#111111'
      : colors.reduce((a, b) => _luma(a) <= _luma(b) ? a : b);

  /// The lightest.
  String get paper => colors.isEmpty
      ? '#F5F5F5'
      : colors.reduce((a, b) => _luma(a) >= _luma(b) ? a : b);

  /// The most colourful.
  String get accent => colors.isEmpty
      ? '#FF6B00'
      : colors.reduce((a, b) => _chroma(a) >= _chroma(b) ? a : b);
}

/// Writes `app_reels/` for [project]. Existing files are kept unless
/// [force] is set. Returns the files written.
List<String> initReels(Project project, {bool force = false}) {
  final s = AppSurvey.of(project);
  final ffmpeg = _which('ffmpeg') ?? 'ffmpeg';
  final first = s.screens.isEmpty ? null : s.screens.first;
  final files = <String, String>{
    'reel.yaml': _reelYaml(s, ffmpeg),
    'host.dart': _host(s),
    'render_test.dart': _renderTest(s),
    'cuts/first.dart': _firstCut(s, first),
    'REELS.md': _guide(s),
    // The studio's scratch reel: a beat, the intro or the outro on its own.
    '.gitignore': 'out/\nsound/\nspecs/_beat.json\n',
    'music/.gitkeep': '',
    'voice/.gitkeep': '',
    'scenes/.gitkeep': '',
  };
  final written = <String>[];
  for (final MapEntry(:key, :value) in files.entries) {
    final file = File('${project.reels}/$key');
    if (file.existsSync() && !force) continue;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(value);
    written.add('app_reels/$key');
  }
  return written;
}

String? _which(String bin) {
  for (final dir in [
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    ...(Platform.environment['PATH'] ?? '').split(':'),
  ]) {
    if (File('$dir/$bin').existsSync()) return '$dir/$bin';
  }
  return null;
}

String _reelYaml(AppSurvey s, String ffmpeg) {
  final display = s.fonts.isEmpty ? 'Roboto' : s.fonts.first;
  final text = s.fonts.length > 1 ? s.fonts[1] : display;
  return '''
# BlaqReel: ${s.name}'s promo reels. See REELS.md.
name: ${s.name}
fps: 30
format: vertical # vertical 1080x1920 · wide 1920x1080 · square · portrait 4:5
out: app_reels/out
ffmpeg: $ffmpeg
music: pad # a synthesized placeholder; point at a track in app_reels/music/
sound: app_reels/sound

brand:
  # Guessed from the colours lib/ uses most: check them.
  ink: "${s.ink}"
  accent: "${s.accent}"
  paper: "${s.paper}"
  # Other common colours: ${s.colors.join(', ')}
  fonts:
    # A font in a package is "packages/<package>/<family>".
    display: $display
    text: $text
''';
}

String _host(AppSurvey s) {
  final wrap = switch (s.state) {
    'riverpod' =>
      '''
  wrap: (screen) => ProviderScope(
    // TODO: the overrides your widget tests use for demo data.
    overrides: const [],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      // TODO: your app's theme.
      home: screen,
    ),
  ),''',
    'bloc' =>
      '''
  wrap: (screen) => MultiRepositoryProvider(
    // TODO: fake repositories with demo data, as in your widget tests.
    providers: const [],
    child: MaterialApp(debugShowCheckedModeBanner: false, home: screen),
  ),''',
    'get_it' =>
      '''
  // TODO: register fakes with demo data in GetIt before the reel mounts,
  // as your widget tests do.
  wrap: (screen) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: screen),''',
    _ =>
      '''
  wrap: (screen) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: screen),''',
  };
  final imports = switch (s.state) {
    'riverpod' => "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
    'bloc' => "import 'package:flutter_bloc/flutter_bloc.dart';\n",
    _ => '',
  };
  return '''
// BlaqReel's one adapter for ${s.name}: given a screen, return it ready to
// draw — the app's theme, fonts and demo data, and no backend. Your widget
// tests already do this; copy from them.
import 'package:blaq_reel/blaq_reel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
$imports
final host = ReelHost(
$wrap
  // Load the app's fonts, or every glyph draws as a box.
  ready: (tester) async {
    await tester.runAsync(loadFonts);
    await tester.pumpAndSettle();
  },
);

/// Loads the fonts reel.yaml names. Add every family the screens use.
Future<void> loadFonts() async {
  // TODO: one FontLoader per family, with its files:
  // final loader = FontLoader('Inter')
  //   ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'));
  // await loader.load();
}
''';
}

String _renderTest(AppSurvey s) =>
    '''
// Renders ${s.name}'s reels. Outside test/, so the normal `flutter test` run
// never picks it up. Use the CLI from the app's root:
//
//   dart run blaq_reel render first
//   dart run blaq_reel studio first
import 'package:blaq_reel/blaq_reel.dart';

import 'cuts/first.dart';
import 'host.dart';

void main() {
  final config = ReelConfig.load('app_reels/reel.yaml');
  blaqReelMain(
    config: config,
    host: host,
    reels: {'first': (format) => first(config, format)},
  );
}
''';

String _firstCut(AppSurvey s, (String, String)? screen) {
  final import = screen == null ? '' : "import '${screen.$2}';\n";
  final widget = screen == null
      ? 'const Placeholder() // TODO: a screen'
      : 'const ${screen.$1}() // TODO: its demo state';
  return '''
// A first reel: one Glass Layers beat. Add beats, pick what lifts, and look
// at stills before rendering: `dart run blaq_reel stills first --at 1,3`.
import 'package:blaq_reel/blaq_reel.dart';
import 'package:blaq_reel/packs.dart';
import 'package:flutter/material.dart';
$import
Reel first(ReelConfig config, Format format) => GlassLayers(
  brand: Brand.from(config),
  format: format,
  fps: config.fps,
  music: config.music == null ? null : Music(config.music!),
  beats: [
    GlassBeat(
      'Hello.',
      screen: $widget,
      // TODO: what lifts off the screen, e.g. Pick.type<Card>().
      lift: [Pick.type<Card>()],
    ),
  ],
).build('first');
''';
}

String _guide(AppSurvey s) =>
    '''
# Reels for ${s.name}

Promo videos rendered from ${s.name}'s real screens by
[BlaqReel](https://github.com/Creative-Blaq-Studios/BlaqReel). Nothing here
ships in the app.

## Commands (from the app's root)

| | |
| --- | --- |
| `dart run blaq_reel list` | the reels, their scenes and lengths |
| `dart run blaq_reel stills <reel> --at 1,3.5` | PNGs at those seconds, in `out/stills/` |
| `dart run blaq_reel studio <reel>` | a scrubber in the browser that re-renders when a scene changes |
| `dart run blaq_reel render <reel> [--format all]` | the MP4s, in `out/` |
| `dart run blaq_reel sfx` | the built-in sounds and the placeholder pad, in `sound/` |

## Files

- `reel.yaml`: brand colours and faces, fps, format, music, FFmpeg.
- `host.dart`: the one adapter. Given a screen, return it drawable with
  demo data. State management found: **${s.state}**.
- `cuts/`: whole reels, usually a style pack (`GlassLayers`) with beats.
- `scenes/`: scenes written straight from the blocks, when no pack fits.
- `music/`, `voice/`: tracks and voice-over lines.
- `out/`, `sound/`: generated; git-ignored.

## Screens in lib/

${s.screens.isEmpty ? '_None found._' : s.screens.map((e) => '- `${e.$1}`, `${e.$2}`').join('\n')}

## How a reel is written

A reel is Dart: a pack (`GlassLayers(beats: [...])`) or scenes built from
the blocks: `Layer`, `Layer.screen`, `Lift`, `Tap`, `Scroll`, `TypeText`,
`Camera`, `Words`, `Backdrop`, `Transition`, `Soundtrack`. Pick widgets in a
screen with `Pick`: `Pick.type<WalletCard>()`, `Pick.text('Done')`,
`Pick.type<Card>().containing(Pick.text('Total'))`, `Pick.typeName('_Private')`.
Look at stills at the moments that matter, fix, look again, then render.
''';
