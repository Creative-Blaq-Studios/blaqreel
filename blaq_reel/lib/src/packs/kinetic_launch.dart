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

/// One beat of [KineticLaunch]: a line, its key part in braces, and the
/// screen that sweeps in beside it.
class KineticBeat {
  /// The line, with the key part in braces: `'Split the {bill}.'`.
  final String text;

  /// The screen, or null for words alone.
  final Widget? screen;

  /// Widgets that lift off the screen once it lands.
  final List<Pick> lift;

  /// The lifted widgets' corner radius.
  final double liftRadius;

  /// How long it runs, transitions included.
  final Duration length;

  /// Fingers on the screen, at the beat's own times.
  final List<Tap> taps;

  /// The device.
  final Device device;

  /// A beat.
  const KineticBeat(
    this.text, {
    this.screen,
    this.lift = const [],
    this.liftRadius = 24,
    this.length = const Duration(milliseconds: 4200),
    this.taps = const [],
    this.device = Device.iphone,
  });
}

/// The Kinetic Launch style pack: a light ground of slow colour, lines that
/// arrive word by word with the key word marked in the accent, and devices
/// that sweep in beside them. From the LangEase launch film.
class KineticLaunch {
  /// The look.
  final Brand brand;

  /// The frame; wide suits it best.
  final Format format;

  /// The beats.
  final List<KineticBeat> beats;

  /// The logo for the last card, built from its clock.
  final Widget Function(Duration t)? logo;

  /// The logo's box.
  final Size logoSize;

  /// A line under the logo.
  final String? line;

  /// An address under that.
  final String? url;

  /// Drawn where a lifted widget was.
  final Widget Function(double radius)? hole;

  /// Drawn over the top of each screen.
  final Widget? statusBar;

  /// Dark ground instead of light.
  final bool dark;

  /// A music bed.
  final Music? music;

  /// Frames per second.
  final int fps;

  /// Frames blended per output frame.
  final int motionBlur;

  /// A Kinetic Launch reel.
  const KineticLaunch({
    required this.brand,
    required this.beats,
    this.format = Format.wide,
    this.logo,
    this.logoSize = const Size(300, 100),
    this.line,
    this.url,
    this.hole,
    this.statusBar,
    this.dark = false,
    this.music,
    this.fps = 30,
    this.motionBlur = 1,
  });

  Size get _stage => format.logical;

  Color get _ink => dark ? brand.paper : brand.ink;

  /// The reel.
  Reel build(String name) {
    final scenes = [
      for (final (i, b) in beats.indexed) _beat(b, i),
      if (logo != null) _end(),
    ];
    return Reel(
      name: name,
      format: format,
      fps: fps,
      motionBlur: motionBlur,
      backdrop: dark
          ? blobs(brand.ink, [
              brand.accent.withValues(alpha: 0.5),
              brand.paper.withValues(alpha: 0.12),
            ], strength: 0.35)
          : blobs(brand.paper, [
              brand.accent,
              Color.lerp(brand.accent, const Color(0xFFFFFFFF), 0.5)!,
              brand.accent.withValues(alpha: 0.6),
            ], strength: 0.5),
      scenes: scenes,
      transitions: const [Transition.rise(length: Duration(milliseconds: 750))],
      soundtrack: Soundtrack(music: music, cueGain: -9),
    );
  }

