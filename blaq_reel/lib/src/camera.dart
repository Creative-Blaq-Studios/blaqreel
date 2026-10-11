import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'time.dart';

/// Where the camera is at one moment. Any field left out holds the value the
/// shot before it had.
///
/// Angles are degrees. [tilt] leans the top of the world away from the
/// camera; [turn] swings its right side away; [roll] spins it clockwise.
/// [zoom] scales the world; [pan] moves it across the frame, in stage units.
/// [focus] is the depth that is sharp, and [aperture] how fast everything
/// else softens: blur sigma per 100 units of depth away from [focus]. [blur]
/// softens the whole world at once, for a focus pull.
class Shot {
  /// When the camera arrives here.
  final Duration at;

  /// How it travels from the shot before.
  final Curve ease;

  /// Lean, in degrees: positive takes the top away.
  final double? tilt;

  /// Swing, in degrees: positive takes the right side away.
  final double? turn;

  /// Spin, in degrees, clockwise.
  final double? roll;

  /// Scale of the world.
  final double? zoom;

  /// Offset of the world's centre from the stage's centre.
  final Offset? pan;

  /// The depth in focus.
  final double? focus;

  /// Blur sigma per 100 units of depth away from [focus].
  final double? aperture;

  /// Blur on the whole world.
  final double? blur;

  /// A camera keyframe.
  const Shot({
    required this.at,
    this.ease = Curves.easeInOutCubic,
    this.tilt,
    this.turn,
    this.roll,
    this.zoom,
    this.pan,
    this.focus,
    this.aperture,
    this.blur,
  });
}

/// The camera's state at one moment, every field filled in.
class CameraPose {
  /// See [Shot.tilt].
  final double tilt;

  /// See [Shot.turn].
  final double turn;

  /// See [Shot.roll].
  final double roll;

  /// See [Shot.zoom].
  final double zoom;

  /// See [Shot.pan].
  final Offset pan;

  /// See [Shot.focus].
  final double focus;

  /// See [Shot.aperture].
  final double aperture;

  /// See [Shot.blur].
  final double blur;

  /// A pose.
  const CameraPose({
    this.tilt = 0,
    this.turn = 0,
    this.roll = 0,
    this.zoom = 1,
    this.pan = Offset.zero,
    this.focus = 0,
    this.aperture = 0,
    this.blur = 0,
  });

  /// How soft a layer at depth [z] is from this pose.
  double blurAt(double z) => blur + aperture * (z - focus).abs() / 100;

  /// This pose moved by a transition: angles, pan and blur add, zoom
  /// multiplies.
  CameraPose nudged({
    double tilt = 0,
    double turn = 0,
    double roll = 0,
    double zoom = 1,
    Offset pan = Offset.zero,
    double blur = 0,
  }) => CameraPose(
    tilt: this.tilt + tilt,
    turn: this.turn + turn,
    roll: this.roll + roll,
    zoom: this.zoom * zoom,
    pan: this.pan + pan,
    focus: focus,
    aperture: aperture,
    blur: this.blur + blur,
  );
}

/// A camera: a pose for every moment, and a perspective [distance] — how far
/// the eye is from depth 0, in stage units. Shorter is more dramatic.
///
/// Write one from [Shot]s, which ease every property together, or from a
/// [Track] per property with [Camera.tracks] when they need their own
/// timing.
class Camera {
  /// The eye's distance from depth 0.
  final double distance;

  final CameraPose Function(Duration t) _at;

  /// A camera through [shots], in time order.
  factory Camera(List<Shot> shots, {double distance = 1100}) {
    final poses = _resolve(shots);
    return Camera._(distance, (t) {
      if (poses.isEmpty) return const CameraPose();
      if (t <= shots.first.at) return poses.first;
      for (var i = 1; i < shots.length; i++) {
        if (t <= shots[i].at) {
          final p = progress(t, shots[i - 1].at, shots[i].at);
          return _lerp(poses[i - 1], poses[i], shots[i].ease.transform(p));
        }
      }
      return poses.last;
    });
  }

