import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audio.dart';
import 'reel.dart';
import 'scene.dart';
import 'stage.dart';
import 'time.dart';

/// Renders a [Reel] inside a widget test: frame by frame on a fixed clock,
/// each frame captured from the stage and handed to FFmpeg, or saved alone
/// as a still.
///
/// ```dart
/// testWidgets('promo', (tester) async {
///   final r = ReelRenderer(tester, promo, host: host);
///   await r.mount();
///   await r.video('app_reels/out/promo.mp4');
/// });
/// ```
class ReelRenderer {
  /// The test's tester.
  final WidgetTester tester;

  /// The reel.
  final Reel reel;

  /// How the app's screens are drawn.
  final ReelHost host;

  /// Frames per second, overriding the reel's.
  final int fps;

  /// The FFmpeg binary.
  final String ffmpeg;

  /// Where the built-in sounds are kept once synthesized.
  final String sfxDir;

  final _time = ValueNotifier<Duration>(Duration.zero);
  final _boundary = GlobalKey();
  Duration _last = const Duration(microseconds: -1);

  /// A renderer.
  ReelRenderer(
    this.tester,
    this.reel, {
    required this.host,
    int? fps,
    this.ffmpeg = 'ffmpeg',
    this.sfxDir = 'app_reels/sound',
  }) : fps = fps ?? reel.fps;

  /// The clock frames are drawn on.
  ReelClock get clock => ReelClock(fps);

  ReelStageState get _stage =>
      tester.state<ReelStageState>(find.byType(ReelStage));

