import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'time.dart';

/// A soft light on the backdrop that drifts slowly.
class Glow {
  /// Its colour at the centre.
  final Color color;

  /// Where its centre rests.
  final Alignment center;

  /// Its radius, as a fraction of the stage's longer side.
  final double radius;

  /// How far it wanders from [center], in alignment units.
  final Offset drift;

  /// Seconds per wander.
  final double period;

  /// Its strength over time, 0 to 1.
  final Track? strength;

  /// A glow.
  const Glow(
    this.color, {
    this.center = Alignment.center,
    this.radius = 0.6,
    this.drift = const Offset(0.08, 0.05),
    this.period = 9,
    this.strength,
  });
}

/// What the world sits on: a vertical gradient from [top] to [bottom], glows
/// over it, and a vignette at the edges.
class Backdrop {
  /// The colour at the top.
  final Color top;

  /// The colour at the bottom.
  final Color bottom;

  /// Soft lights, drawn in order.
  final List<Glow> glows;

  /// How dark the corners go, 0 to 1.
  final double vignette;

  /// A floor the wall curves into, in this colour: a photo studio's sweep.
  final Color? floor;

  /// A backdrop.
  const Backdrop({
    required this.top,
    required this.bottom,
    this.glows = const [],
    this.vignette = 0.35,
    this.floor,
  });

  /// A plain [base] with one [glow] of light behind the middle.
  factory Backdrop.glow(Color base, Color glow, {double strength = 0.35}) =>
      Backdrop(
        top: base,
        bottom: Color.lerp(base, const Color(0xFF000000), 0.35)!,
        glows: [
          Glow(
            glow.withValues(alpha: strength),
            center: const Alignment(0.1, -0.2),
            radius: 0.65,
          ),
        ],
      );
}

/// Slow coloured blobs drifting over [base]: the Kinetic Launch look on a
/// light ground, or the Dark Glow look on a dark one.
Backdrop blobs(Color base, List<Color> colors, {double strength = 0.45}) {
  const spots = [
    Alignment(-0.7, -0.6),
    Alignment(0.75, -0.2),
    Alignment(-0.4, 0.7),
    Alignment(0.6, 0.8),
  ];
  return Backdrop(
    top: base,
    bottom: Color.lerp(base, const Color(0xFF000000), 0.12)!,
    vignette: 0.15,
    glows: [
      for (var i = 0; i < colors.length; i++)
        Glow(
          colors[i].withValues(alpha: strength),
          center: spots[i % spots.length],
          radius: 0.55,
          drift: const Offset(0.15, 0.1),
          period: 7.0 + i * 2.3,
        ),
    ],
  );
}

/// Paints a [Backdrop] at a moment.
class BackdropPainter extends CustomPainter {
  /// The backdrop.
  final Backdrop backdrop;

  /// The moment.
  final Duration t;

  /// A painter.
  const BackdropPainter(this.backdrop, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backdrop.top, backdrop.bottom],
        ).createShader(rect),
    );

    final floor = backdrop.floor;
    if (floor != null) {
      // The wall meets the floor in a soft curve two-thirds of the way down.
      final horizon = size.height * 0.6;
      canvas.drawRect(
        Rect.fromLTRB(0, horizon - size.height * 0.12, size.width, size.height),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [floor.withValues(alpha: 0), floor, floor],
                stops: const [0, 0.35, 1],
              ).createShader(
                Rect.fromLTRB(
                  0,
                  horizon - size.height * 0.12,
                  size.width,
                  size.height,
                ),
              ),
      );
    }

    final seconds = secondsOf(t);
    final longest = math.max(size.width, size.height);
    for (final glow in backdrop.glows) {
      final phase = 2 * math.pi * seconds / glow.period;
      final c = Alignment(
        glow.center.x + glow.drift.dx * math.sin(phase),
        glow.center.y + glow.drift.dy * math.cos(phase * 0.8),
      ).withinRect(rect);
      final strength = glow.strength?.at(t) ?? 1;
      final r = glow.radius * longest;
      final color = glow.color.withValues(alpha: glow.color.a * strength);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    if (backdrop.vignette > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            radius: 0.9,
            colors: [
              const Color(0x00000000),
              Color.fromRGBO(0, 0, 0, backdrop.vignette),
            ],
            stops: const [0.55, 1],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(BackdropPainter old) =>
      old.t != t || old.backdrop != backdrop;
}
