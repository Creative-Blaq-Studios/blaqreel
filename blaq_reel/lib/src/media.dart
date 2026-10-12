import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'time.dart';

/// A picture from a file, drawn in a reel: a generated background, a hand,
/// a texture, one frame of a clip.
///
/// Files are read when first used and decoded by the renderer between
/// frames ([ReelImage.decodePending]): inside `flutter test`, a decode only
/// finishes on the real clock, so a picture used for the first time shows
/// from the next frame drawn after it is decoded.
class ReelImage extends StatelessWidget {
  /// The file: a PNG, JPEG or WebP, relative to the app's folder.
  final String path;

  /// How it fills its box.
  final BoxFit fit;

  /// Where it sits in its box when it does not fill it.
  final Alignment alignment;

  /// A picture.
  const ReelImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  static final Map<String, MemoryImage> _images = {};
  static final Set<String> _decoded = {};
  static final Set<String> _pending = {};

  /// The picture at [path], read once.
  static MemoryImage of(String path) => _images.putIfAbsent(
    path,
    () => MemoryImage(File(path).readAsBytesSync()),
  );

  /// The picture's size in pixels, read from its header (PNG or JPEG);
  /// null if it can't be read.
  static Size? sizeOf(String path) {
    final b = of(path).bytes;
    // PNG: the IHDR chunk's width and height.
    if (b.length > 24 && b[0] == 0x89 && b[1] == 0x50) {
      int u32(int i) =>
          (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
      return Size(u32(16).toDouble(), u32(20).toDouble());
    }
    // JPEG: the first start-of-frame segment.
    if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) {
      var i = 2;
      while (i + 9 < b.length) {
        if (b[i] != 0xFF) return null;
        final marker = b[i + 1], len = (b[i + 2] << 8) | b[i + 3];
        if (marker >= 0xC0 &&
            marker <= 0xCF &&
            marker != 0xC4 &&
            marker != 0xC8 &&
            marker != 0xCC) {
          return Size(
            ((b[i + 7] << 8) | b[i + 8]).toDouble(),
            ((b[i + 5] << 8) | b[i + 6]).toDouble(),
          );
        }
        i += 2 + len;
      }
    }
    return null;
  }

  /// Whether a picture is waiting to be decoded.
  static bool get hasPending => _pending.isNotEmpty;

