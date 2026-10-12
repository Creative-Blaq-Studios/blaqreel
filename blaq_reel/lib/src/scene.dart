import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'audio.dart';
import 'backdrop.dart';
import 'camera.dart';
import 'format.dart';
import 'layer.dart';
import 'time.dart';
import 'words.dart';

/// One stretch of a reel: its own camera, layers and words on its own clock,
/// which starts at zero when the scene does.
class Scene {
  /// A name, for the studio's timeline.
  final String name;

  /// How long it is on screen, transitions included.
  final Duration length;

  /// The camera.
  final Camera camera;

  /// The world's layers.
  final List<Layer> layers;

  /// Words over the world, flat to the frame.
  final List<Words> words;

  /// Its own backdrop, crossfading with its neighbours'; null uses the
  /// reel's.
  final Backdrop? backdrop;

  /// Sounds, at the scene's own times.
  final List<Cue> cues;

  /// Playback speed over time on screen: below 1 is slow motion.
  final TimeWarp? speed;

  /// A scene.
  Scene({
    required this.name,
    required this.length,
    required this.camera,
    this.layers = const [],
    this.words = const [],
    this.backdrop,
    this.cues = const [],
    Track? speed,
  }) : speed = speed == null ? null : TimeWarp(speed);

  /// The scene's own time, [t] after it starts on screen.
  Duration local(Duration t) => speed?.map(t) ?? t;
}

/// What a transition does to a scene's camera, opacity and outline at one
/// moment.
class SceneEffect {
  /// Added to the camera's angles.
  final double tilt;

  /// Added to the camera's swing.
  final double turn;

  /// Multiplies the camera's zoom.
  final double zoom;

  /// Added to the camera's pan, in stage units.
  final Offset pan;

  /// Added blur.
  final double blur;

  /// The whole scene's opacity.
  final double opacity;

  /// A circle the scene shows through: its radius as a fraction of the
  /// stage's diagonal, and its centre. Null shows all of it.
  final double? clip;

  /// The circle's centre.
  final Alignment clipCenter;

  /// An effect.
  const SceneEffect({
    this.tilt = 0,
    this.turn = 0,
    this.zoom = 1,
    this.pan = Offset.zero,
    this.blur = 0,
    this.opacity = 1,
    this.clip,
    this.clipCenter = Alignment.center,
  });

  /// No effect.
  static const none = SceneEffect();

  /// [pose] with this effect's camera changes.
  CameraPose apply(CameraPose pose) =>
      pose.nudged(tilt: tilt, turn: turn, zoom: zoom, pan: pan, blur: blur);
}

/// The kinds of [Transition].
enum TransitionKind {
  /// Straight from one to the next.
  cut,

  /// A crossfade.
  fade,

  /// The camera swings on to the next scene, which waits beside this one.
  swing,

  /// The camera pushes through this scene into the next.
  zoomThrough,

  /// The next scene opens in a growing circle.
  wipe,

  /// The next scene rises from below as this one lifts away.
  rise,
}

/// How one scene hands over to the next. The two overlap for [length].
class Transition {
  /// What happens.
  final TransitionKind kind;

  /// How long the two scenes overlap.
  final Duration length;

  /// For [TransitionKind.swing]: 1 brings the next scene in from the right,
  /// -1 from the left.
  final double direction;

  /// For [TransitionKind.wipe]: where the circle opens.
  final Alignment origin;

  /// The sound at the start, or null for none.
  final String? sound;

  const Transition._(
    this.kind,
    this.length, {
    this.direction = 1,
    this.origin = Alignment.center,
    this.sound,
  });

  /// Straight cut.
  static const cut = Transition._(TransitionKind.cut, Duration.zero);

  /// A crossfade.
  const Transition.fade({Duration length = const Duration(milliseconds: 600)})
    : this._(TransitionKind.fade, length);

  /// The camera swings on to the next scene.
  const Transition.swing({
    Duration length = const Duration(milliseconds: 900),
    double direction = 1,
    String? sound = 'whoosh',
  }) : this._(TransitionKind.swing, length, direction: direction, sound: sound);

  /// The camera pushes through into the next scene.
  const Transition.zoomThrough({
    Duration length = const Duration(milliseconds: 800),
    String? sound = 'whoosh',
  }) : this._(TransitionKind.zoomThrough, length, sound: sound);

  /// The next scene opens in a growing circle from [origin].
  const Transition.wipe({
    Duration length = const Duration(milliseconds: 700),
    Alignment origin = Alignment.center,
    String? sound = 'whoosh',
  }) : this._(TransitionKind.wipe, length, origin: origin, sound: sound);

