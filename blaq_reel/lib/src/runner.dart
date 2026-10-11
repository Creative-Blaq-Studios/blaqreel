import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'format.dart';
import 'reel.dart';
import 'render.dart';
import 'scene.dart';
import 'time.dart';

/// Builds a reel for a format: the same scenes laid out for each frame.
typedef ReelBuilder = Reel Function(Format format);

/// The whole of an app's `app_reels/render_test.dart`:
///
/// ```dart
/// void main() => blaqReelMain(
///   config: ReelConfig.load('app_reels/reel.yaml'),
///   host: host,
///   reels: {'promo': (format) => promo(config, format)},
/// );
/// ```
///
/// The `blaq_reel` CLI picks what runs with dart-defines:
/// `BLAQ_REEL_TASK` (`video`, `stills`, `preview`, `describe`),
/// `BLAQ_REEL_NAME`, `BLAQ_REEL_FORMATS` (comma-separated, or `all`),
/// `BLAQ_REEL_AT` (seconds, comma-separated), `BLAQ_REEL_FPS`,
/// `BLAQ_REEL_AUDIO` (`off` for none). Run by hand with no task, it
/// registers a video and a stills test per reel, to pick with
/// `--plain-name`.
void blaqReelMain({
  required ReelConfig config,
  required ReelHost host,
  required Map<String, ReelBuilder> reels,
}) {
  const task = String.fromEnvironment('BLAQ_REEL_TASK');
  const name = String.fromEnvironment('BLAQ_REEL_NAME');
  const formats = String.fromEnvironment('BLAQ_REEL_FORMATS');
  const at = String.fromEnvironment('BLAQ_REEL_AT');
  const fps = int.fromEnvironment('BLAQ_REEL_FPS');
  const audio = String.fromEnvironment('BLAQ_REEL_AUDIO');
  const long = Timeout(Duration(minutes: 60));

  final chosen = name.isEmpty || name == 'all'
      ? reels.keys.toList()
      : name.split(',');
  for (final n in chosen) {
    if (!reels.containsKey(n)) {
      throw ArgumentError.value(n, 'BLAQ_REEL_NAME', 'no such reel');
    }
  }
  final List<Format> wanted = switch (formats) {
    '' => [config.format],
    'all' => Format.all,
    _ => [for (final f in formats.split(',')) Format.named(f.trim())],
  };
  final times = at.isEmpty
      ? const [0.5]
      : [for (final s in at.split(',')) double.parse(s.trim())];

  String file(String reel, Format f, String ext) => f == config.format
      ? '${config.out}/$reel.$ext'
      : '${config.out}/$reel-${f.name}.$ext';

  ReelRenderer renderer(WidgetTester tester, Reel reel) => ReelRenderer(
    tester,
    reel,
    host: host,
    fps: fps == 0 ? null : fps,
    ffmpeg: config.ffmpeg,
    sfxDir: config.sound,
  );

  for (final n in chosen) {
    for (final f in wanted) {
      final label = '$n ${f.name}';
      if (task.isEmpty || task == 'video') {
        testWidgets('$label video', (tester) async {
          final r = renderer(tester, reels[n]!(f));
          await r.mount();
          await r.video(file(n, f, 'mp4'), audio: audio != 'off');
        }, timeout: long);
      }
      if (task.isEmpty || task == 'stills') {
        testWidgets('$label stills', (tester) async {
          final r = renderer(tester, reels[n]!(f));
          await r.mount();
          for (final s in times) {
            final stem = f == config.format ? n : '$n-${f.name}';
            await r.still(s.s, '${config.out}/stills/$stem-${s}s.png');
          }
        }, timeout: long);
      }
      if (task == 'preview') {
        testWidgets('$label preview', (tester) async {
          final reel = reels[n]!(f);
          final r = renderer(tester, reel);
          await r.mount();
          final dir = '${config.out}/studio';
          await r.preview('$dir/$n-${f.name}.mp4');
          _writeJson('$dir/$n-${f.name}.json', {
            ...describeReel(reel, fps: r.fps),
            'video': '$n-${f.name}.mp4',
            'rendered': DateTime.now().toIso8601String(),
          });
        }, timeout: long);
      }
      if (task == 'describe') {
        test('$label describe', () {
          _writeJson(
            '${config.out}/studio/$n-${f.name}.json',
            describeReel(reels[n]!(f)),
          );
        });
      }
    }
  }
}

void _writeJson(String path, Object? data) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
}
