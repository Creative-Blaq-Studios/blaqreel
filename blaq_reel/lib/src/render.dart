import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reel.dart';
import 'stage.dart';
import 'time.dart';

/// Renders a [Reel] inside a widget test: frame by frame on a fixed clock,
/// each frame captured from the stage and handed to FFmpeg, or saved alone
/// as a still.
///
/// ```dart
/// testWidgets('proof', (tester) async {
///   final r = ReelRenderer(tester, proof, host: host);
///   await r.mount();
///   await r.video('app_reels/out/proof.mp4');
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

  final _time = ValueNotifier<Duration>(Duration.zero);
  final _boundary = GlobalKey();

  /// A renderer.
  ReelRenderer(this.tester, this.reel, {required this.host, int? fps})
    : fps = fps ?? reel.fps;

  /// The clock frames are drawn on.
  ReelClock get clock => ReelClock(fps);

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

    final stage = tester.state<ReelStageState>(find.byType(ReelStage));
    for (var i = 0; i < 30 && !stage.lifted; i++) {
      await tester.pump();
    }
    if (!stage.lifted) {
      throw StateError('A Lift matched nothing in its screen.');
    }
    await host.settle?.call(tester);
  }

  /// Moves the stage to [t] and draws it.
  Future<void> seek(Duration t) async {
    _time.value = t;
    // flutter_test draws every shadow solid, for stable goldens. A reel wants
    // them soft, so they are on while this frame paints, and off again before
    // the test's end-of-test check sees the flag.
    debugDisableShadows = false;
    try {
      // The app's own clock moves a frame at a time too, so anything
      // animating inside a screen keeps pace with the reel.
      await tester.pump(clock.frame);
    } finally {
      debugDisableShadows = true;
    }
  }

  /// The frame as drawn, in pixels.
  Future<ui.Image> capture() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: reel.format.pixelRatio),
    );
    return image!;
  }

  /// Saves the frame at [t] as a PNG at [path].
  Future<void> still(Duration t, String path) async {
    await seek(t);
    final image = await capture();
    await tester.runAsync(() async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
  }

  /// Renders the whole reel to an H.264 MP4 at [path], piping raw RGBA
  /// frames into [ffmpeg]. A little grain is added while encoding, so dark
  /// gradients do not band.
  Future<void> video(String path, {String ffmpeg = 'ffmpeg'}) async {
    final size = reel.format.pixels;
    final w = size.width.round();
    final h = size.height.round();
    final frames = clock.frames(reel.length);
    // Real I/O never completes in the test's fake-async zone: anything that
    // touches the disk or a process is synchronous or inside runAsync.
    File(path).parent.createSync(recursive: true);

    final errors = StringBuffer();
    final process = (await tester.runAsync(() async {
      final p = await Process.start(ffmpeg, [
        '-y',
        '-loglevel', 'error', //
        '-f', 'rawvideo',
        '-pix_fmt', 'rgba',
        '-s', '${w}x$h',
        '-framerate', '$fps',
        '-i', 'pipe:0',
        '-vf',
        'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p,'
            'noise=alls=2:allf=t',
        '-c:v', 'libx264',
        '-preset', 'slow',
        '-crf', '15',
        '-profile:v', 'high',
        '-colorspace', 'bt709',
        '-color_primaries', 'bt709',
        '-color_trc', 'bt709',
        '-color_range', 'tv',
        '-movflags', '+faststart',
        path,
      ]);
      p.stdout.drain<void>().ignore();
      p.stderr.transform(utf8.decoder).listen(errors.write);
      return p;
    }))!;

    final watch = Stopwatch()..start();
    for (var n = 0; n < frames; n++) {
      await seek(clock.at(n));
      final image = await capture();
      await tester.runAsync(() async {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        process.stdin.add(Uint8List.sublistView(rgba!));
        await process.stdin.flush();
      });
      if (n % fps == 0) {
        debugPrint('blaq_reel: frame $n/$frames  ${watch.elapsed}');
      }
    }

    final code = await tester.runAsync(() async {
      await process.stdin.close();
      return process.exitCode;
    });
    if (code != 0) {
      throw ProcessException(ffmpeg, const [], '$errors', code ?? -1);
    }
    debugPrint('blaq_reel: $frames frames to $path in ${watch.elapsed}');
  }
}