  /// Decodes every picture used but not decoded yet. Run on the real clock
  /// (`tester.runAsync`), then pump, so the pictures draw.
  static Future<void> decodePending() async {
    final paths = _pending.toList();
    _pending.clear();
    for (final path in paths) {
      final done = Completer<void>();
      final stream = of(path).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, _) {
          if (!done.isCompleted) done.complete();
        },
        onError: (Object e, StackTrace? _) {
          if (!done.isCompleted) done.completeError(e);
        },
      );
      stream.addListener(listener);
      try {
        await done.future;
        _decoded.add(path);
      } finally {
        stream.removeListener(listener);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!File(path).existsSync()) {
      throw ArgumentError.value(path, 'path', 'no such picture');
    }
    if (!_decoded.contains(path)) _pending.add(path);
    return Image(
      image: of(path),
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// How a picture moves while it shows.
enum MediaMove {
  /// It stays put.
  none,

  /// It bobs gently, as if floating.
  float,

  /// It rises into place as it appears.
  rise,

  /// It drifts slowly sideways.
  drift,

  /// It grows slowly, as a camera pushing in.
  zoom,

  /// It turns slowly.
  spin,

  /// It springs in from small.
  pop,
}

/// A picture, or a run of frames (a clip), set in the frame like words: in
/// front of the 3D world or behind it, for a while, moving its own way.
///
/// Its [box] is in fractions of the frame: `Rect.fromLTWH(0.6, 0.05, 0.35,
/// 0.2)` is the top right. Times are its scene's own (or, on a reel, the
/// reel's clock as made).
class Media {
  /// A picture.
  final String? image;

  /// A folder of frames, played in name order at [fps], looping: a clip
  /// turned into pictures (`dart run blaq_reel media frames <video>`).
  final String? frames;

  /// The frames' rate.
  final double fps;

  /// Where it sits, in fractions of the frame.
  final Rect box;

  /// When it appears; from the start if null.
  final Duration? at;

  /// When it goes; to the end if null.
  final Duration? until;

  /// Behind the screens and lifted parts rather than in front.
  final bool behind;

  /// How it fills its box.
  final BoxFit fit;

  /// How it moves while it shows.
  final MediaMove move;

  /// How opaque it is at most.
  final double opacity;

  /// A picture or a clip in the frame.
  const Media({
    this.image,
    this.frames,
    this.fps = 30,
    this.box = const Rect.fromLTWH(0, 0, 1, 1),
    this.at,
    this.until,
    this.behind = false,
    this.fit = BoxFit.contain,
    this.move = MediaMove.none,
    this.opacity = 1,
  }) : assert(image != null || frames != null);

  static final Map<String, List<String>> _runs = {};

  /// The picture to show at [t] since it appeared.
  String pathAt(Duration t) {
    final image = this.image;
    if (image != null) return image;
    final run = _runs.putIfAbsent(frames!, () {
      final dir = Directory(frames!);
      if (!dir.existsSync()) {
        throw ArgumentError.value(frames, 'frames', 'no such folder');
      }
      final files =
          dir
              .listSync()
              .whereType<File>()
              .map((f) => f.path)
              .where((p) => RegExp(r'\.(png|jpe?g|webp)$').hasMatch(p))
              .toList()
            ..sort();
      if (files.isEmpty) {
        throw ArgumentError.value(frames, 'frames', 'no pictures in it');
      }
      return files;
    });
    final i = (secondsOf(t) * fps).floor();
    return run[i % run.length];
  }

  /// It drawn at [t] on its scene's clock, in a frame of [stage].
  Widget drawn(Duration t, Size stage) {
    final from = at ?? Duration.zero;
    if (t < from || (until != null && t > until!)) {
      return const SizedBox.shrink();
    }
    final local = t - from;
    final s = secondsOf(local);
    final fadeIn = progress(local, Duration.zero, 300.ms, curve: Ease.out);
    final fadeOut = until == null
        ? 0.0
        : progress(t, until! - 300.ms, until!, curve: Ease.leave);
    var dx = 0.0, dy = 0.0, scale = 1.0, turn = 0.0;
    switch (move) {
      case MediaMove.none:
        break;
      case MediaMove.float:
        dy = math.sin(s * 1.3) * 6;
        turn = math.sin(s * 0.9) * 0.02;
      case MediaMove.rise:
        dy = 30 * (1 - progress(local, Duration.zero, 700.ms, curve: Ease.out));
      case MediaMove.drift:
        dx = s * 8;
      case MediaMove.zoom:
        scale = 1 + 0.025 * s;
      case MediaMove.spin:
        turn = s * 0.35;
      case MediaMove.pop:
        scale =
            0.6 + 0.4 * progress(local, Duration.zero, 500.ms, curve: Ease.pop);
    }
    final r = Rect.fromLTWH(
      box.left * stage.width,
      box.top * stage.height,
      box.width * stage.width,
      box.height * stage.height,
    );
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(
        child: Opacity(
          opacity: (opacity * fadeIn * (1 - fadeOut)).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: turn,
              child: Transform.scale(
                scale: scale,
                child: ReelImage(pathAt(local), fit: fit),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A hand that does a reel's taps in place of the round fingertip: a
/// picture (generated, photographed or drawn) with its fingertip at [tip].
class TapHand {
  /// The picture.
  final String image;

  /// Where the fingertip is in the picture, in fractions of it: (0.3, 0.05)
  /// is near the top, a third of the way across.
  final Offset tip;

  /// How wide it is drawn, in stage units.
  final double width;

  /// A hand.
  const TapHand(
    this.image, {
    this.tip = const Offset(0.3, 0.05),
    this.width = 200,
  });
}
