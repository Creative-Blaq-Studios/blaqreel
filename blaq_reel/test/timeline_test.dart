import 'package:blaq_reel/blaq_reel.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReelClock', () {
    test('Given 30 fps, when counting 5 s, then it is 150 frames', () {
      const clock = ReelClock(30);
      expect(clock.frames(5.s), 150);
      expect(clock.at(45), 1.5.s);
    });
  });

  group('Track', () {
    final track = Track([
      Keyframe(1.s, 0),
      Keyframe(3.s, 100, ease: Curves.linear),
    ]);

    test('Given keyframes, when before the first, then it holds it', () {
      expect(track.at(Duration.zero), 0);
    });

    test('Given a linear key, when halfway, then it is halfway', () {
      expect(track.at(2.s), 50);
    });

    test('Given keyframes, when after the last, then it holds it', () {
      expect(track.at(9.s), 100);
    });

    test('Given a chained track, when read, then each link holds', () {
      final chained = Track.from(
        0,
      ).to(1.s, 10, Ease.linear).hold(2.s).to(3.s, 0, Ease.linear);
      expect(chained.at(500.ms), 5);
      expect(chained.at(1500.ms), 10);
      expect(chained.at(2500.ms), 5);
      expect(chained.end, 3.s);
    });

    test('Given a shift, when read, then it is later by that much', () {
      expect(track.shift(1.s).at(3.s), 50);
    });
  });

  group('TimeWarp', () {
    test('Given speed 1, when mapped, then time is unchanged', () {
      final warp = TimeWarp(Track.constant(1));
      expect(warp.map(2.s).inMilliseconds, closeTo(2000, 2));
    });

    test('Given half speed, when mapped, then scene time is half', () {
      final warp = TimeWarp(Track.constant(0.5));
      expect(warp.map(2.s).inMilliseconds, closeTo(1000, 2));
    });

    test('Given slow motion in the middle, then only that stretch slows', () {
      final warp = TimeWarp(
        Track.from(1).hold(1.s).to(1.s, 0.25).hold(3.s).to(3.s, 1),
      );
      // 1 s at full speed, 2 s at a quarter, then 1 s at full speed.
      expect(warp.map(4.s).inMilliseconds, closeTo(2500, 6));
    });
  });

  group('Camera', () {
    final camera = Camera([
      const Shot(at: Duration.zero, tilt: 40, zoom: 0.5),
      const Shot(at: Duration(seconds: 2), ease: Curves.linear, tilt: 0),
    ]);

    test('Given a shot that leaves zoom out, then zoom holds', () {
      expect(camera.at(1.s).zoom, 0.5);
      expect(camera.at(1.s).tilt, 20);
    });

    test('Given tracks, when a property is left out, then it rests', () {
      final c = Camera.tracks(turn: Track.constant(12));
      expect(c.at(1.s).turn, 12);
      expect(c.at(1.s).zoom, 1);
    });

    test('Given a pose with focus, when away from it, then it blurs', () {
      const pose = CameraPose(focus: 100, aperture: 2);
      expect(pose.blurAt(100), 0);
      expect(pose.blurAt(0), 2);
    });

    test('Given a nudge, then angles add and zoom multiplies', () {
      final p = const CameraPose(turn: 5, zoom: 0.5).nudged(turn: 10, zoom: 2);
      expect(p.turn, 15);
      expect(p.zoom, 1);
    });

    test('Given no turn, when projecting, then the centre lands mid-stage', () {
      final m = camera.project(
        pose: const CameraPose(),
        stage: const Size(360, 640),
        size: const Size(100, 100),
      );
      final centre = MatrixUtils.transformPoint(m, const Offset(50, 50));
      expect(centre.dx, closeTo(180, 1e-6));
      expect(centre.dy, closeTo(320, 1e-6));
    });

    test('Given depth toward the camera, when projecting, then it grows', () {
      Offset corner(double z) => MatrixUtils.transformPoint(
        camera.project(
          pose: const CameraPose(),
          stage: const Size(360, 640),
          size: const Size(100, 100),
          motion: MotionPose(z: z),
        ),
        Offset.zero,
      );
      expect(corner(200).dx, lessThan(corner(0).dx));
    });
  });
}
