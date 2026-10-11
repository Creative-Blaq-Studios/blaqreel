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

  /// Dark ground with the accent glowing, or the brand's light paper.
  final bool dark;

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
    this.dark = true,
    this.music,
    this.voice = const [],
    this.motionBlur = 1,
    this.fps = 30,
  });

  /// The look's backdrop.
  Backdrop get backdrop => dark
      ? Backdrop(
          top: Color.lerp(brand.ink, const Color(0xFFFFFFFF), 0.03)!,
          bottom: Color.lerp(brand.ink, const Color(0xFF000000), 0.55)!,
          vignette: 0.4,
          glows: [
            Glow(
              brand.accent.withValues(alpha: 0.28),
              center: const Alignment(0.4, -0.35),
              radius: 0.55,
            ),
            Glow(
              brand.accent.withValues(alpha: 0.1),
              center: const Alignment(-0.7, 0.75),
              radius: 0.45,
              period: 13,
            ),
          ],
        )
      : Backdrop(
          top: brand.paper,
          bottom: Color.lerp(brand.paper, const Color(0xFF000000), 0.1)!,
          vignette: 0.12,
          glows: [
            Glow(
              brand.accent.withValues(alpha: 0.7),
              center: const Alignment(0.45, -0.3),
              radius: 0.5,
            ),
          ],
        );

  Color get _wordColor => dark ? brand.paper : brand.ink;

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
    final l = beat.length;
    const settle = Duration(milliseconds: 1500);
    const lifted = Duration(milliseconds: 3000);
    const heroHeight = 220.0;
    const fallBack = 80.0;
    final heights = [heroHeight, 150.0, 95.0];

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
          ? Track.from(0).hold(settle).to(lifted, heroHeight - fallBack)
          : null,
      aperture: hasLift ? Track.from(0).hold(settle).to(lifted, 2.2) : null,
    );

    final wordAt = hasLift ? 2.s : 1.2.s;
    final highlight = beat.highlight ?? (beat.word.endsWith('.') ? '.' : null);
    return Scene(
      name: beat.word,
      length: l,
      camera: camera,
      speed: beat.slowLift == 1
          ? null
          : Track.from(1)
                .hold(settle - 200.ms)
                .to(settle + 300.ms, beat.slowLift)
                .hold(lifted - 300.ms)
                .to(lifted + 300.ms, 1),
      layers: [
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
          accent: brand.accent,
          align: f.wordAlign,
          maxWidth: f.wordWidth,
          style: brand
              .words(f.wordSize, _wordColor)
              .copyWith(
                shadows: [
                  Shadow(
                    color: (dark ? brand.ink : brand.paper).withValues(
                      alpha: 0.6,
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
            style: brand.words(f.lineSize, _wordColor, tracking: -0.02),
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
                .small(f.lineSize * 0.42, brand.accent, weight: 600)
                .copyWith(
                  shadows: [
                    Shadow(
                      color: brand.ink.withValues(alpha: 0.9),
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
