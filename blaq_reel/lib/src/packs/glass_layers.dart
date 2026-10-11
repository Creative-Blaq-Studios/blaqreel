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

/// One beat of [GlassLayers]: a word, a screen, and the parts of it that
/// lift off as layers.
class GlassBeat {
  /// The beat's one word, `'Share.'`. A trailing full stop takes the accent
  /// unless [highlight] names another part.
  final String word;

  /// The screen.
  final Widget screen;

  /// Picks the widgets that lift off, the first the furthest. Up to three
  /// read well.
  final List<Pick> lift;

  /// The lifted widgets' corner radius.
  final double liftRadius;

  /// The part of [word] that takes the accent.
  final String? highlight;

  /// How long it runs, transitions included.
  final Duration length;

  /// Fingers on the screen, at the beat's own times.
  final List<Tap> taps;

  /// Scrolling, at the beat's own times.
  final List<Scroll> scrolls;

  /// Typing, at the beat's own times.
  final List<TypeText> typing;

  /// Slows time while the lift rises: 1 is none, 0.5 is half speed.
  final double slowLift;

  /// The device.
  final Device device;

  /// Scales the screen in frame for this beat: below 1 for a tall lift that
  /// would otherwise run into the word.
  final double zoom;

  /// Moves the screen in frame for this beat, in stage units.
  final Offset framing;

  /// This beat's ground, if it differs from the reel's. The two crossfade
  /// as the beats hand over.
  final GlassLook? look;

  /// Colours of your own for this beat's ground, overriding its look's; the
  /// look still decides the words' colours and anything behind the screen.
  final Backdrop? ground;

  /// A beat.
  const GlassBeat(
    this.word, {
    required this.screen,
    this.lift = const [],
    this.liftRadius = 24,
    this.highlight,
    this.length = const Duration(milliseconds: 5000),
    this.taps = const [],
    this.scrolls = const [],
    this.typing = const [],
    this.slowLift = 1,
    this.device = Device.iphone,
    this.zoom = 1,
    this.framing = Offset.zero,
    this.look,
    this.ground,
  });
}

/// How [GlassLayers] closes: the logo, a line under it, and an address.
class GlassEnd {
  /// The logo, built from the end card's clock, drawn at [logoSize].
  final Widget Function(Duration t) logo;

  /// The logo's box.
  final Size logoSize;

  /// A line under it.
  final String? line;

  /// An address under that.
  final String? url;

  /// Whether every beat's screen fans out in depth behind the logo.
  final bool fan;

  /// How long it holds, its transition in included.
  final Duration length;

  /// An end card.
  const GlassEnd({
    required this.logo,
    required this.logoSize,
    this.line,
    this.url,
    this.fan = true,
    this.length = const Duration(milliseconds: 4200),
  });
}

/// The Glass Layers style pack: real screens split into floating layers in
/// depth, one word per beat, a camera that never stops, a soft backdrop.
/// From the Sber "glass layers" Short.
///
/// Give it a brand, screens and words; it supplies the camera, the timing,
/// the lifts and the transitions, laid out for whichever [Format] it is
/// built for.
class GlassLayers {
  /// The look.
  final Brand brand;

  /// The frame.
  final Format format;

  /// The beats, in order.
  final List<GlassBeat> beats;

  /// What opens it, built from the opening's clock: usually the app's mark
  /// assembling. Null starts on the first beat.
  final Widget Function(Duration t)? open;

  /// The opening widget's box.
  final Size openSize;

  /// How it ends. Null ends on the last beat.
  final GlassEnd? end;

  /// Drawn where a lifted widget was: the page colour, in the lift's shape.
  final Widget Function(double radius)? hole;

  /// Drawn over the top of each screen.
  final Widget? statusBar;

  /// What the screens sit on, unless a beat says otherwise.
  final GlassLook look;

  /// Colours of your own for the ground, overriding [look]'s; the look
  /// still decides the words' colours.
  final Backdrop? ground;

  /// A music bed.
  final Music? music;

