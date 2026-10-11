import 'time.dart';

/// Where something sits in the world over time, relative to where it was
/// placed: across ([x], [y]), toward the camera ([z]), its own lean ([tilt]),
/// swing ([turn]) and spin ([roll]) in degrees, its [scale], [opacity], and
/// any [blur] on top of what the camera's focus gives it.
class Motion {
  /// Across, in world units.
  final Track x;

  /// Down, in world units.
  final Track y;

  /// Toward the camera, in world units.
  final Track z;

  /// Lean, in degrees: positive takes the top away.
  final Track tilt;

  /// Swing, in degrees: positive takes the right side away.
  final Track turn;

  /// Spin, in degrees, clockwise.
  final Track roll;

  /// Scale around its centre.
  final Track scale;

  /// Opacity.
  final Track opacity;

  /// Extra blur sigma.
  final Track blur;

  /// A motion. Anything left out stays at rest.
  Motion({
    Track? x,
    Track? y,
    Track? z,
    Track? tilt,
    Track? turn,
    Track? roll,
    Track? scale,
    Track? opacity,
    Track? blur,
  }) : x = x ?? Track.constant(0),
       y = y ?? Track.constant(0),
       z = z ?? Track.constant(0),
       tilt = tilt ?? Track.constant(0),
       turn = turn ?? Track.constant(0),
       roll = roll ?? Track.constant(0),
       scale = scale ?? Track.constant(1),
       opacity = opacity ?? Track.constant(1),
       blur = blur ?? Track.constant(0);

  /// The pose at [t].
  MotionPose at(Duration t) => MotionPose(
    x: x.at(t),
    y: y.at(t),
    z: z.at(t),
    tilt: tilt.at(t),
    turn: turn.at(t),
    roll: roll.at(t),
    scale: scale.at(t),
    opacity: opacity.at(t),
    blur: blur.at(t),
  );
}

/// A [Motion] at one moment.
class MotionPose {
  /// See [Motion.x].
  final double x;

  /// See [Motion.y].
  final double y;

  /// See [Motion.z].
  final double z;

  /// See [Motion.tilt].
  final double tilt;

  /// See [Motion.turn].
  final double turn;

  /// See [Motion.roll].
  final double roll;

  /// See [Motion.scale].
  final double scale;

  /// See [Motion.opacity].
  final double opacity;

  /// See [Motion.blur].
  final double blur;

  /// A pose.
  const MotionPose({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.tilt = 0,
    this.turn = 0,
    this.roll = 0,
    this.scale = 1,
    this.opacity = 1,
    this.blur = 0,
  });

  /// Whether it turns or leans at all.
  bool get rotates => tilt != 0 || turn != 0 || roll != 0;
}