  Scene _beat(KineticBeat beat, int i) {
    final stage = _stage;
    final wide = !format.isTall;
    final l = beat.length;
    final zoom = wide ? 0.33 : 0.46;
    final screenAt = Offset(
      wide ? stage.width * 0.62 : 0,
      wide ? 0 : stage.height * 0.36,
    );
    const lands = Duration(milliseconds: 1700);
    return Scene(
      name: beat.text.replaceAll(RegExp('[{}]'), ''),
      length: l,
      camera: Camera.tracks(
        zoom: Track.from(zoom * 0.97).to(l, zoom * 1.03, Ease.linear),
        turn: Track.from(-10).to(l, -6, Ease.linear),
        tilt: Track.constant(4),
        // Focus rises with the first lift, so it stays sharp and the
        // screen softens behind it.
        focus: Track.from(0).hold(lands).to(lands + 900.ms, 140),
        aperture: Track.from(0).hold(lands).to(lands + 900.ms, 1.4),
        // Both lifts sit inside the sharp band.
        depth: Track.from(0).hold(lands).to(lands + 900.ms, 34),
      ),
      layers: [
        if (beat.screen != null)
          Layer.screen(
            beat.screen!,
            device: beat.device,
            statusBar: statusBar,
            taps: beat.taps,
            position: screenAt,
            motion: Motion(
              x: Track.from(
                stage.width * 1.4,
              ).hold(600.ms).to(lands, 0, Ease.out),
              turn: Track.from(-40).hold(600.ms).to(lands, -14, Ease.out),
              roll: Track.from(8).hold(600.ms).to(lands, 0, Ease.out),
              z: Track.from(-120).hold(600.ms).to(lands, 0, Ease.out),
            ),
            lifts: [
              for (final (k, where) in beat.lift.take(2).indexed)
                Lift(
                  where: where,
                  radius: beat.liftRadius,
                  hole: hole?.call(beat.liftRadius),
                  motion: Motion(
                    z: Track.from(0)
                        .hold(lands + 150.ms * k)
                        .to(lands + 900.ms + 150.ms * k, k == 0 ? 160 : 120),
                  ),
                ),
            ],
          ),
      ],
      words: [
        Words(
          beat.text,
          at: 250.ms,
          until: l - 650.ms,
          reveal: Reveal.words,
          stagger: 130.ms,
          rise: 650.ms,
          align: wide
              ? const Alignment(-1, -0.05)
              : (beat.screen == null
                    ? Alignment.center
                    : const Alignment(-1, -0.82)),
          maxWidth: wide && beat.screen != null ? 0.5 : 0.95,
          accent: dark ? brand.accent : brand.ink,
          marker: true,
          markerColor: brand.accent.withValues(alpha: dark ? 0.35 : 0.85),
          style: brand.words(wide ? 50 : 46, _ink, tracking: -0.03),
        ),
      ],
      cues: [
        if (beat.screen != null)
          const Cue(Duration(milliseconds: 600), 'whoosh'),
      ],
    );
  }

  Scene _end() {
    const l = Duration(milliseconds: 3600);
    final wide = !format.isTall;
    return Scene(
      name: 'end',
      length: l,
      camera: Camera.tracks(zoom: Track.from(0.98).to(l, 1.03, Ease.linear)),
      layers: [
        Layer.timed(
          logo!,
          size: logoSize,
          position: Offset(0, -_stage.height * 0.08),
          motion: Motion(
            scale: Track.from(0.85).to(900.ms, 1, Ease.out),
            opacity: Track.from(0).to(500.ms, 1, Ease.out),
          ),
        ),
      ],
      words: [
        if (line != null)
          Words(
            line!,
            at: 700.ms,
            reveal: Reveal.words,
            stagger: 80.ms,
            align: Alignment(0, wide ? 0.42 : 0.3),
            textAlign: TextAlign.center,
            maxWidth: 0.9,
            accent: dark ? brand.accent : brand.ink,
            marker: true,
            markerColor: brand.accent.withValues(alpha: dark ? 0.35 : 0.85),
            style: brand.words(wide ? 30 : 28, _ink, tracking: -0.02),
          ),
        if (url != null)
          Words(
            url!,
            at: 1.3.s,
            reveal: Reveal.fade,
            align: Alignment(0, wide ? 0.68 : 0.48),
            textAlign: TextAlign.center,
            style: brand.small(wide ? 15 : 14, _ink.withValues(alpha: 0.7)),
          ),
      ],
      cues: const [Cue(Duration(milliseconds: 300), 'chime')],
    );
  }
}