  /// Voice-over.
  final List<VoiceLine> voice;

  /// Frames blended per output frame.
  final int motionBlur;

  /// Frames per second.
  final int fps;

  /// A Glass Layers reel.
  const GlassLayers({
    required this.brand,
    required this.beats,
    this.format = Format.vertical,
    this.open,
    this.openSize = const Size(160, 160),
    this.end,
    this.hole,
    this.statusBar,
    this.look = GlassLook.ink,
    this.ground,
    this.music,
    this.voice = const [],
    this.motionBlur = 1,
    this.fps = 30,
  });

  /// Whether the ground is light, so words go dark on it.
  static bool _isLight(GlassLook l) =>
      l == GlassLook.mesh || l == GlassLook.butter || l == GlassLook.studio;

  /// The look the whole reel uses: [look], unless a render asks for
  /// another with `--dart-define=BLAQ_REEL_LOOK=<name>` (the `looks`
  /// command does, to compare grounds).
  GlassLook get _look => _override ?? look;

  static final GlassLook? _override = () {
    const name = String.fromEnvironment('BLAQ_REEL_LOOK');
    if (name.isEmpty) return null;
    return GlassLook.values.firstWhere(
      (l) => l.name == name,
      orElse: () => throw ArgumentError.value(name, 'BLAQ_REEL_LOOK'),
    );
  }();

  /// The look [beat] uses: its own, unless a render overrides every look.
  GlassLook _lookOf(GlassBeat beat) => _override ?? beat.look ?? look;

  /// The reel's backdrop: [ground] if given, or its look's.
  Backdrop get backdrop => ground ?? backdropOf(_look);

  /// [l]'s backdrop, in this brand's colours.
  Backdrop backdropOf(GlassLook l) {
    final ink = brand.ink, accent = brand.accent, paper = brand.paper;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    const white = Color(0xFFFFFFFF), black = Color(0xFF000000);
    return switch (l) {
      GlassLook.ink || GlassLook.echo => Backdrop(
        top: mix(ink, white, 0.03),
        bottom: mix(ink, black, 0.55),
        vignette: l == GlassLook.echo ? 0.55 : 0.4,
        glows: [
          if (l == GlassLook.ink) ...[
            Glow(
              accent.withValues(alpha: 0.28),
              center: const Alignment(0.4, -0.35),
              radius: 0.55,
            ),
            Glow(
              accent.withValues(alpha: 0.1),
              center: const Alignment(-0.7, 0.75),
              radius: 0.45,
              period: 13,
            ),
          ],
        ],
      ),
      // Soft fields of the accent and two neighbours of it, drifting on a
      // light ground.
      GlassLook.mesh => Backdrop(
        top: mix(paper, white, 0.5),
        bottom: mix(paper, accent, 0.18),
        vignette: 0.06,
        glows: [
          Glow(
            accent.withValues(alpha: 0.9),
            center: const Alignment(-0.75, -0.55),
            radius: 0.62,
            drift: const Offset(0.18, 0.12),
            period: 8,
          ),
          Glow(
            mix(accent, const Color(0xFFFF8A65), 0.55).withValues(alpha: 0.55),
            center: const Alignment(0.85, 0.05),
            radius: 0.5,
            drift: const Offset(0.14, 0.16),
            period: 10.5,
          ),
          Glow(
            const Color(0xFFC9BCFF).withValues(alpha: 0.55),
            center: const Alignment(-0.35, 0.85),
            radius: 0.55,
            drift: const Offset(0.2, 0.1),
            period: 12,
          ),
          Glow(
            white.withValues(alpha: 0.7),
            center: const Alignment(0.2, 0.1),
            radius: 0.35,
            period: 9,
          ),
        ],
      ),
      // The brand colour, whole: bold and flat, lit from above.
      GlassLook.butter => Backdrop(
        top: mix(accent, white, 0.12),
        bottom: mix(accent, const Color(0xFFE0A800), 0.35),
        vignette: 0.1,
        glows: [
          Glow(
            white.withValues(alpha: 0.45),
            center: const Alignment(0, -0.75),
            radius: 0.55,
            period: 11,
          ),
        ],
      ),
      // A photo studio's white sweep: a pale wall curving into a floor, a
      // soft light from above, and the faintest warmth of the accent.
      GlassLook.studio => Backdrop(
        top: mix(paper, white, 0.6),
        bottom: mix(paper, black, 0.04),
        vignette: 0.14,
        floor: mix(paper, black, 0.09),
        glows: [
          Glow(
            white.withValues(alpha: 0.9),
            center: const Alignment(0, -0.7),
            radius: 0.55,
            drift: const Offset(0.03, 0.02),
            period: 14,
          ),
          Glow(
            accent.withValues(alpha: 0.18),
            center: const Alignment(0.6, 0.6),
            radius: 0.45,
            period: 11,
          ),
        ],
      ),
      GlassLook.grid => Backdrop(
        top: mix(ink, black, 0.45),
        bottom: mix(ink, black, 0.2),
        vignette: 0.5,
        glows: [
          Glow(
            accent.withValues(alpha: 0.16),
            center: const Alignment(0, 0.35),
            radius: 0.55,
            period: 12,
          ),
        ],
      ),
    };
  }

