import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// How a ground moves: one of ten patterns, drawn over the backdrop's
/// gradient in place of its glows. The studio's editor draws the same ten
/// the same way (`cli/animator_page.dart`), so keep the two in step.
enum GroundPattern {
  /// Soft fields of colour wandering slowly.
  drift,

  /// Wide bands of light sweeping across.
  aurora,

  /// The glows swell and settle.
  breathe,

  /// Three glows circling the middle, each at its own pace.
  orbit,

  /// A band of light crossing every few seconds.
  sweep,

  /// Soft discs rising in depth.
  bokeh,

  /// A floor of lines in perspective, flowing toward the eye.
  grid,

  /// Four colours melting into each other, their centres moving.
  mesh,

  /// Silk ribbons waving through the frame.
  ribbons,

  /// Beams fanning down from above, turning slowly.
  rays,
}

/// A ground's motion: its [pattern], the three [colours] that move, how
/// fast, and a pulse on the beat.
class GroundMotion {
  /// The pattern.
  final GroundPattern pattern;

  /// What moves: three colours.
  final List<Color> colours;

  /// How fast: 1 is the pattern's own pace.
  final double speed;

  /// Picks the bokeh's discs.
  final int seed;

  /// A soft pulse of the first colour on every beat, at this tempo; null
  /// for none.
  final double? bpm;

  /// Whether the ground is light, which some patterns draw differently.
  final bool light;

  /// Film grain over the whole reel, 0 to 1; read from the reel's own
  /// ground only.
  final double grain;

  /// A motion.
  const GroundMotion({
    required this.pattern,
    required this.colours,
    this.speed = 1,
    this.seed = 7,
    this.bpm,
    this.light = true,
    this.grain = 0,
  });
}