  /// The next scene rises from below.
  const Transition.rise({
    Duration length = const Duration(milliseconds: 900),
    String? sound = 'whoosh',
  }) : this._(TransitionKind.rise, length, sound: sound);

  static double _smooth(double a, double b, double x) {
    final p = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return p * p * (3 - 2 * p);
  }

  /// The scene leaving, [p] of the way through.
  SceneEffect outgoing(double p, Size stage) {
    final e = Ease.inOut.transform(p);
    return switch (kind) {
      TransitionKind.cut => SceneEffect.none,
      TransitionKind.fade => SceneEffect(opacity: 1 - p),
      TransitionKind.swing => SceneEffect(
        pan: Offset(-direction * stage.width * 1.05 * e, 0),
        turn: direction * 22 * e,
        blur: 3 * e,
        opacity: 1 - _smooth(0.55, 1, p),
      ),
      TransitionKind.zoomThrough => SceneEffect(
        zoom: 1 + 2.4 * e * e,
        blur: 10 * e,
        opacity: 1 - _smooth(0.45, 0.9, p),
      ),
      TransitionKind.wipe => SceneEffect.none,
      TransitionKind.rise => SceneEffect(
        pan: Offset(0, -stage.height * 0.55 * e),
        tilt: -10 * e,
        blur: 4 * e,
        opacity: 1 - _smooth(0.4, 0.9, p),
      ),
    };
  }

  /// The scene arriving, [p] of the way through.
  SceneEffect incoming(double p, Size stage) {
    final e = Ease.inOut.transform(p);
    return switch (kind) {
      TransitionKind.cut => SceneEffect.none,
      TransitionKind.fade => SceneEffect(opacity: p),
      TransitionKind.swing => SceneEffect(
        pan: Offset(direction * stage.width * 1.05 * (1 - e), 0),
        turn: -direction * 22 * (1 - e),
        blur: 3 * (1 - e),
        opacity: _smooth(0, 0.45, p),
      ),
      TransitionKind.zoomThrough => SceneEffect(
        zoom: 0.72 + 0.28 * e,
        blur: 8 * (1 - e),
        opacity: _smooth(0.25, 0.75, p),
      ),
      TransitionKind.wipe => SceneEffect(
        clip: Ease.out.transform(p),
        clipCenter: origin,
      ),
      TransitionKind.rise => SceneEffect(
        pan: Offset(0, stage.height * 0.7 * (1 - e)),
        tilt: 18 * (1 - e),
        blur: 4 * (1 - e),
        opacity: _smooth(0, 0.4, p),
      ),
    };
  }
}

/// A scene's place on the reel's timeline.
class SceneSpan {
  /// The scene.
  final Scene scene;

  /// Its index in the reel.
  final int index;

  /// When it starts on screen.
  final Duration start;

  /// When it ends on screen.
  final Duration end;

  /// How it arrives, if it follows another scene.
  final Transition? enter;

  /// How it leaves, if another scene follows.
  final Transition? exit;

  /// A span.
  const SceneSpan(
    this.scene,
    this.index,
    this.start,
    this.end, {
    this.enter,
    this.exit,
  });

  /// Whether it is on screen at [t].
  bool shows(Duration t) => t >= start && t < end;

  /// The transition's effect on it at [t].
  SceneEffect effect(Duration t, Size stage) {
    final enter = this.enter;
    if (enter != null && t < start + enter.length) {
      return enter.incoming(progress(t, start, start + enter.length), stage);
    }
    final exit = this.exit;
    if (exit != null && t >= end - exit.length) {
      return exit.outgoing(progress(t, end - exit.length, end), stage);
    }
    return SceneEffect.none;
  }

  /// Whether a carried layer should ignore the exit at [t].
  bool leaving(Duration t) => exit != null && t >= end - exit!.length;
}

/// A whole video: its format and frame rate, what it sits on, its scenes and
/// the transitions between them, and its sound.
class Reel {
  /// A name, for file names.
  final String name;

  /// The frame.
  final Format format;

  /// Frames per second.
  final int fps;

  /// What every scene sits on, unless it has its own.
  final Backdrop backdrop;

  /// The scenes, in order.
  final List<Scene> scenes;

  /// The transition after each scene but the last. Shorter lists repeat
  /// their last entry; empty means cuts.
  final List<Transition> transitions;

  /// Music, voice-over and cue sounds.
  final Soundtrack soundtrack;