  /// Layers the look adds behind a beat's screen.
  List<Layer> _ambient(GlassBeat beat, GlassLook l) => switch (l) {
    // The beat's own screen, huge and out of focus behind it.
    GlassLook.echo => [
      Layer.screen(
        beat.screen,
        device: beat.device,
        statusBar: statusBar,
        motion: Motion(
          z: Track.constant(-160),
          scale: Track.constant(2.4),
          blur: Track.constant(14),
          opacity: Track.constant(0.32),
        ),
      ),
    ],
    // A floor of lines the phone stands over, in the world, so it moves
    // with the camera.
    GlassLook.grid => [
      Layer(
        CustomPaint(painter: _FloorGrid(brand.accent)),
        // Near the focus, so depth of field softens it without wiping it
        // out; small enough that its near edge stays in front of the eye.
        size: const Size(1800, 1800),
        position: const Offset(0, 560),
        ignoreFocus: true,
        motion: Motion(tilt: Track.constant(82), z: Track.constant(-60)),
      ),
    ],
    _ => const [],
  };

  Color _wordColor(GlassLook l) => _isLight(l) ? brand.ink : brand.paper;

  /// The accent on words: on the brand's own colour it would vanish, so
  /// there it is the light colour; on light fields it deepens to read.
  Color _wordAccent(GlassLook l) => switch (l) {
    GlassLook.butter => brand.paper,
    GlassLook.mesh ||
    GlassLook.studio => Color.lerp(brand.accent, brand.ink, 0.35)!,
    _ => brand.accent,
  };

  _Frame get _frame => _Frame.of(format);

  /// The reel.
  Reel build(String name) {
    final scenes = <Scene>[];
    final transitions = <Transition>[];
    if (open != null) {
      scenes.add(openScene());
      transitions.add(const Transition.zoomThrough());
    }
    for (final (i, beat) in beats.indexed) {
      scenes.add(beatScene(beat, i.isEven ? 1 : -1));
      if (i < beats.length - 1) {
        transitions.add(Transition.swing(direction: i.isEven ? 1 : -1));
      }
    }
    if (end != null) {
      transitions.add(const Transition.rise());
      scenes.add(endScene(end!));
    }
    return Reel(
      name: name,
      format: format,
      fps: fps,
      backdrop: backdrop,
      scenes: scenes,
      transitions: transitions,
      motionBlur: motionBlur,
      soundtrack: Soundtrack(music: music, voice: voice, cueGain: -9),
    );
  }