/// Draws [m] at [seconds] (already scaled by its speed) over a ground of
/// [size] whose gradient runs [top] to [bottom].
void paintGround(
  Canvas canvas,
  Size size,
  double seconds,
  GroundMotion m,
  Color top,
  Color bottom,
) {
  final w = size.width, h = size.height, big = math.max(w, h);
  final rect = Offset.zero & size;
  final c = [for (var i = 0; i < 3; i++) m.colours[i % m.colours.length]];
  final light = m.light, t = seconds;
  // A blur as the editor's canvas `blur(px)` draws it, on a 360-wide frame.
  double sigma(double px) => px * w / 360;

  void glow(double x, double y, double r, Color col, double a) {
    final o = Offset(x, y);
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(o, r, [
          col.withValues(alpha: a),
          col.withValues(alpha: 0),
        ]),
    );
  }

  void blurred(double px, void Function() draw, [BlendMode? mode]) {
    final s = sigma(px);
    canvas.saveLayer(
      rect,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: s,
          sigmaY: s,
          tileMode: TileMode.decal,
        )
        ..blendMode = mode ?? BlendMode.srcOver,
    );
    draw();
    canvas.restore();
  }

  void base(Color a, Color b) => canvas.drawRect(
    rect,
    Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [a, b]),
  );

  switch (m.pattern) {
    case GroundPattern.drift:
      const spots = [(0.25, 0.25, 0.62), (0.9, 0.5, 0.5), (0.3, 0.92, 0.55)];
      for (var i = 0; i < 3; i++) {
        final (x, y, r) = spots[i];
        glow(
          w * (x + 0.12 * math.sin(t * 0.31 + i * 2)),
          h * (y + 0.08 * math.cos(t * 0.27 + i)),
          r * big,
          c[i],
          light ? 0.75 : 0.42,
        );
      }
    case GroundPattern.aurora:
      blurred(34, () {
        for (var i = 0; i < 3; i++) {
          final y0 = h * (0.25 + 0.22 * i), amp = h * 0.08;
          final path = Path()..moveTo(-w * 0.2, y0);
          for (var x = -0.2; x <= 1.2001; x += 0.05) {
            path.lineTo(
              w * x,
              y0 +
                  amp * math.sin(x * 4 + t * 0.6 + i * 1.7) +
                  amp * 0.5 * math.sin(x * 9 - t * 0.9),
            );
          }
          path
            ..lineTo(w * 1.2, y0 + h * 0.18)
            ..lineTo(-w * 0.2, y0 + h * 0.18)
            ..close();
          canvas.drawPath(
            path,
            Paint()..color = c[i].withValues(alpha: light ? 0.35 : 0.5),
          );
        }
      }, light ? BlendMode.multiply : BlendMode.screen);
    case GroundPattern.breathe:
      final k = 0.5 + 0.5 * math.sin(t * 1.1);
      glow(
        w * 0.5,
        h * 0.42,
        big * (0.32 + 0.16 * k),
        c[0],
        (light ? 0.55 : 0.35) + 0.3 * k,
      );
      glow(
        w * 0.15,
        h * 0.85,
        big * (0.3 + 0.08 * (1 - k)),
        c[2],
        light ? 0.45 : 0.3,
      );
    case GroundPattern.orbit:
      const rings = [(0.42, 0.5, 0.0), (0.33, -0.7, 1.5), (0.25, 0.9, 3.0)];
      for (var i = 0; i < 3; i++) {
        final (r, sp, ph) = rings[i];
        glow(
          w * 0.55 + math.cos(t * sp + ph) * w * r * 1.1,
          h * 0.45 + math.sin(t * sp + ph) * h * r * 0.7,
          big * 0.32,
          c[i],
          light ? 0.7 : 0.45,
        );
      }
    case GroundPattern.sweep:
      const white = Color(0xFFFFFFFF);
      glow(
        w * 0.5,
        -h * 0.05,
        big * 0.6,
        light ? white : c[0],
        light ? 0.7 : 0.25,
      );
      final u = ((t * 0.28) % 1.6) - 0.3;
      canvas
        ..save()
        ..translate(w * u, 0)
        ..rotate(-0.35);
      final band = Rect.fromLTWH(-w * 0.18, -h, w * 0.36, h * 3);
      canvas
        ..drawRect(
          band,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(-w * 0.18, 0),
              Offset(w * 0.18, 0),
              [
                white.withValues(alpha: 0),
                (light ? white : c[0]).withValues(alpha: light ? 0.55 : 0.22),
                white.withValues(alpha: 0),
              ],
              const [0, 0.5, 1],
            ),
        )
        ..restore();
    case GroundPattern.bokeh:
      final r = _Lcg(m.seed);
      for (var i = 0; i < 22; i++) {
        final z = r.next(), x = r.next(), sp = 0.02 + z * 0.06;
        final y = ((r.next() - t * sp) % 1 + 1) % 1;
        final blur = 2 + (1 - (z - 0.5).abs() * 2) * 8;
        canvas.drawCircle(
          Offset(w * (x + 0.02 * math.sin(t + i)), h * (y * 1.2 - 0.1)),
          (6 + z * 30) * w / 360,
          Paint()
            ..color = c[i % 3].withValues(alpha: light ? 0.35 : 0.3 + z * 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma(blur)),
        );
      }
    case GroundPattern.grid:
      if (light) {
        base(
          Color.lerp(top, const Color(0xFF000000), 0.88)!,
          Color.lerp(bottom, const Color(0xFF000000), 0.92)!,
        );
      }
      final hz = h * 0.58, vx = w * 0.5;
      glow(vx, hz, big * 0.45, c[0], 0.35);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, w / 360);
      for (var i = 0; i < 14; i++) {
        final d = (i + (t * 0.6) % 1) / 14;
        final y = hz + (h - hz) * d * d;
        line.color = c[0].withValues(alpha: 0.55 * d);
        canvas.drawLine(Offset(0, y), Offset(w, y), line);
      }
      line.color = c[0].withValues(alpha: 0.55 * 0.6);
      for (var i = -10; i <= 10; i++) {
        canvas.drawLine(Offset(vx, hz), Offset(vx + i * w * 0.18, h), line);
      }
    case GroundPattern.mesh:
      const cw = 18, ch = 32;
      final pts =
          [
            (0.2, 0.2, c[0]),
            (0.85, 0.3, c[1]),
            (0.3, 0.85, c[2]),
            (0.8, 0.85, light ? top : bottom),
          ].indexed.map((e) {
            final (i, (x, y, col)) = e;
            return (
              x + 0.18 * math.sin(t * 0.4 + i * 1.9),
              y + 0.14 * math.cos(t * 0.33 + i * 1.3),
              col,
            );
          }).toList();
      blurred(12, () {
        final cell = Size(w * 1.1 / cw, h * 1.1 / ch);
        for (var y = 0; y < ch; y++) {
          for (var x = 0; x < cw; x++) {
            var sw = 0.0, r = 0.0, g = 0.0, b = 0.0;
            for (final (px, py, col) in pts) {
              final d =
                  math.sqrt(
                    math.pow(x / cw - px, 2) + math.pow((y / ch - py) * 1.6, 2),
                  ) +
                  0.02;
              final k = 1 / (d * d * d);
              sw += k;
              r += col.r * k;
              g += col.g * k;
              b += col.b * k;
            }
            canvas.drawRect(
              Rect.fromLTWH(
                -w * 0.05 + x * cell.width,
                -h * 0.05 + y * cell.height,
                cell.width + 1,
                cell.height + 1,
              ),
              Paint()
                ..color = Color.from(
                  alpha: 1,
                  red: r / sw,
                  green: g / sw,
                  blue: b / sw,
                ),
            );
          }
        }
      });
    case GroundPattern.ribbons:
      blurred(6, () {
        for (var i = 0; i < 4; i++) {
          final y0 = h * (0.2 + 0.2 * i), th = h * 0.05;
          final path = Path();
          for (var x = 0.0; x <= 1.0001; x += 0.04) {
            final y = y0 + h * 0.07 * math.sin(x * 5 + t * 0.7 + i);
            x == 0 ? path.moveTo(w * x, y) : path.lineTo(w * x, y);
          }
          for (var x = 1.0; x >= -0.0001; x -= 0.04) {
            path.lineTo(
              w * x,
              y0 + th + h * 0.07 * math.sin(x * 5 + t * 0.7 + i + 0.6),
            );
          }
          path.close();
          canvas.drawPath(
            path,
            Paint()..color = c[i % 3].withValues(alpha: light ? 0.45 : 0.35),
          );
        }
      });
    case GroundPattern.rays:
      blurred(10, () {
        canvas
          ..save()
          ..translate(w * 0.5, -h * 0.08);
        for (var i = 0; i < 7; i++) {
          final a = -0.9 + i * 0.3 + 0.12 * math.sin(t * 0.5 + i);
          final col = c[i % 3];
          canvas
            ..save()
            ..rotate(a);
          final beam = Path()
            ..moveTo(-w * 0.02, 0)
            ..lineTo(w * 0.02, 0)
            ..lineTo(w * 0.12, h * 1.3)
            ..lineTo(-w * 0.12, h * 1.3)
            ..close();
          canvas
            ..drawPath(
              beam,
              Paint()
                ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * 1.2), [
                  (light ? const Color(0xFFFFFFFF) : col).withValues(
                    alpha: light ? 0.6 : 0.35,
                  ),
                  col.withValues(alpha: 0),
                ]),
            )
            ..restore();
        }
        canvas.restore();
      });
  }
}

/// The editor's random numbers (`rng` in the page), so a seed picks the same
/// bokeh in both.
class _Lcg {
  int _s;
  _Lcg(int seed) : _s = seed & 0xFFFFFFFF;
  double next() {
    _s = (_s * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _s / 4294967296;
  }
}
