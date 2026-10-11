import 'package:flutter/widgets.dart';

import '../audio.dart';
import '../camera.dart';
import '../format.dart';
import '../layer.dart';
import '../motion.dart';
import '../scene.dart';
import '../time.dart';
import '../words.dart';
import 'brand.dart';
import 'glass_layers.dart';

/// A recorded voice-over line for one part of a [StoryAd]: the file and
/// what it says. Placed at its part's start, plus [delay].
class StoryVoice {
  /// The recording.
  final String path;

  /// What it says, for captions and the studio.
  final String text;

  /// From the start of its part.
  final Duration delay;

  /// A line.
  const StoryVoice(
    this.path,
    this.text, {
    this.delay = const Duration(milliseconds: 250),
  });
}

/// The Story Ad style pack: a pain-first hook, the problem, the product
/// arriving, its beats, proof, and a call to action, with a voice-over line
/// for any part. From the Meetris and Hector ads.
///
/// The beats are [GlassBeat]s and play as Glass Layers does.
class StoryAd {
  /// The look.
  final Brand brand;

  /// The frame.
  final Format format;

  /// The hook: short lines, typed one after another.
  final List<String> hook;

  /// The problem: lines that build up, key parts in braces.
  final List<String> problem;

  /// The product arriving: its mark, built from the part's clock.
  final Widget Function(Duration t) meet;

  /// The mark's box.
  final Size meetSize;

  /// A line under the mark.
  final String? meetLine;

  /// The beats.
  final List<GlassBeat> beats;

  /// Proof: lines that hold, key parts in braces. Only what is true.
  final List<String> proof;

  /// The call to action.
  final GlassEnd end;

  /// Voice-over, by part: `hook`, `problem`, `meet`, `beat 0`…, `proof`,
  /// `end`.
  final Map<String, StoryVoice> voice;

  /// Drawn where a lifted widget was.
  final Widget Function(double radius)? hole;

  /// Drawn over the top of each screen.
  final Widget? statusBar;

  /// A music bed, ducked under the voice.
  final Music? music;

  /// Frames per second.
  final int fps;

  /// Frames blended per output frame.
  final int motionBlur;

  /// A Story Ad.
  const StoryAd({
    required this.brand,
    required this.hook,
    required this.meet,
    required this.beats,
    required this.end,
    this.format = Format.vertical,
    this.problem = const [],
    this.meetSize = const Size(200, 200),
    this.meetLine,
    this.proof = const [],
    this.voice = const {},
    this.hole,
    this.statusBar,
    this.music,
    this.fps = 30,
    this.motionBlur = 1,
  });

  bool get _wide => !format.isTall;

  /// The reel.
  Reel build(String name) {
    final glass = GlassLayers(
      brand: brand,
      format: format,
      beats: beats,
      hole: hole,
      statusBar: statusBar,
      fps: fps,
    );
    final parts = <(String, Scene)>[
      ('hook', _hook()),
      if (problem.isNotEmpty) ('problem', _lines('problem', problem)),
      ('meet', _meet()),
      for (final (i, b) in beats.indexed)
        ('beat $i', glass.beatScene(b, i.isEven ? 1 : -1)),
      if (proof.isNotEmpty) ('proof', _lines('proof', proof)),
      ('end', glass.endScene(end)),
    ];
    final transitions = <Transition>[
      for (var i = 0; i < parts.length - 1; i++)
        switch (parts[i + 1].$1) {
          'meet' => const Transition.fade(length: Duration(milliseconds: 500)),
          final next when next.startsWith('beat') && parts[i].$1 == 'meet' =>
            const Transition.zoomThrough(),
          final next when next.startsWith('beat') => Transition.swing(
            direction: i.isEven ? 1 : -1,
          ),
          'end' => const Transition.rise(),
          _ => const Transition.fade(length: Duration(milliseconds: 500)),
        },
    ];

    Reel reel(Soundtrack soundtrack) => Reel(
      name: name,
      format: format,
      fps: fps,
      motionBlur: motionBlur,
      backdrop: glass.backdrop,
      scenes: [for (final p in parts) p.$2],
      transitions: transitions,
      soundtrack: soundtrack,
    );

    // The voice-over sits on each part's start, which only the timeline
    // knows: lay it out once to find out.
    final timeline = reel(const Soundtrack()).timeline;
    final lines = <VoiceLine>[
      for (final (i, (key, _)) in parts.indexed)
        if (voice[key] case final v?)
          VoiceLine(timeline[i].start + v.delay, v.path, v.text),
    ];
    return reel(
      Soundtrack(music: music, voice: lines, cueGain: -10, duck: true),
    );
  }

  TextStyle _big(double size) => brand.words(size, brand.paper);

  Scene _hook() {
    const each = Duration(milliseconds: 1500);
    final l = each * hook.length + 600.ms;
    return Scene(
      name: 'hook',
      length: l,
      camera: Camera.still(const CameraPose()),
      words: [
        for (final (i, line) in hook.indexed)
          Words(
            line,
            at: each * i + 200.ms,
            // The last line leaves before the part does, so it never
            // crossfades over the next part's words.
            until: i == hook.length - 1 ? l - 1000.ms : each * (i + 1),
            reveal: Reveal.typewriter,
            stagger: 38.ms,
            align: Alignment.center,
            textAlign: TextAlign.center,
            maxWidth: _wide ? 0.75 : 0.95,
            accent: brand.accent,
            style: _big(_wide ? 58 : 44),
          ),
      ],
    );
  }

  Scene _lines(String name, List<String> lines) {
    const each = Duration(milliseconds: 900);
    final l = each * lines.length + 1600.ms;
    final gap = _wide ? 0.4 : 0.46;
    final top = -gap * (lines.length - 1) / 2;
    return Scene(
      name: name,
      length: l,
      camera: Camera.still(const CameraPose()),
      words: [
        for (final (i, line) in lines.indexed)
          Words(
            line,
            at: each * i + 150.ms,
            until: l - 1000.ms,
            reveal: Reveal.words,
            stagger: 90.ms,
            align: Alignment(0, top + gap * i),
            textAlign: TextAlign.center,
            maxWidth: 0.95,
            accent: brand.accent,
            style: _big(_wide ? 42 : 32),
          ),
      ],
    );
  }

  Scene _meet() {
    const l = Duration(milliseconds: 2800);
    final stage = format.logical;
    return Scene(
      name: 'meet',
      length: l,
      camera: Camera.tracks(zoom: Track.from(1).to(l, 1.06, Ease.linear)),
      layers: [
        Layer.timed(
          meet,
          size: meetSize,
          position: Offset(0, -stage.height * 0.06),
          motion: Motion(
            z: Track.from(-300).to(1200.ms, 0, Ease.out),
            blur: Track.from(12).to(1000.ms, 0, Ease.out),
            opacity: Track.from(0).to(500.ms, 1, Ease.out),
          ),
        ),
      ],
      words: [
        if (meetLine != null)
          Words(
            meetLine!,
            at: 1.s,
            reveal: Reveal.words,
            stagger: 80.ms,
            align: Alignment(0, _wide ? 0.62 : 0.5),
            textAlign: TextAlign.center,
            maxWidth: 0.9,
            accent: brand.accent,
            style: _big(_wide ? 34 : 28),
          ),
      ],
      cues: const [Cue(Duration(milliseconds: 100), 'rise')],
    );
  }
}