  /// The opening: [open] arriving out of the dark, for a zoom through into
  /// the first beat.
  Scene openScene() {
    const length = Duration(milliseconds: 2600);
    final f = _frame;
    return Scene(
      name: 'open',
      length: length,
      camera: Camera.tracks(zoom: Track.from(1).to(length, 1.08, Ease.linear)),
      layers: [
        Layer.timed(
          open!,
          size: openSize,
          position: Offset(0, -f.stage.height * 0.02),
          motion: Motion(
            z: Track.from(-420).to(1400.ms, 0, Ease.out),
            roll: Track.from(10).to(1400.ms, 0, Ease.out),
            blur: Track.from(14).to(1100.ms, 0, Ease.out),
            opacity: Track.from(0).to(600.ms, 1, Ease.out),
          ),
        ),
      ],
      cues: [const Cue(Duration(milliseconds: 150), 'rise')],
    );
  }

  /// One beat as a scene. [dir] is 1 or -1: which way the camera swings,
  /// alternating so consecutive beats mirror each other.
  Scene beatScene(GlassBeat beat, double dir) {
    final f = _frame.adjusted(beat.zoom, beat.framing);
    final bl = _lookOf(beat);
    final light = _isLight(bl);
    final l = beat.length;
    const settle = Duration(milliseconds: 1500);
    const lifted = Duration(milliseconds: 3000);
    const heroHeight = 220.0;
    const fallBack = 80.0;
    // Close enough together that one sharp band holds every lifted card:
    // lifted means in focus. Only the screen behind softens.
    final heights = [heroHeight, 180.0, 145.0];
    final count = beat.lift.take(3).length;
    final top = heroHeight - fallBack;
    final bottom = (count == 0 ? heroHeight : heights[count - 1]) - fallBack;

    final hasLift = beat.lift.isNotEmpty;
    final camera = Camera.tracks(
      tilt: Track.from(15).to(settle, 6, Ease.arrive).to(l, 9, Ease.linear),
      turn: Track.from(
        -19 * dir,
      ).to(settle, -7 * dir, Ease.arrive).to(l, -13 * dir, Ease.linear),
      roll: Track.from(
        -4 * dir,
      ).to(settle, -2 * dir, Ease.arrive).to(l, -3 * dir, Ease.linear),
      zoom: Track.from(
        f.zoom * 0.9,
      ).to(settle, f.zoom, Ease.arrive).to(l, f.zoom * 1.05, Ease.linear),
      panX: Track.from(
        f.pan.dx,
      ).hold(settle).to(l, f.pan.dx + 6 * dir, Ease.linear),
      panY: Track.from(
        f.pan.dy + 24,
      ).to(settle, f.pan.dy, Ease.arrive).to(l, f.pan.dy - 6, Ease.linear),
      focus: hasLift
          ? Track.from(0).hold(settle).to(lifted, (top + bottom) / 2)
          : null,
      aperture: hasLift ? Track.from(0).hold(settle).to(lifted, 2.6) : null,
      depth: hasLift
          ? Track.from(0).hold(settle).to(lifted, (top - bottom) / 2 + 14)
          : null,
    );

    final wordAt = hasLift ? 2.s : 1.2.s;
    final highlight = beat.highlight ?? (beat.word.endsWith('.') ? '.' : null);
    return Scene(
      name: beat.word,
      length: l,
      camera: camera,
      backdrop: _override == null
          ? (beat.ground ?? (bl != _look ? backdropOf(bl) : null))
          : null,
      speed: beat.slowLift == 1
          ? null
          : Track.from(1)
                .hold(settle - 200.ms)
                .to(settle + 300.ms, beat.slowLift)
                .hold(lifted - 300.ms)
                .to(lifted + 300.ms, 1),
      layers: [
        ..._ambient(beat, bl),
        Layer.screen(
          beat.screen,
          device: beat.device,
          statusBar: statusBar,
          taps: beat.taps,
          scrolls: beat.scrolls,
          typing: beat.typing,
          motion: hasLift
              ? Motion(
                  z: Track.from(0).hold(settle).to(lifted, -fallBack),
                  opacity: Track.from(1).hold(settle).to(lifted, 0.76),
                )
              : null,
          lifts: [
            for (final (k, where) in beat.lift.take(3).indexed)
              Lift(
                where: where,
                radius: beat.liftRadius,
                hole: hole?.call(beat.liftRadius),
                glass: const Glass(depth: 6, color: Color(0x30FFFFFF)),
                motion: Motion(
                  z: Track.from(0)
                      .hold(settle + 250.ms * k)
                      .to(lifted + 250.ms * k, heights[k]),
                  x: Track.from(0)
                      .hold(settle + 250.ms * k)
                      .to(lifted + 250.ms * k, k == 0 ? 0 : 10.0 * dir * k),
                  scale: Track.from(1)
                      .hold(settle + 250.ms * k)
                      .to(lifted + 250.ms * k, k == 0 ? 1.06 : 1.03),
                ),
              ),
          ],
        ),
      ],
      words: [
        Words(
          beat.word,
          at: wordAt,
          until: l - 1100.ms,
          highlight: highlight,
          accent: _wordAccent(bl),
          align: f.wordAlign,
          maxWidth: f.wordWidth,
          style: brand
              .words(f.wordSize, _wordColor(bl))
              .copyWith(
                shadows: [
                  Shadow(
                    color: (light ? brand.paper : brand.ink).withValues(
                      alpha: light ? 0.35 : 0.6,
                    ),
                    blurRadius: 24,
                  ),
                ],
              ),
        ),
      ],
      cues: [if (hasLift) Cue(settle, 'rise')],
    );
  }

