import 'dart:math' as math;

import 'dart:ui' show ImageFilter;

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

  /// The screen, or the piece of the app this beat is about if [piece] is
  /// set.
  final Widget screen;

  /// Makes this beat about one piece of the app rather than a screen: a
  /// button, a card, a spinner, laid out at this size and shown large on
  /// the ground on its own, with no phone around it. Fingers in [taps]
  /// press it for real, so a button goes into its loading state.
  final Size? piece;

  /// Picks the widgets that lift off, the first the furthest. Up to three
  /// read best; [maxParts] lift.
  final List<Pick> lift;

  /// The most parts a beat lifts.
  static const maxParts = 6;

  /// This beat's words: how they look, sit and arrive, over the reel's.
  final GlassWords? words;

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

  /// A scan line passes over the first lifted widget as it rises: the move
  /// for a beat about reading something — a receipt, a document. The same
  /// as [move] [GlassMove.scan].
  final bool sweep;

  /// How the lifted parts leave the screen.
  final GlassMove move;

  /// Each lifted part's own move, in [lift]'s order, over [move]: where it
  /// lands, how high, how large, turned how, when, and whether it is
  /// scanned. A null (or a missing one) leaves that part to [move].
  final List<PartMove?> partMoves;

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
    this.sweep = false,
    this.move = GlassMove.lift,
    this.partMoves = const [],
    this.piece,
    this.words,
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

  /// How every beat's words look and sit, unless a beat says otherwise.
  final GlassWords? words;

  /// Frames blended per output frame.
  final int motionBlur;

  /// The beats swing the other way: the first one to the left. A beat
  /// rendered on its own keeps the side it swings to in its reel this way.
  final bool flip;

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
    this.flip = false,
    this.fps = 30,
    this.words,
  });

  /// Whether the ground is light, so words go dark on it.
  static bool _isLight(GlassLook l) => l.isLight;

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
    GlassLook.echo when beat.piece == null => [
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

  /// The ground [beat] sits on, if it is one of its own colours rather than
  /// a look's: the beat's, else (unless the beat chose a look) the reel's.
  Backdrop? _groundOf(GlassBeat? beat) {
    if (_override != null) return null;
    return beat?.ground ?? (beat?.look == null ? ground : null);
  }

  /// Whether [beat]'s ground is light, so its words go dark.
  bool _lightOf(GlassBeat? beat) =>
      _groundOf(beat)?.light ?? _isLight(beat == null ? _look : _lookOf(beat));

  /// The words' colour and accent on [beat]'s ground.
  Color _inkOn(GlassBeat? beat) => _lightOf(beat) ? brand.ink : brand.paper;
  Color _accentOn(GlassBeat? beat) {
    final g = _groundOf(beat);
    if (g?.light == null) {
      return _wordAccent(beat == null ? _look : _lookOf(beat));
    }
    return g!.light!
        ? Color.lerp(brand.accent, brand.ink, 0.35)!
        : brand.accent;
  }

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
      final dir = i.isEven != flip ? 1.0 : -1.0;
      scenes.add(beatScene(beat, dir));
      if (i < beats.length - 1) {
        transitions.add(Transition.swing(direction: dir));
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
    if (beat.piece != null) return _pieceScene(beat, dir);
    final move = beat.sweep ? GlassMove.scan : beat.move;
    final f = _frame.adjusted(
      // A spread reaches past the phone's sides, so it stands back a little.
      beat.zoom * (move == GlassMove.spread ? 0.86 : 1),
      beat.framing,
    );
    final bl = _lookOf(beat);
    final l = beat.length;
    const settle = Duration(milliseconds: 1500);
    const rise = Duration(milliseconds: 1500);
    const fallBack = 80.0;
    // Close enough together that one sharp band holds every lifted card:
    // lifted means in focus. Only the screen behind softens.
    final heights = switch (move) {
      GlassMove.spread => [190.0, 170.0, 150.0, 160.0, 180.0, 140.0],
      GlassMove.fan => [150.0, 170.0, 190.0, 210.0, 230.0, 250.0],
      GlassMove.zoom => [240.0, 150.0, 130.0, 120.0, 110.0, 100.0],
      _ => [220.0, 180.0, 145.0, 125.0, 110.0, 100.0],
    };
    final count = beat.lift.take(GlassBeat.maxParts).length;
    // A part's own height wins over the move's.
    for (var k = 0; k < count && k < beat.partMoves.length; k++) {
      final z = beat.partMoves[k]?.z;
      if (z != null) heights[k] = z;
    }
    final used = heights.take(math.max(count, 1));
    final top = used.reduce(math.max) - fallBack;
    final bottom = used.reduce(math.min) - fallBack;
    final lifted = settle + rise;

    final hasLift = beat.lift.isNotEmpty;
    final orbit = move == GlassMove.orbit;
    final camera = Camera.tracks(
      tilt: Track.from(15).to(settle, 6, Ease.arrive).to(l, 9, Ease.linear),
      // An orbit swings right round the phone; every other move drifts.
      turn: orbit
          ? Track.from(-34 * dir).to(l, 26 * dir, Ease.inOut)
          : Track.from(
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
          taps: [
            ...beat.taps,
            // A finger picks the part out before it rises.
            if (move == GlassMove.tap && hasLift)
              Tap(where: beat.lift.first, at: settle + 100.ms),
          ],
          scrolls: beat.scrolls,
          typing: [
            ...beat.typing,
            // A lifted field types once it is in place, unless told when.
            for (final (k, where) in beat.lift.take(GlassBeat.maxParts).indexed)
              if (beat.partMoves.elementAtOrNull(k)?.typing case final typing?)
                TypeText(
                  where: where,
                  text: typing.text,
                  at:
                      typing.at ??
                      _timing(beat, move, k, settle, rise).$3 + 250.ms,
                  perCharacter: typing.every,
                  sound: typing.sound ? 'tick' : null,
                ),
          ],
          motion: hasLift
              ? Motion(
                  z: Track.from(0).hold(settle).to(lifted, -fallBack),
                  opacity: Track.from(1)
                      .hold(settle)
                      .to(lifted, move == GlassMove.zoom ? 0.5 : 0.76),
                )
              : null,
          lifts: [
            for (final (k, where) in beat.lift.take(GlassBeat.maxParts).indexed)
              _lift(beat, move, where, k, count, heights[k], dir, settle, rise),
          ],
        ),
      ],
      words: [
        _beatWords(beat, f, bl, highlight, at: wordAt, until: l - 1100.ms),
      ],
      cues: [if (hasLift) Cue(settle, 'rise')],
    );
  }

  /// A beat's words: the pack's own look, under the reel's [words], under
  /// the beat's own.
  Words _beatWords(
    GlassBeat beat,
    _Frame f,
    GlassLook bl,
    String? highlight, {
    required Duration at,
    required Duration until,
  }) {
    final own = beat.words, reel = words;
    T? pick<T>(T? Function(GlassWords w) get) =>
        (own == null ? null : get(own)) ?? (reel == null ? null : get(reel));
    final light = _lightOf(beat);
    final color = pick((w) => w.color) ?? _inkOn(beat);
    final anchor = pick((w) => w.anchor);
    final size = pick((w) => w.size);
    final weight = pick((w) => w.weight);
    final plate = pick((w) => w.plate);
    final width = pick((w) => w.width);
    return Words(
      beat.word,
      // A width set by hand wraps the words at it; otherwise they shrink
      // to fit one line.
      fit: width == null,
      at: own?.at ?? at,
      until: own?.until ?? until,
      highlight: highlight,
      accent: pick((w) => w.accent) ?? _accentOn(beat),
      align: anchor ?? f.wordAlign,
      textAlign: anchor == null
          ? TextAlign.left
          : anchor.x < -0.3
          ? TextAlign.left
          : anchor.x > 0.3
          ? TextAlign.right
          : TextAlign.center,
      maxWidth: width ?? f.wordWidth,
      reveal: pick((w) => w.reveal) ?? Reveal.letters,
      offset: pick((w) => w.offset) ?? Offset.zero,
      plate: plate == null || plate.a == 0 ? null : plate,
      plateBlur: pick((w) => w.plateBlur) ?? 0,
      behind: pick((w) => w.behind) ?? false,
      // A size is set for a 9:16 frame; other frames scale it as the pack
      // scales its own.
      style: brand
          .words(size == null ? f.wordSize : size * f.wordSize / 80, color)
          .copyWith(
            fontWeight: weight,
            // The display face is variable: its weight is an axis too.
            fontVariations: weight == null
                ? null
                : [FontVariation('wght', weight.value.toDouble())],
            shadows: [
              Shadow(
                color: (light ? brand.paper : brand.ink).withValues(
                  alpha: light ? 0.35 : 0.6,
                ),
                blurRadius: 24,
              ),
            ],
          ),
    );
  }

  /// The [k]th of [count] parts lifting off in [move], to [height]: the
  /// move decides, and the part's own [PartMove] overrides what it sets.
  /// When part [k] starts to rise, when its rise ends, and when it is in
  /// place (sooner than the end for a pop's spring).
  static (Duration, Duration, Duration) _timing(
    GlassBeat beat,
    GlassMove move,
    int k,
    Duration settle,
    Duration rise,
  ) {
    final own = k < beat.partMoves.length ? beat.partMoves[k] : null;
    final start =
        settle +
        (own?.delay ?? (move == GlassMove.pop ? 320.ms : 250.ms) * k) +
        (move == GlassMove.tap ? 450.ms : Duration.zero);
    // How long it takes to rise: its own, or the beat's.
    final end = start + (own?.rise ?? rise);
    final arrive = move == GlassMove.pop ? start + (own?.rise ?? 650.ms) : end;
    return (start, end, arrive);
  }

  Lift _lift(
    GlassBeat beat,
    GlassMove move,
    Pick where,
    int k,
    int count,
    double height,
    double dir,
    Duration settle,
    Duration rise,
  ) {
    final own = k < beat.partMoves.length ? beat.partMoves[k] : null;
    final (start, end, arrive) = _timing(beat, move, k, settle, rise);
    final ease = move == GlassMove.pop ? Ease.pop : Curves.easeInOutCubic;
    Track up(double to) => Track.from(0).hold(start).to(arrive, to, ease);
    // Where it sits in a fan or a spread, from the middle one.
    final side = k - (count - 1) / 2;
    final scanned = own?.scan ?? (move == GlassMove.scan && k == 0);
    const spreadAt = [
      Offset(-118, -230),
      Offset(128, 20),
      Offset(-104, 260),
      Offset(120, -210),
      Offset(-125, 40),
      Offset(110, 250),
    ];
    final (Offset? to, double scale, double turn, double roll) = switch (move) {
      // Pulled apart round the phone, each turned toward the middle.
      GlassMove.spread => (
        Offset(spreadAt[k].dx * dir, spreadAt[k].dy),
        1.02,
        (k.isEven ? 14.0 : -14.0) * dir,
        0.0,
      ),
      // Gathered in the middle, overlapping, fanned like a hand of cards.
      GlassMove.fan => (
        Offset(78 * side * dir, 40.0 + 30 * side.abs()),
        1.04,
        0.0,
        8 * side * dir,
      ),
      // The first part comes forward to the middle of the screen, large.
      GlassMove.zoom when k == 0 => (const Offset(0, -30), 1.38, 0.0, 0.0),
      GlassMove.pop => (null, k == 0 ? 1.08 : 1.04, 0.0, 0.0),
      // Something being read rises larger, so the scan line over it reads
      // at a glance.
      _ => (null, scanned ? 1.45 : (k == 0 ? 1.06 : 1.03), 0.0, 0.0),
    };
    final lands = own?.to ?? to;
    return Lift(
      where: where,
      radius: beat.liftRadius,
      hole: hole?.call(beat.liftRadius),
      glass: const Glass(depth: 6, color: Color(0x30FFFFFF)),
      sweep: scanned ? Sweep(at: start + 600.ms, color: brand.accent) : null,
      motion: Motion(
        z: up(height),
        // Off to one side a little, unless it is going somewhere.
        x: lands == null && move != GlassMove.pop && k > 0
            ? up(10.0 * dir * k)
            : null,
        scale: Track.from(1).hold(start).to(arrive, own?.scale ?? scale, ease),
        tilt: own?.tilt == null ? null : up(own!.tilt!),
        turn: (own?.turn ?? turn) == 0 ? null : up(own?.turn ?? turn),
        roll: (own?.roll ?? roll) == 0 ? null : up(own?.roll ?? roll),
      ),
      to: lands,
      travel: lands == null
          ? null
          : Track.from(0).hold(start).to(end, 1, Ease.inOut),
    );
  }

  /// A beat about one piece of the app: it arrives out of the ground on its
  /// own, large, with no phone around it, and does what it does — a button
  /// pressed into its loading state, a placeholder pulsing — while the
  /// camera drifts round it. It sits in the room the word leaves: above it
  /// on a tall frame, beside it on a wide one.
  Scene _pieceScene(GlassBeat beat, double dir) {
    final f = _frame;
    final stage = f.stage;
    final tall = stage.height / stage.width > 1.1;
    final bl = _lookOf(beat);
    final light = _lightOf(beat);
    final l = beat.length;
    final size = beat.piece!;
    const settle = Duration(milliseconds: 1300);
    final room = tall
        ? Size(stage.width * 0.84, stage.height * 0.4)
        : Size(stage.width * 0.44, stage.height * 0.6);
    final centre =
        (tall
            ? Offset(0, -stage.height * 0.1)
            : Offset(stage.width * 0.22, 0)) +
        beat.framing;
    final scale =
        math.min(room.width / size.width, room.height / size.height) *
        beat.zoom;
    final highlight = beat.highlight ?? (beat.word.endsWith('.') ? '.' : null);
    return Scene(
      name: beat.word,
      length: l,
      camera: Camera.tracks(
        tilt: Track.from(12).to(settle, 4, Ease.arrive).to(l, 7, Ease.linear),
        turn: Track.from(
          -16 * dir,
        ).to(settle, -6 * dir, Ease.arrive).to(l, -10 * dir, Ease.linear),
        roll: Track.from(
          -3 * dir,
        ).to(settle, -1 * dir, Ease.arrive).to(l, -2 * dir, Ease.linear),
        zoom: Track.from(0.92).to(settle, 1, Ease.arrive).to(l, 1.04),
      ),
      backdrop: _override == null
          ? (beat.ground ?? (bl != _look ? backdropOf(bl) : null))
          : null,
      layers: [
        ..._ambient(beat, bl),
        // Its own silhouette, soft and a little below, so it stands off the
        // ground even when the two share a colour.
        Layer.component(
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Color(light ? 0x38000000 : 0x80000000),
                BlendMode.srcIn,
              ),
              child: beat.screen,
            ),
          ),
          size: size,
          position: centre + Offset(0, 10 * scale),
          motion: Motion(
            z: Track.from(-340).to(settle, -20, Ease.out),
            y: Track.from(0).hold(settle).to(l, -6),
            scale: Track.constant(scale),
            blur: Track.from(12).to(900.ms, 0, Ease.out),
            opacity: Track.from(0).hold(300.ms).to(settle, 1, Ease.out),
          ),
        ),
        Layer.component(
          beat.screen,
          size: size,
          position: centre,
          taps: beat.taps,
          typing: beat.typing,
          motion: Motion(
            z: Track.from(-320).to(settle, 0, Ease.out),
            y: Track.from(0).hold(settle).to(l, -10),
            scale: Track.constant(scale),
            blur: Track.from(12).to(900.ms, 0, Ease.out),
            opacity: Track.from(0).to(600.ms, 1, Ease.out),
          ),
        ),
      ],
      words: [
        _beatWords(beat, f, bl, highlight, at: 1.1.s, until: l - 1100.ms),
      ],
      cues: const [Cue(Duration(milliseconds: 150), 'rise')],
    );
  }

  /// The end card as a scene.
  Scene endScene(GlassEnd end) {
    final f = _frame;
    final l = end.length;
    final stage = f.stage;
    // Pieces of the app are not screens: the fan is of screens only.
    final screens = [
      for (final b in beats)
        if (b.piece == null) b,
    ];
    final n = screens.length;
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
          for (final (i, beat) in screens.indexed)
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
            style: brand.words(f.lineSize, _inkOn(null), tracking: -0.02),
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
                  _lightOf(null) ? brand.ink : brand.accent,
                  weight: 600,
                )
                .copyWith(
                  shadows: [
                    Shadow(
                      color: (_lightOf(null) ? brand.paper : brand.ink)
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

/// Whether a look's ground is light, so words and logos go dark on it.
extension GlassLookTone on GlassLook {
  /// Light grounds: mesh, butter, studio.
  bool get isLight =>
      this == GlassLook.mesh ||
      this == GlassLook.butter ||
      this == GlassLook.studio;
}

/// How a beat's words look, sit and arrive, over the pack's own: set for
/// the whole reel on [GlassLayers.words], and any beat's own on
/// [GlassBeat.words]. Whatever is null is left to what is under it.
class GlassWords {
  /// The words' colour.
  final Color? color;

  /// The accented part's colour (the full stop, or what is in braces).
  final Color? accent;

  /// Font size, in stage units on a 9:16 frame (the pack's own is 80);
  /// other frames scale it as they scale their own.
  final double? size;

  /// Font weight.
  final FontWeight? weight;

  /// How they arrive.
  final Reveal? reveal;

  /// When they arrive, in the beat's own time.
  final Duration? at;

  /// When they leave.
  final Duration? until;

  /// Where in the frame's safe area they sit.
  final Alignment? anchor;

  /// Moved from the anchor, as fractions of the frame.
  final Offset? offset;

  /// Their widest, as a fraction of the safe area's width; longer lines
  /// wrap.
  final double? width;

  /// A backing plate; fully transparent means none.
  final Color? plate;

  /// Frosting behind the plate.
  final double? plateBlur;

  /// Behind the phone and its parts rather than in front.
  final bool? behind;

  /// Words.
  const GlassWords({
    this.color,
    this.accent,
    this.size,
    this.weight,
    this.reveal,
    this.at,
    this.until,
    this.anchor,
    this.offset,
    this.width,
    this.plate,
    this.plateBlur,
    this.behind,
  });
}

/// One lifted part's own way off the screen, over its beat's [GlassMove]:
/// whatever is set here wins, whatever is null the move decides.
class PartMove {
  /// Where its centre lands, from the screen's centre, in screen units;
  /// null rises where it sat.
  final Offset? to;

  /// How high it rises off the screen.
  final double? z;

  /// How large it grows.
  final double? scale;

  /// Leaning back or forward, degrees.
  final double? tilt;

  /// Turning left or right, degrees.
  final double? turn;

  /// Rolling in the screen's plane, degrees.
  final double? roll;

  /// When it starts, after the screen settles.
  final Duration? delay;

  /// How long it takes to rise into place.
  final Duration? rise;

  /// A scan line passes over it as it rises.
  final bool? scan;

  /// Text typed into the field in it.
  final PartTyping? typing;

  /// A part's move.
  const PartMove({
    this.to,
    this.z,
    this.scale,
    this.tilt,
    this.turn,
    this.roll,
    this.delay,
    this.rise,
    this.scan,
    this.typing,
  });

  /// From a spec's part: `{"to": [x, y], "z", "scale", "tilt", "turn",
  /// "roll", "delay" (ms), "rise" (ms), "scan", "typing": {"text", "at"
  /// (ms into the beat), "every" (ms a character), "sound"}}`; null if it
  /// sets none of them.
  static PartMove? fromJson(Map<String, Object?> j) {
    double? n(String k) => j[k] is num ? (j[k]! as num).toDouble() : null;
    final to = j['to'];
    final m = PartMove(
      to: to is List && to.length == 2 && to[0] is num && to[1] is num
          ? Offset((to[0] as num).toDouble(), (to[1] as num).toDouble())
          : null,
      z: n('z'),
      scale: n('scale'),
      tilt: n('tilt'),
      turn: n('turn'),
      roll: n('roll'),
      delay: n('delay') == null
          ? null
          : Duration(milliseconds: n('delay')!.round()),
      rise: n('rise') == null
          ? null
          : Duration(milliseconds: n('rise')!.round()),
      scan: j['scan'] is bool ? j['scan']! as bool : null,
      typing: PartTyping.fromJson(j['typing']),
    );
    final any =
        m.to != null ||
        m.z != null ||
        m.scale != null ||
        m.tilt != null ||
        m.turn != null ||
        m.roll != null ||
        m.delay != null ||
        m.rise != null ||
        m.scan != null ||
        m.typing != null;
    return any ? m : null;
  }
}

/// Text typed into a lifted part's field, as a keyboard would.
class PartTyping {
  /// What is typed: the keys pressed, which the field formats as it would
  /// for a person ("186" in a money field shows R186.00).
  final String text;

  /// When typing starts, from the beat's start; null for just after the
  /// part is in place.
  final Duration? at;

  /// Time between keys.
  final Duration every;

  /// A soft tick for each key.
  final bool sound;

  /// Typing.
  const PartTyping(
    this.text, {
    this.at,
    this.every = const Duration(milliseconds: 90),
    this.sound = true,
  });

  /// From a spec: `{"text", "at", "every", "sound"}`; null without text.
  static PartTyping? fromJson(Object? v) {
    if (v is! Map || v['text'] is! String || '${v['text']}'.isEmpty) {
      return null;
    }
    Duration? ms(Object? n) =>
        n is num ? Duration(milliseconds: n.round()) : null;
    return PartTyping(
      '${v['text']}',
      at: ms(v['at']),
      every: ms(v['every']) ?? const Duration(milliseconds: 90),
      sound: v['sound'] != false,
    );
  }
}

/// How a [GlassBeat]'s parts leave its screen.
enum GlassMove {
  /// Straight up off the screen, toward the camera.
  lift,

  /// Up, the first larger, with a scan line passing over it: reading.
  scan,

  /// Pulled apart round the phone, past its sides, each turned to the
  /// middle: an exploded view.
  spread,

  /// Gathered in the middle, overlapping, fanned like a hand of cards.
  fan,

  /// The first part comes forward to the middle, large; the screen dims.
  zoom,

  /// A finger taps the first part, then they lift.
  tap,

  /// One after another, each springing up past its place and back.
  pop,

  /// Up as in [lift], while the camera swings right round the phone.
  orbit,
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