  /// A camera with a track for each property; any left out stays at rest.
  factory Camera.tracks({
    Track? tilt,
    Track? turn,
    Track? roll,
    Track? zoom,
    Track? panX,
    Track? panY,
    Track? focus,
    Track? aperture,
    Track? blur,
    double distance = 1100,
  }) => Camera._(
    distance,
    (t) => CameraPose(
      tilt: tilt?.at(t) ?? 0,
      turn: turn?.at(t) ?? 0,
      roll: roll?.at(t) ?? 0,
      zoom: zoom?.at(t) ?? 1,
      pan: Offset(panX?.at(t) ?? 0, panY?.at(t) ?? 0),
      focus: focus?.at(t) ?? 0,
      aperture: aperture?.at(t) ?? 0,
      blur: blur?.at(t) ?? 0,
    ),
  );

  /// A camera that never moves.
  factory Camera.still(CameraPose pose, {double distance = 1100}) =>
      Camera._(distance, (_) => pose);

  Camera._(this.distance, this._at);

  /// The pose at [t].
  CameraPose at(Duration t) => _at(t);

  static List<CameraPose> _resolve(List<Shot> shots) {
    var pose = const CameraPose();
    return [
      for (final s in shots)
        pose = CameraPose(
          tilt: s.tilt ?? pose.tilt,
          turn: s.turn ?? pose.turn,
          roll: s.roll ?? pose.roll,
          zoom: s.zoom ?? pose.zoom,
          pan: s.pan ?? pose.pan,
          focus: s.focus ?? pose.focus,
          aperture: s.aperture ?? pose.aperture,
          blur: s.blur ?? pose.blur,
        ),
    ];
  }

  static double _l(double a, double b, double p) => a + (b - a) * p;

  static CameraPose _lerp(CameraPose a, CameraPose b, double p) => CameraPose(
    tilt: _l(a.tilt, b.tilt, p),
    turn: _l(a.turn, b.turn, p),
    roll: _l(a.roll, b.roll, p),
    zoom: _l(a.zoom, b.zoom, p),
    pan: Offset.lerp(a.pan, b.pan, p)!,
    focus: _l(a.focus, b.focus, p),
    aperture: _l(a.aperture, b.aperture, p),
    blur: _l(a.blur, b.blur, p),
  );

  /// The matrix that draws a box of [size] onto a stage of [stage] size:
  /// the box centred at [position] in the world, moved and turned by its
  /// own [motion], and seen through [pose].
  Matrix4 project({
    required CameraPose pose,
    required Size stage,
    required Size size,
    Offset position = Offset.zero,
    MotionPose motion = const MotionPose(),
  }) {
    const rad = math.pi / 180;
    // Flutter's z points into the screen, so toward the camera is negative,
    // and a perspective entry of 1/distance makes nearer things bigger.
    final perspective = Matrix4.identity()..setEntry(3, 2, 1 / distance);
    final m =
        Matrix4.translationValues(
            stage.width / 2 + pose.pan.dx,
            stage.height / 2 + pose.pan.dy,
            0,
          )
          ..multiply(perspective)
          ..multiply(Matrix4.rotationX(-pose.tilt * rad))
          ..multiply(Matrix4.rotationY(pose.turn * rad))
          ..multiply(Matrix4.rotationZ(pose.roll * rad))
          ..multiply(Matrix4.diagonal3Values(pose.zoom, pose.zoom, pose.zoom))
          ..multiply(
            Matrix4.translationValues(
              position.dx + motion.x,
              position.dy + motion.y,
              -motion.z,
            ),
          );
    if (motion.rotates) {
      m
        ..multiply(Matrix4.rotationX(-motion.tilt * rad))
        ..multiply(Matrix4.rotationY(motion.turn * rad))
        ..multiply(Matrix4.rotationZ(motion.roll * rad));
    }
    if (motion.scale != 1) {
      m.multiply(Matrix4.diagonal3Values(motion.scale, motion.scale, 1));
    }
    return m..multiply(
      Matrix4.translationValues(-size.width / 2, -size.height / 2, 0),
    );
  }
}