  /// The end card as a scene.
  Scene endScene(GlassEnd end) {
    final f = _frame;
    final l = end.length;
    final stage = f.stage;
    final n = beats.length;
    final wide = !format.isTall;
    return Scene(
      name: 'end',
      length: l,
      camera: Camera.tracks(
        zoom: Track.from(0.96).to(l, 1.04, Ease.linear),
        focus: Track.constant(0),
        aperture: Track.constant(1.6),
      ),
      layers: [
        if (end.fan)
          for (final (i, beat) in beats.indexed)
            Layer.screen(
              beat.screen,
              device: beat.device,
              statusBar: statusBar,
              // Low in the frame, under the address, so the logo and the
              // line stand on the dark ground above them.
              position: Offset(
                (i - (n - 1) / 2) * (wide ? stage.width * 0.2 : 92),
                // Distance pulls far things toward the middle, so the
                // wider the frame, the lower they have to start.
                stage.height * (wide ? 1.05 : 0.72),
              ),
              motion: Motion(
                z: Track.from(-700)
                    .hold(300.ms + 90.ms * i)
                    .to(1500.ms + 90.ms * i, -520, Ease.out),
                y: Track.from(
                  260,
                ).hold(300.ms + 90.ms * i).to(1500.ms + 90.ms * i, 0, Ease.out),
                turn: Track.constant(-28),
                tilt: Track.constant(6),
                scale: Track.constant(wide ? 0.55 : 0.5),
                opacity: Track.from(
                  0,
                ).hold(300.ms + 90.ms * i).to(1100.ms + 90.ms * i, 0.5),
              ),
            ),
        Layer.timed(
          end.logo,
          size: end.logoSize,
          position: Offset(0, -stage.height * (wide ? 0.08 : 0.06)),
          motion: Motion(
            z: Track.from(-160).hold(500.ms).to(1600.ms, 0, Ease.out),
            blur: Track.from(10).hold(500.ms).to(1400.ms, 0, Ease.out),
            opacity: Track.from(0).hold(500.ms).to(1100.ms, 1, Ease.out),
          ),
        ),
      ],
      words: [
        if (end.line != null)
          Words(
            end.line!,
            at: 1.5.s,
            reveal: Reveal.words,
            stagger: 70.ms,
            align: Alignment(0, wide ? 0.46 : 0.36),
            textAlign: TextAlign.center,
            maxWidth: wide ? 0.7 : 0.9,
            style: brand.words(f.lineSize, _wordColor(_look), tracking: -0.02),
          ),
        if (end.url != null)
          Words(
            end.url!,
            at: 2.2.s,
            reveal: Reveal.fade,
            rise: 600.ms,
            align: Alignment(0, wide ? 0.74 : 0.6),
            textAlign: TextAlign.center,
            style: brand
                .small(
                  f.lineSize * 0.42,
                  _isLight(_look) ? brand.ink : brand.accent,
                  weight: 600,
                )
                .copyWith(
                  shadows: [
                    Shadow(
                      color: (_isLight(_look) ? brand.paper : brand.ink)
                          .withValues(alpha: 0.9),
                      blurRadius: 12,
                    ),
                  ],
                ),
          ),
      ],
      cues: const [Cue(Duration(milliseconds: 900), 'chime')],
    );
  }
}