  /// Frames blended into each output frame, for motion blur. 1 is none.
  final int motionBlur;

  /// How fast it plays: 1.25 runs every timing a quarter faster (beats,
  /// moves, typing, words, transitions, the ground), so the video is shorter;
  /// 0.8 slower. Music and voice-over keep their own speed; cues and lines
  /// move with the moments they belong to.
  final double pace;

  /// A reel.
  Reel({
    required this.name,
    required this.backdrop,
    required this.scenes,
    this.format = Format.vertical,
    this.fps = 30,
    this.transitions = const [],
    this.soundtrack = const Soundtrack(),
    this.motionBlur = 1,
    this.pace = 1,
  }) : assert(pace > 0);

  /// This reel at [pace].
  Reel withPace(double pace) => Reel(
    name: name,
    backdrop: backdrop,
    scenes: scenes,
    format: format,
    fps: fps,
    transitions: transitions,
    soundtrack: soundtrack,
    motionBlur: motionBlur,
    pace: pace,
  );

  /// When a moment on the reel's clock comes in the video, at its [pace].
  Duration played(Duration reelTime) =>
      Duration(microseconds: (reelTime.inMicroseconds / pace).round());

  /// The moment on the reel's clock shown at [videoTime].
  Duration atVideo(Duration videoTime) =>
      Duration(microseconds: (videoTime.inMicroseconds * pace).round());

  /// How long the video runs, at its [pace].
  Duration get playedLength => played(length);

  /// A reel of one scene.
  factory Reel.single({
    required String name,
    required Duration length,
    required Backdrop backdrop,
    required Camera camera,
    Format format = Format.vertical,
    int fps = 30,
    List<Layer> layers = const [],
    List<Words> words = const [],
    List<Cue> cues = const [],
    Soundtrack soundtrack = const Soundtrack(),
  }) => Reel(
    name: name,
    backdrop: backdrop,
    format: format,
    fps: fps,
    soundtrack: soundtrack,
    scenes: [
      Scene(
        name: name,
        length: length,
        camera: camera,
        layers: layers,
        words: words,
        cues: cues,
      ),
    ],
  );

  /// Every scene's place in time.
  late final List<SceneSpan> timeline = _timeline();

  /// How long it runs.
  Duration get length => timeline.isEmpty ? Duration.zero : timeline.last.end;

  Transition _after(int i) {
    if (transitions.isEmpty) return Transition.cut;
    return transitions[math.min(i, transitions.length - 1)];
  }

  List<SceneSpan> _timeline() {
    final spans = <SceneSpan>[];
    var start = Duration.zero;
    for (var i = 0; i < scenes.length; i++) {
      final enter = i == 0 ? null : _after(i - 1);
      final exit = i == scenes.length - 1 ? null : _after(i);
      final end = start + scenes[i].length;
      spans.add(SceneSpan(scenes[i], i, start, end, enter: enter, exit: exit));
      start = end - (exit?.length ?? Duration.zero);
    }
    return spans;
  }

  /// Every sound, at its time on the reel: the scenes' own cues, and the
  /// ones taps, typing, words and transitions make.
  List<Cue> get cues {
    final out = <Cue>[];
    for (final span in timeline) {
      final s = span.scene;
      Duration abs(Duration local) => span.start + _onScreen(s, local);
      for (final c in s.cues) {
        out.add(c.copyAt(abs(c.at)));
      }
      for (final w in s.words) {
        if (w.sound != null) out.add(Cue(abs(w.at), w.sound!));
      }
      for (final layer in s.layers) {
        for (final tap in layer.taps) {
          if (tap.sound != null) out.add(Cue(abs(tap.at), tap.sound!));
        }
        for (final typing in layer.typing) {
          if (typing.sound == null) continue;
          for (var i = 0; i < typing.text.length; i++) {
            if (typing.text[i].trim().isEmpty) continue;
            out.add(
              Cue(
                abs(typing.at + typing.perCharacter * i),
                typing.sound!,
                gain: -8,
              ),
            );
          }
        }
      }
      final exit = span.exit;
      if (exit?.sound != null) {
        out.add(Cue(span.end - exit!.length, exit.sound!));
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// The time on screen, from a scene's start, at which the scene's own
  /// clock reads [local].
  static Duration _onScreen(Scene s, Duration local) {
    final warp = s.speed;
    if (warp == null) return local;
    var lo = Duration.zero;
    var hi = s.length * 4;
    for (var i = 0; i < 40; i++) {
      final mid = (lo + hi) ~/ 2;
      if (warp.map(mid) < local) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }
}
