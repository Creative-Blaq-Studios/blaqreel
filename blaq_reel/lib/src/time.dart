import 'package:flutter/animation.dart';

/// Seconds and milliseconds as durations: `1.5.s`, `250.ms`.
extension ReelSeconds on num {
  /// This many seconds.
  Duration get s => Duration(microseconds: (this * 1e6).round());

  /// This many milliseconds.
  Duration get ms => Duration(microseconds: (this * 1e3).round());
}

/// Seconds in [d], as a double.
double secondsOf(Duration d) => d.inMicroseconds / 1e6;

/// The fixed clock a reel is drawn on: frame `n` is at `n / fps` seconds,
/// whatever the machine's speed. Nothing runs in real time.
class ReelClock {
  /// Frames per second.
  final int fps;

  /// A clock ticking [fps] times a second.
  const ReelClock(this.fps);

  /// One frame's length.
  Duration get frame => Duration(microseconds: (1e6 / fps).round());

  /// How many frames [length] takes, rounded to the nearest frame.
  int frames(Duration length) => (secondsOf(length) * fps).round();

  /// The time frame [n] is drawn at.
  Duration at(int n) => Duration(microseconds: (n * 1e6 / fps).round());
}

/// Eases that read well on screen, by the names motion designers use.
abstract final class Ease {
  /// Fast away, long settle: most arrivals.
  static const Curve out = Cubic(0.16, 1, 0.3, 1);

  /// Under way at once, then a long settle; slower to land than [out].
  static const Curve arrive = Cubic(0.3, 0.1, 0.1, 1);

  /// Slow in, slow out: camera moves between two rests.
  static const Curve inOut = Curves.easeInOutCubic;

  /// Gathers speed and leaves: exits.
  static const Curve leave = Cubic(0.7, 0, 0.84, 0);

  /// A constant drift.
  static const Curve linear = Curves.linear;

  /// A gentle drift that slows to a stop.
  static const Curve drift = Curves.easeOutSine;

  /// Past the mark and back: something popping into place.
  static const Curve pop = Cubic(0.34, 1.56, 0.64, 1);
}

/// A value at a moment, reached from the keyframe before it along [ease].
class Keyframe {
  /// When the value is reached.
  final Duration at;

  /// The value.
  final double value;

  /// The curve from the previous keyframe into this one.
  final Curve ease;

  /// A keyframe.
  const Keyframe(this.at, this.value, {this.ease = Curves.easeInOutCubic});
}

/// A number that changes over time: held before the first keyframe and after
/// the last, eased between them.
///
/// Write one from keyframes, or chain one:
/// `Track.from(0).to(1.s, 100, Ease.out).hold(2.s).to(3.s, 0)`.
class Track {
  /// The keyframes, in time order.
  final List<Keyframe> keys;

  /// A track through [keys], which must be in time order.
  const Track(this.keys);

  /// A track that never moves.
  Track.constant(double value) : keys = [Keyframe(Duration.zero, value)];

  /// A track that starts at [value] at time zero, to chain from.
  Track.from(double value, {Duration at = Duration.zero})
    : keys = [Keyframe(at, value)];

  /// This track, then a move to [value] arriving at [at] along [ease].
  Track to(Duration at, double value, [Curve ease = Curves.easeInOutCubic]) =>
      Track([...keys, Keyframe(at, value, ease: ease)]);

  /// This track, holding its last value until [until].
  Track hold(Duration until) =>
      Track([...keys, Keyframe(until, keys.last.value, ease: Curves.linear)]);

  /// The same track, [by] later.
  Track shift(Duration by) =>
      Track([for (final k in keys) Keyframe(k.at + by, k.value, ease: k.ease)]);

  /// The value at [t].
  double at(Duration t) {
    if (keys.isEmpty) return 0;
    if (t <= keys.first.at) return keys.first.value;
    for (var i = 1; i < keys.length; i++) {
      final b = keys[i];
      if (t <= b.at) {
        final a = keys[i - 1];
        final span = (b.at - a.at).inMicroseconds;
        if (span <= 0) return b.value;
        final p = (t - a.at).inMicroseconds / span;
        return a.value + (b.value - a.value) * b.ease.transform(p);
      }
    }
    return keys.last.value;
  }

  /// The time of the last keyframe.
  Duration get end => keys.isEmpty ? Duration.zero : keys.last.at;
}

/// How far through the window from [start] to [end] the time [t] is, 0 to 1,
/// eased along [curve].
double progress(
  Duration t,
  Duration start,
  Duration end, {
  Curve curve = Curves.linear,
}) {
  final span = (end - start).inMicroseconds;
  if (span <= 0) return t >= end ? 1 : 0;
  final p = ((t - start).inMicroseconds / span).clamp(0.0, 1.0);
  return curve.transform(p);
}

/// Playback speed over a scene's own time: 1 is real time, 0.4 is slow
/// motion, 2 is double speed. Maps time on screen to time in the scene.
///
/// Slow motion costs nothing extra to draw well: every frame is drawn in
/// full, so a scene at 0.25 has four times the frames for the same motion.
class TimeWarp {
  /// Speed over time on screen.
  final Track speed;

  /// The step the warp is integrated at.
  static const _step = Duration(milliseconds: 2);

  final List<Duration> _table = [Duration.zero];

  /// A warp following [speed].
  TimeWarp(this.speed);

  /// Scene time at [t] seconds on screen.
  Duration map(Duration t) {
    if (t <= Duration.zero) return Duration.zero;
    final n = t.inMicroseconds ~/ _step.inMicroseconds;
    while (_table.length <= n + 1) {
      final i = _table.length;
      final mid = _step * (i - 1) + _step ~/ 2;
      _table.add(
        _table.last +
            Duration(
              microseconds: (speed.at(mid) * _step.inMicroseconds).round(),
            ),
      );
    }
    final rest = t - _step * n;
    final p = rest.inMicroseconds / _step.inMicroseconds;
    final a = _table[n];
    final b = _table[n + 1];
    return a + Duration(microseconds: ((b - a).inMicroseconds * p).round());
  }
}