/// Where things sit in a format: the screen, the words.
class _Frame {
  final Size stage;
  final double zoom;
  final Offset pan;
  final Alignment wordAlign;
  final double wordSize;
  final double wordWidth;
  final double lineSize;

  const _Frame({
    required this.stage,
    required this.zoom,
    required this.pan,
    required this.wordAlign,
    required this.wordSize,
    required this.wordWidth,
    required this.lineSize,
  });

  _Frame adjusted(double scale, Offset by) => _Frame(
    stage: stage,
    zoom: zoom * scale,
    pan: pan + by,
    wordAlign: wordAlign,
    wordSize: wordSize,
    wordWidth: wordWidth,
    lineSize: lineSize,
  );

  factory _Frame.of(Format format) {
    final stage = format.logical;
    final aspect = stage.height / stage.width;
    if (aspect > 1.5) {
      return _Frame(
        stage: stage,
        zoom: 0.5,
        pan: const Offset(8, -70),
        wordAlign: Alignment.bottomLeft,
        wordSize: 80,
        wordWidth: 1,
        lineSize: 34,
      );
    }
    if (aspect > 1.1) {
      return _Frame(
        stage: stage,
        zoom: 0.4,
        pan: const Offset(40, -30),
        wordAlign: Alignment.bottomLeft,
        wordSize: 64,
        wordWidth: 1,
        lineSize: 30,
      );
    }
    if (aspect > 0.8) {
      return _Frame(
        stage: stage,
        zoom: 0.36,
        pan: Offset(stage.width * 0.2, 0),
        wordAlign: Alignment.centerLeft,
        wordSize: 54,
        wordWidth: 0.5,
        lineSize: 26,
      );
    }
    return _Frame(
      stage: stage,
      zoom: 0.36,
      pan: Offset(stage.width * 0.2, 6),
      wordAlign: const Alignment(-0.85, 0.1),
      wordSize: 66,
      wordWidth: 0.45,
      lineSize: 28,
    );
  }
}

/// What [GlassLayers] screens sit on.
enum GlassLook {
  /// The brand's ink, with the accent glowing.
  ink,

  /// Light: soft fields of the accent and its neighbours, drifting.
  mesh,

  /// The accent, whole: the brand colour as the ground.
  butter,

  /// Dark, with the beat's own screen huge and out of focus behind it.
  echo,

  /// A lit sweep: a wall curving into a floor, a light from above.
  studio,

  /// Dark, with a floor of lines in the world under the phone.
  grid,
}

class _FloorGrid extends CustomPainter {
  final Color color;

  const _FloorGrid(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 90.0;
    final c = size.center(Offset.zero);
    final paint = Paint()..strokeWidth = 3;
    for (var x = 0.0; x <= size.width; x += step) {
      for (var y = 0.0; y <= size.height; y += step) {
        // Lines fade toward the edges, so the floor has no hard end.
        final d = ((Offset(x, y) - c).distance / (size.width / 2)).clamp(
          0.0,
          1.0,
        );
        paint.color = color.withValues(alpha: 0.55 * (1 - d) * (1 - d));
        canvas
          ..drawLine(Offset(x, y), Offset(x + step, y), paint)
          ..drawLine(Offset(x, y), Offset(x, y + step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FloorGrid old) => old.color != color;
}
