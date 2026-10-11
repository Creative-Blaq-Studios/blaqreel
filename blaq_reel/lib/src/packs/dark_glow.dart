import 'package:flutter/widgets.dart';

import '../audio.dart';
import '../backdrop.dart';
import '../camera.dart';
import '../format.dart';
import '../layer.dart';
import '../motion.dart';
import '../scene.dart';
import '../time.dart';
import '../words.dart';
import 'brand.dart';

/// One stop on [DarkGlow]'s camera path: a screen, a title and a line.
class GlowStop {
  /// The screen.
  final Widget screen;

  /// A short title, its key part in braces.
  final String title;

  /// A line under it.
  final String? line;

  /// Widgets that lift while the camera holds here.
  final List<Pick> lift;

  /// The lifted widgets' corner radius.
  final double liftRadius;

  /// How long the camera holds here.
  final Duration hold;

  /// Scrolling while it holds, at times from the reel's start.
  final List<Scroll> scrolls;

  /// The device.
  final Device device;

  /// A stop.
  const GlowStop({
    required this.screen,
    required this.title,
    this.line,
    this.lift = const [],
    this.liftRadius = 24,
    this.hold = const Duration(milliseconds: 3000),
    this.scrolls = const [],
    this.device = Device.iphone,
  });
}

/// The Dark Glow style pack: one unbroken camera travelling past the app's
/// screens on a dark ground, each glowing at its edges in the accent as the
/// camera reaches it, with a title and a line beside it. From the Gemini
/// Canvas film.
class DarkGlow {
  /// The look.
  final Brand brand;

  /// The frame; wide suits it best.
  final Format format;

  /// The stops, in order.
  final List<GlowStop> stops;

  /// The logo the camera ends on, built from the end's clock.
  final Widget Function(Duration t)? logo;

  /// The logo's box.
  final Size logoSize;

  /// An address under the logo.
  final String? url;

  /// Drawn where a lifted widget was.
  final Widget Function(double radius)? hole;

  /// Drawn over the top of each screen.
  final Widget? statusBar;

  /// Time between stops.
  final Duration travel;

  /// A music bed.
  final Music? music;

  /// Frames per second.
  final int fps;

  /// Frames blended per output frame; travel is fast, so 2 or 3 helps.
  final int motionBlur;

  /// A Dark Glow reel.
  const DarkGlow({
    required this.brand,
    required this.stops,
    this.format = Format.wide,
    this.logo,
    this.logoSize = const Size(300, 100),
    this.url,
    this.hole,
    this.statusBar,
    this.travel = const Duration(milliseconds: 1300),
    this.music,
    this.fps = 30,
    this.motionBlur = 1,
  });

  static const _spacing = 900.0;
  static const _intro = Duration(milliseconds: 900);

  Duration _arrive(int i) => _intro + (stops.first.hold + travel) * i;

