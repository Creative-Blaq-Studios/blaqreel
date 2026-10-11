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

    test('Given a pose with focus, when away from it, then it blurs', () {
      const pose = CameraPose(focus: 100, aperture: 2);
      expect(pose.blurAt(100), 0);
      expect(pose.blurAt(0), 2);
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
          z: z,
        ),
        Offset.zero,
      );
      expect(corner(200).dx, lessThan(corner(0).dx));
    });
  });
}