  /// Takes the stage down and lets the app's pending timers run out — the
  /// work a pressed button is waiting on, say — so the test ends clean.
  Future<void> close() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 1));
  }

  /// Sizes the test view to the format, pumps the stage, lets the host get
  /// ready, and waits until every lifted widget has been found.
  Future<void> mount() async {
    tester.view.physicalSize = reel.format.pixels;
    tester.view.devicePixelRatio = reel.format.pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: ReelStage(reel: reel, host: host, time: _time),
      ),
    );
    await host.ready?.call(tester);
    _stage.prime();

    for (var i = 0; i < 30 && !_stage.ready; i++) {
      await tester.pump();
    }
    if (!_stage.ready) {
      throw StateError(
        'These lifts matched nothing in their screens: '
        '${_stage.missing.join(', ')}',
      );
    }
    await host.settle?.call(tester);
  }

  /// Moves the stage to [t] and draws it. Any real press due since the last
  /// frame is made first.
  Future<void> seek(Duration t, {Duration? step}) async {
    for (final press in _stage.pressesBetween(_last, t)) {
      await tester.tapAt(press.at);
    }
    _last = t;
    _time.value = t;
    // flutter_test draws every shadow solid, for stable goldens. A reel wants
    // them soft, so they are on while this frame paints, and off again before
    // the test's end-of-test check sees the flag.
    debugDisableShadows = false;
    try {
      // The app's own clock moves a frame at a time too, so anything
      // animating inside a screen keeps pace with the reel.
      await tester.pump(step ?? clock.frame);
    } finally {
      debugDisableShadows = true;
    }
  }

  /// The frame as drawn, at [scale] of the format's size.
  Future<ui.Image> capture({double scale = 1}) async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: reel.format.pixelRatio * scale),
    );
    return image!;
  }

  /// Saves the frame at [t] in the video (at the reel's pace) as a PNG at
  /// [path].
  Future<void> still(Duration t, String path) async {
    await seek(reel.atVideo(t));
    final image = await capture();
    await tester.runAsync(() async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File(path);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  /// Renders the whole reel to an H.264 MP4 at [path], with its soundtrack
  /// unless [audio] is off.
  ///
  /// Frames are piped to FFmpeg as raw RGBA. With motion blur, the reel is
  /// drawn that many times faster and FFmpeg blends each run of frames into
  /// one. A little grain is added so dark gradients do not band.
  Future<void> video(String path, {bool audio = true}) =>
      _encode(path, scale: 1, crf: 15, preset: 'slow', audio: audio);

  /// A quick, smaller render for the studio: half size, faster encoding.
  /// With [scene], only that scene (by name), without sound: a look at the
  /// opening or the end on its own.
  Future<void> preview(String path, {String? scene}) {
    if (scene == null) {
      return _encode(
        path,
        scale: 0.5,
        crf: 24,
        preset: 'veryfast',
        audio: true,
      );
    }
    final span = reel.timeline.firstWhere(
      (s) => s.scene.name == scene,
      orElse: () =>
          throw ArgumentError.value(scene, 'scene', 'not in the reel'),
    );
    return _encode(
      path,
      scale: 0.5,
      crf: 24,
      preset: 'veryfast',
      audio: false,
      from: reel.played(span.start),
      to: reel.played(span.end),
    );
  }

  Future<void> _encode(
    String path, {
    required double scale,
    required int crf,
    required String preset,
    required bool audio,
    Duration from = Duration.zero,
    Duration? to,
  }) async {
    final blur = reel.motionBlur < 1 ? 1 : reel.motionBlur;
    // Even sizes: H.264 in 4:2:0 needs them.
    final w = (reel.format.pixels.width * scale / 2).round() * 2;
    final h = (reel.format.pixels.height * scale / 2).round() * 2;
    // At a pace, each frame moves the reel's clock that much further.
    final step = Duration(microseconds: (1e6 / (fps * blur)).round());
    final reelStep = reel.atVideo(step);
    // A stretch of it, from [from] to [to] in the video.
    final first = clock.frames(from) * blur;
    final frames = clock.frames(to ?? reel.playedLength) * blur - first;
    File(path).parent.createSync(recursive: true);
    final silent = audio ? '$path.silent.mp4' : path;

    final errors = StringBuffer();
    final filters = [
      if (blur > 1) 'tmix=frames=$blur,framestep=$blur',
      'scale=out_color_matrix=bt709:out_range=tv',
      'format=yuv420p',
      // A little noise always, against banding; more when the ground asks
      // for film grain.
      'noise=alls=${(2 + (reel.backdrop.motion?.grain ?? 0) * 10).round()}:allf=t',
    ].join(',');
    final process = (await tester.runAsync(() async {
      final p = await Process.start(ffmpeg, [
        '-y',
        '-loglevel', 'error', //
        '-f', 'rawvideo',
        '-pix_fmt', 'rgba',
        '-s', '${w}x$h',
        '-framerate', '${fps * blur}',
        '-i', 'pipe:0',
        '-vf', filters,
        '-r', '$fps',
        '-c:v', 'libx264',
        '-preset', preset,
        '-crf', '$crf',
        '-profile:v', 'high',
        '-colorspace', 'bt709',
        '-color_primaries', 'bt709',
        '-color_trc', 'bt709',
        '-color_range', 'tv',
        '-movflags', '+faststart',
        silent,
      ]);
      p.stdout.drain<void>().ignore();
      p.stderr.transform(utf8.decoder).listen(errors.write);
      return p;
    }))!;

    final watch = Stopwatch()..start();
    for (var n = 0; n < frames; n++) {
      await seek(reel.atVideo(step * (first + n)), step: reelStep);
      final image = await capture(scale: w / reel.format.pixels.width);
      await tester.runAsync(() async {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        process.stdin.add(Uint8List.sublistView(rgba!));
        await process.stdin.flush();
      });
      if (n % (fps * blur * 2) == 0) {
        debugPrint(
          'blaq_reel: ${reel.name} frame $n/$frames  ${watch.elapsed}',
        );
      }
    }

    final code = await tester.runAsync(() async {
      await process.stdin.close();
      return process.exitCode;
    });
    if (code != 0) {
      throw ProcessException(ffmpeg, const [], '$errors', code ?? -1);
    }

    if (audio) {
      await tester.runAsync(() async => _mix(silent, path));
    }
    debugPrint('blaq_reel: ${reel.name} → $path in ${watch.elapsed}');
  }

  /// Lays the soundtrack under [silent], writing [out].
  void _mix(String silent, String out) {
    var soundtrack = reel.soundtrack;
    final music = soundtrack.music;
    final length = reel.playedLength;
    if (music != null && music.path == Music.pad) {
      final seconds = secondsOf(length).ceil();
      final pad = '$sfxDir/pad-${seconds}s.m4a';
      if (!File(pad).existsSync()) Sfx.pad(pad, length, ffmpeg);
      soundtrack = Soundtrack(
        music: Music(
          pad,
          gain: music.gain,
          fadeIn: music.fadeIn,
          fadeOut: music.fadeOut,
        ),
        voice: soundtrack.voice,
        cues: soundtrack.cues,
        cueGain: soundtrack.cueGain,
        duck: soundtrack.duck,
      );
    }
    // Lines and cues at their moments in the video; music as it is.
    if (reel.pace != 1) {
      soundtrack = Soundtrack(
        music: soundtrack.music,
        voice: [
          for (final v in soundtrack.voice)
            VoiceLine(reel.played(v.at), v.path, v.text, gain: v.gain),
        ],
        cues: soundtrack.cues,
        cueGain: soundtrack.cueGain,
        duck: soundtrack.duck,
      );
    }
    final args = mixArgs(
      video: silent,
      out: out,
      length: length,
      soundtrack: soundtrack,
      cues: [for (final c in reel.cues) c.copyAt(reel.played(c.at))],
      resolve: (s) => Sfx.resolve(s, sfxDir, ffmpeg),
    );
    if (args == null) {
      File(silent).renameSync(out);
      return;
    }
    final r = Process.runSync(ffmpeg, args);
    if (r.exitCode != 0) {
      throw ProcessException(ffmpeg, args, '${r.stderr}', r.exitCode);
    }
    File(silent).deleteSync();
  }
}

/// [reel]'s timeline as JSON-ready data, for the studio and for editors:
/// scenes, words, cues and voice-over, all on the video's clock (the reel's,
/// at its pace).
Map<String, Object?> describeReel(Reel reel, {int? fps}) {
  double sec(Duration d) => secondsOf(reel.played(d));
  return {
    'name': reel.name,
    'pace': reel.pace,
    'format': reel.format.name,
    'width': reel.format.pixels.width,
    'height': reel.format.pixels.height,
    'fps': fps ?? reel.fps,
    'length': sec(reel.length),
    'scenes': [
      for (final SceneSpan span in reel.timeline)
        {
          'name': span.scene.name,
          'start': sec(span.start),
          'end': sec(span.end),
          'enter': span.enter?.kind.name,
          'words': [
            for (final w in span.scene.words)
              {
                'text': w.plain,
                'at': sec(span.start + w.at),
                'until': w.until == null ? null : sec(span.start + w.until!),
              },
          ],
        },
    ],
    'cues': [
      for (final c in reel.cues) {'at': sec(c.at), 'sound': c.sound},
    ],
    'voice': [
      for (final v in reel.soundtrack.voice) {'at': sec(v.at), 'text': v.text},
    ],
  };
}
