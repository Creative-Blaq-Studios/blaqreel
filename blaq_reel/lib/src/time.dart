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
class Track {
  /// The keyframes, in time order.
  final List<Keyframe> keys;

  /// A track through [keys], which must be in time order.
  const Track(this.keys);

  /// A track that never moves.
  Track.constant(double value) : keys = [Keyframe(Duration.zero, value)];

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