  /// The reel.
  Reel build(String name) {
    final stage = format.logical;
    final wide = !format.isTall;
    final zoom = wide ? 0.5 : 0.55;
    final n = stops.length;
    // Where the camera puts the screen it holds on: right of centre when
    // wide, so the words have the left; above centre when tall.
    final frameAt = wide
        ? Offset(stage.width * 0.2, 0)
        : Offset(0, -stage.height * 0.08);

    var focus = Track.from(0);
    // The world slides past a camera that stays put, so the camera always
    // turns around the screen it is looking at. Turning a camera that had
    // travelled along the row would swing far screens out of place.
    var slide = Track.from(_spacing * 0.9);
    var turn = Track.from(-24);
    var z = Track.from(zoom * 0.8);
    for (var i = 0; i < n; i++) {
      final a = _arrive(i);
      slide = slide.to(a, -i * _spacing, Ease.inOut).hold(a + stops[i].hold);
      turn = turn.to(a, -12, Ease.inOut).to(a + stops[i].hold, -8, Ease.linear);
      z = z.to(a, zoom, Ease.inOut).hold(a + stops[i].hold);
      // While it holds, focus rises with the lifted card; on the way to the
      // next stop it comes back down to the screens.
      focus = stops[i].lift.isEmpty
          ? focus
          : focus
                .hold(a + 300.ms)
                .to(a + 1100.ms, 130)
                .hold(a + stops[i].hold)
                .to(a + stops[i].hold + travel ~/ 2, 0);
    }
    final last = _arrive(n - 1) + stops.last.hold;
    final length = last + travel ~/ 2;

    final layers = <Layer>[];
    final words = <Words>[];
    for (var i = 0; i < n; i++) {
      final s = stops[i];
      final a = _arrive(i);
      final pos = Offset(i * _spacing, frameAt.dy / zoom);
      // Screens the camera is not on fade back, lifted cards with them, so
      // only the current stop competes with its words.
      final away = Track.from(0.18)
          .hold(a - travel ~/ 2)
          .to(a, 1, Ease.inOut)
          .hold(a + s.hold)
          .to(a + s.hold + travel ~/ 2, 0.18, Ease.inOut);
      final here = Track.from(0.25)
          .hold(a - travel ~/ 2)
          .to(a, 1, Ease.inOut)
          .hold(a + s.hold)
          .to(a + s.hold + travel ~/ 2, 0.25, Ease.inOut);
      layers
        ..add(
          Layer(
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(s.device.radius),
                ),
                shadows: [
                  BoxShadow(
                    color: brand.accent.withValues(alpha: 0.55),
                    blurRadius: 90,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: brand.accent.withValues(alpha: 0.9),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            size: s.device.size,
            position: pos,
            motion: Motion(x: slide, z: Track.constant(-4), opacity: here),
          ),
        )
        ..add(
          Layer.screen(
            s.screen,
            device: s.device,
            statusBar: statusBar,
            position: pos,
            scrolls: s.scrolls,
            motion: Motion(x: slide, opacity: away),
            lifts: [
              for (final (k, where) in s.lift.take(2).indexed)
                Lift(
                  where: where,
                  radius: s.liftRadius,
                  hole: hole?.call(s.liftRadius),
                  motion: Motion(
                    opacity: away,
                    z: Track.from(0)
                        .hold(a + 300.ms + 150.ms * k)
                        .to(a + 1100.ms + 150.ms * k, k == 0 ? 150 : 110)
                        .hold(a + s.hold)
                        .to(a + s.hold + travel ~/ 2, 0, Ease.inOut),
                  ),
                ),
            ],
          ),
        );
      // The title sits high and the line low, with room between for a
      // title that wraps to two lines.
      final align = wide ? const Alignment(-1, -0.5) : const Alignment(0, 0.62);
      words
        ..add(
          Words(
            s.title,
            at: a - 150.ms,
            until: a + s.hold - 250.ms,
            reveal: Reveal.letters,
            stagger: 30.ms,
            align: align,
            textAlign: wide ? TextAlign.left : TextAlign.center,
            maxWidth: wide ? 0.42 : 0.95,
            accent: brand.accent,
            style: brand.words(wide ? 40 : 36, brand.paper, tracking: -0.03),
          ),
        )
        ..addAll([
          if (s.line != null)
            Words(
              s.line!,
              at: a + 350.ms,
              until: a + s.hold - 250.ms,
              reveal: Reveal.fade,
              rise: 500.ms,
              align: wide
                  ? const Alignment(-1, 0.12)
                  : const Alignment(0, 0.96),
              textAlign: wide ? TextAlign.left : TextAlign.center,
              maxWidth: wide ? 0.4 : 0.9,
              style: brand.small(
                wide ? 17 : 15,
                brand.paper.withValues(alpha: 0.72),
              ),
            ),
        ]);
    }

    final scenes = [
      Scene(
        name: 'path',
        length: length,
        camera: Camera.tracks(
          panX: Track.constant(frameAt.dx),
          panY: Track.constant(0),
          turn: turn,
          tilt: Track.constant(5),
          zoom: z,
          focus: focus,
          aperture: Track.constant(1.1),
          // Both lifts sit inside the sharp band while the camera holds.
          depth: Track.constant(36),
        ),
        layers: layers,
        words: words,
        cues: [for (var i = 1; i < n; i++) Cue(_arrive(i) - travel, 'whoosh')],
      ),
      if (logo != null)
        Scene(
          name: 'end',
          length: 3.4.s,
          camera: Camera.tracks(zoom: Track.from(0.96).to(3.4.s, 1.02)),
          layers: [
            Layer.timed(
              logo!,
              size: logoSize,
              position: Offset(0, -stage.height * 0.05),
              motion: Motion(
                blur: Track.from(10).to(900.ms, 0, Ease.out),
                opacity: Track.from(0).to(700.ms, 1, Ease.out),
              ),
            ),
          ],
          words: [
            if (url != null)
              Words(
                url!,
                at: 900.ms,
                reveal: Reveal.fade,
                align: Alignment(0, wide ? 0.5 : 0.35),
                textAlign: TextAlign.center,
                style: brand.small(16, brand.accent, weight: 600),
              ),
          ],
          cues: const [Cue(Duration(milliseconds: 200), 'chime')],
        ),
    ];

    return Reel(
      name: name,
      format: format,
      fps: fps,
      motionBlur: motionBlur,
      backdrop: Backdrop(
        top: Color.lerp(brand.ink, const Color(0xFF000000), 0.35)!,
        bottom: Color.lerp(brand.ink, const Color(0xFF000000), 0.75)!,
        vignette: 0.5,
        glows: [
          Glow(
            brand.accent.withValues(alpha: 0.12),
            center: const Alignment(0.3, 0),
            radius: 0.6,
            period: 11,
          ),
        ],
      ),
      scenes: scenes,
      transitions: const [Transition.fade(length: Duration(milliseconds: 700))],
      soundtrack: Soundtrack(music: music, cueGain: -10),
    );
  }
}
