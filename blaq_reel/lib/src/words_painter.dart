import 'package:flutter/rendering.dart';
import 'package:flutter/animation.dart';

import 'layer.dart';
import 'time.dart';

/// Paints [Words] at a moment: every letter at its kerned place in the whole
/// word, risen as far as its own clock says, under a line it rises from.
class WordsPainter extends CustomPainter {
  /// The words.
  final Words words;

  /// The moment.
  final Duration t;

  /// A painter.
  WordsPainter(this.words, this.t);

  /// The laid-out words, unrisen: callers size the box from it.
  static TextPainter layout(Words words) => TextPainter(
    text: TextSpan(text: words.text, style: words.style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (t < words.at) return;
    final until = words.until;
    var leaving = 0.0;
    if (until != null) {
      leaving = progress(t, until, until + 400.ms, curve: Curves.easeInCubic);
      if (leaving >= 1) return;
    }

    final whole = layout(words);
    final height = whole.height;
    final start = words.highlight == null
        ? -1
        : words.text.indexOf(words.highlight!);
    final end = start < 0 ? -1 : start + words.highlight!.length;

    // The line the letters rise from: everything below it is hidden, so a
    // letter appears from nowhere rather than sliding in from the bottom.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(-height, -height, size.width + 2 * height, height * 2),
    );
    for (var i = 0; i < words.text.length; i++) {
      final begin = words.at + words.stagger * i;
      final p = progress(t, begin, begin + words.rise, curve: _rise);
      if (p <= 0) continue;
      final x = whole.getOffsetForCaret(TextPosition(offset: i), Rect.zero).dx;
      final accent = i >= start && i < end && words.accent != null;
      final base = words.style.color ?? const Color(0xFFFFFFFF);
      final color = accent ? words.accent! : base;
      final alpha = (p * 1.6).clamp(0.0, 1.0) * (1 - leaving);
      final glyph = TextPainter(
        text: TextSpan(
          text: words.text[i],
          style: words.style.copyWith(
            color: color.withValues(alpha: color.a * alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = (1 - p) * height * 0.9 - leaving * height * 0.3;
      glyph.paint(canvas, Offset(x, y));
    }
    canvas.restore();
  }

  /// Fast out, long settle: an expo ease-out.
  static const _rise = Cubic(0.16, 1, 0.3, 1);

  @override
  bool shouldRepaint(WordsPainter old) => old.t != t || old.words != words;
}
