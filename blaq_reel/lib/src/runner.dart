import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backdrop.dart';
import 'format.dart';
import 'reel.dart';
import 'render.dart';
import 'camera.dart';
import 'layer.dart';
import 'scene.dart';
import 'spec.dart';
import 'stage.dart';
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
  ReelKit? kit,
  String specs = 'app_reels/specs',
}) {
  // Reels the studio's builder wrote, as data, beside the ones in Dart.
  if (kit != null) {
    reels = {
      ...reels,
      for (final MapEntry(:key, :value) in ReelSpec.all(specs).entries)
        key: (format) =>
            value.build(name: key, kit: kit, config: config, format: format),
    };
  }
  const task = String.fromEnvironment('BLAQ_REEL_TASK');
  const name = String.fromEnvironment('BLAQ_REEL_NAME');
  const formats = String.fromEnvironment('BLAQ_REEL_FORMATS');
  const at = String.fromEnvironment('BLAQ_REEL_AT');
  const fps = int.fromEnvironment('BLAQ_REEL_FPS');
  const audio = String.fromEnvironment('BLAQ_REEL_AUDIO');
  const long = Timeout(Duration(minutes: 60));

  if (task == 'catalogue') {
    if (kit == null) throw StateError('The catalogue needs a ReelKit.');
    testWidgets('catalogue', (tester) async {
      await _catalogue(tester, host, kit, config);
    }, timeout: long);
    return;
  }

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
          await r.close();
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
          await r.close();
        }, timeout: long);
      }
      if (task == 'preview') {
        testWidgets('$label preview', (tester) async {
          final reel = reels[n]!(f);
          final r = renderer(tester, reel);
          await r.mount();
          final dir = '${config.out}/studio';
          await r.preview('$dir/$n-${f.name}.mp4');
          await r.close();
          _writeJson('$dir/$n-${f.name}.json', {
            ...describeReel(reel, fps: r.fps),
            'video': '$n-${f.name}.mp4',
            'rendered': DateTime.now().toIso8601String(),
          });
        }, timeout: long);
      }
      if (task == 'map') {
        testWidgets('$label map', (tester) async {
          await _map(tester, renderer, reels[n]!(f), '${config.out}/map/$n');
        }, timeout: long);
      }
      if (task == 'describe') {
        test('$label describe', () {
          // Apart from the previews' own JSON, which names a video.
          _writeJson(
            '${config.out}/studio/describe/$n-${f.name}.json',
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

/// Draws each distinct screen in [reel] flat, and lists what in it could be
/// featured, into [dir]: a PNG per screen and `map.json`.
Future<void> _map(
  WidgetTester tester,
  ReelRenderer Function(WidgetTester, Reel) renderer,
  Reel reel,
  String dir,
) async {
  // Widgets the app's own code made are "local": the app and the packages
  // beside it, not Flutter or pub's cache.
  final here = Directory.current.absolute.path;
  // The inspector's own way to say which code is the app's; it is protected
  // only to keep it out of app code, and this is tooling.
  // ignore: invalid_use_of_protected_member
  WidgetInspectorService.instance.addPubRootDirectories([
    here,
    Directory(here).parent.path,
  ]);
  final r = renderer(tester, reel);
  await r.mount();
  final stage = tester.state<ReelStageState>(find.byType(ReelStage));
  Directory(dir).createSync(recursive: true);
  final seen = <Widget>{};
  final screens = <Map<String, Object?>>[];
  for (final span in reel.timeline) {
    for (final (j, layer) in span.scene.layers.indexed) {
      if (!layer.isScreen || !seen.add(layer.child)) continue;
      // After its transition in: until then the scene may not be painted.
      await r.seek(
        span.start +
            (span.enter?.length ?? Duration.zero) +
            const Duration(milliseconds: 50),
      );
      final boundary = stage.screenBoundary((span.index, j));
      if (boundary == null || boundary.debugNeedsPaint) continue;
      final file = 'screen-${span.index}-$j.png';
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('$dir/$file').writeAsBytesSync(png!.buffer.asUint8List());
      });
      final parts = stage.mapScreen((span.index, j));
      screens.add({
        'scene': span.scene.name,
        'start': span.start.inMilliseconds / 1000,
        'image': file,
        'screen': layer.child.runtimeType.toString(),
        'width': layer.size.width,
        'height': layer.size.height,
        'parts': [for (final p in parts) p.toJson()],
      });
    }
  }
  _writeJson('$dir/map.json', {'reel': reel.name, 'screens': screens});
  await r.close();
}

/// Every screen in [kit], drawn flat with its featurable parts listed, for
/// the builder: `<out>/studio/catalogue/`.
Future<void> _catalogue(
  WidgetTester tester,
  ReelHost host,
  ReelKit kit,
  ReelConfig config,
) async {
  final ids = kit.screens.keys.toList();
  final reel = Reel(
    name: 'catalogue',
    backdrop: const Backdrop(top: Color(0xFF000000), bottom: Color(0xFF000000)),
    scenes: [
      for (final id in ids)
        Scene(
          name: id,
          length: const Duration(seconds: 1),
          camera: Camera.still(const CameraPose(zoom: 0.5)),
          layers: [
            if (kit.screens[id]!.size case final size?)
              Layer.component(kit.screens[id]!.widget, size: size)
            else
              Layer.screen(
                kit.screens[id]!.widget,
                statusBar: kit.statusBar,
                scrolls: kit.screens[id]!.scrolls,
              ),
          ],
        ),
    ],
  );
  final dir = '${config.out}/studio/catalogue';
  await _map(
    tester,
    (t, r) => ReelRenderer(t, r, host: host, ffmpeg: config.ffmpeg),
    reel,
    dir,
  );
  // Name each screen by its id and label rather than its scene.
  final file = File('$dir/map.json');
  final map = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  for (final s in (map['screens']! as List).cast<Map<String, Object?>>()) {
    final id = '${s['scene']}';
    s['id'] = id;
    s['label'] = kit.screens[id]?.label ?? id;
    s['kind'] = kit.screens[id]?.isComponent ?? false ? 'component' : 'screen';
  }
  _writeJson(file.path, map);
}
