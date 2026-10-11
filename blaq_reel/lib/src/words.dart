import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'time.dart';

/// How [Words] arrive.
enum Reveal {
  /// Letter by letter, each rising into place from under its line.
  letters,

  /// Word by word, each rising into place.
  words,

  /// Typed, a character at a time, behind a caret.
  typewriter,

  /// All at once, fading up from a little below.
  fade,
}

/// Words drawn flat over the world, arriving and leaving on their own clock.
///
/// Put the part to colour in braces — `'Split the {cart} bill'` — or name it
/// with [highlight]; it takes [accent], and with [marker] a band of
/// [markerColor] sweeps in behind it once it has landed.
class Words {
  /// The words, with any accented part in braces.
  final String text;

  /// When they start to arrive.
  final Duration at;

  /// When they leave, or null to stay.
  final Duration? until;

  /// Their style.
  final TextStyle style;

  /// A part to accent, besides any in braces.
  final String? highlight;

  /// The accent colour.
  final Color? accent;

  /// Draws a band behind the accented part once it lands.
  final bool marker;

  /// The band's colour; the accent at a third by default.
  final Color? markerColor;

  /// Where they sit inside the format's safe area.
  final Alignment align;

  /// How the lines line up with each other.
  final TextAlign textAlign;

  /// The widest they get, as a fraction of the safe area's width.
  final double maxWidth;

  /// How they arrive.
  final Reveal reveal;

  /// Time between letters, or words.
  final Duration stagger;

  /// Time each letter or word takes to land.
  final Duration rise;

  /// A sound cue as they start to arrive, or null for none.
  final String? sound;

  /// Keeps them on one line: the type shrinks until they fit the width.
  final bool fit;

  /// Moved from where [align] puts it, as fractions of the frame: `0.1`
  /// across is a tenth of the frame's width.
  final Offset offset;

  /// A backing plate behind the words, so they read over whatever is
  /// behind them; null draws none.
  final Color? plate;

  /// Blurs what is behind the plate, as frosted glass, by this sigma.
  final double plateBlur;

  /// Drawn behind the scene's layers (the phone, its parts) rather than in
  /// front of them.
  final bool behind;

  /// Words.
  const Words(
    this.text, {
    required this.at,
    required this.style,
    this.until,
    this.highlight,
    this.accent,
    this.marker = false,
    this.markerColor,
    this.align = Alignment.bottomLeft,
    this.textAlign = TextAlign.left,
    this.maxWidth = 1,
    this.reveal = Reveal.letters,
    this.stagger = const Duration(milliseconds: 55),
    this.rise = const Duration(milliseconds: 700),
    this.sound,
    this.fit = false,
    this.offset = Offset.zero,
    this.plate,
    this.plateBlur = 0,
    this.behind = false,
  });

  /// These words sized for a line of [maxWidth]: with [fit], shrunk to
  /// sit on one line; otherwise shrunk only if a single word is longer than
  /// a line, so that no word is ever broken in two.
  Words fitted(double maxWidth) {
    double widthOf(String text) => (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout()).width;
    final widest = fit
        ? widthOf(plain)
        : plain.split(RegExp(r'\s+')).map(widthOf).fold(0.0, math.max);
    if (widest <= maxWidth) return this;
    final size = (style.fontSize ?? 14) * maxWidth / widest * 0.98;
    return Words(
      text,
      at: at,
      style: style.copyWith(
        fontSize: size,
        letterSpacing: style.letterSpacing == null
            ? null
            : style.letterSpacing! * size / (style.fontSize ?? 14),
      ),
      until: until,
      highlight: highlight,
      accent: accent,
      marker: marker,
      markerColor: markerColor,
      align: align,
      textAlign: textAlign,
      maxWidth: this.maxWidth,
      reveal: reveal,
      stagger: stagger,
      rise: rise,
      sound: sound,
      offset: offset,
      plate: plate,
      plateBlur: plateBlur,
      behind: behind,
    );
  }

  /// The text with the braces taken out.
  String get plain => text.replaceAll('{', '').replaceAll('}', '');

  /// The accented ranges of [plain].
  List<(int, int)> get accents {
    final ranges = <(int, int)>[];
    var removed = 0;
    for (final m in RegExp(r'\{([^}]*)\}').allMatches(text)) {
      final start = m.start - removed;
      ranges.add((start, start + m.group(1)!.length));
      removed += 2;
    }
    final h = highlight;
    if (h != null && h.isNotEmpty) {
      final i = plain.indexOf(h);
      if (i >= 0) ranges.add((i, i + h.length));
    }
    return ranges;
  }

  /// When the last of them has landed.
  Duration get landed {
    final p = plain;
    final steps = switch (reveal) {
      Reveal.letters || Reveal.typewriter => p.length - 1,
      Reveal.words => p.split(RegExp(r'\s+')).length - 1,
      Reveal.fade => 0,
    };
    return at + stagger * math.max(steps, 0) + rise;
  }
}

/// Paints [Words] at a moment.
class WordsPainter extends CustomPainter {
  /// The words.
  final Words words;

  /// The moment.
  final Duration t;

  /// The widest they may be.
  final double maxWidth;

  /// A painter.
  WordsPainter(this.words, this.t, {required this.maxWidth});

  /// The laid-out words, unrisen: callers size the box from it.
  static TextPainter layout(Words words, double maxWidth) => TextPainter(
    text: TextSpan(text: words.plain, style: words.style),
    textDirection: TextDirection.ltr,
    textAlign: words.textAlign,
  )..layout(maxWidth: maxWidth);

  static const Curve _rise = Ease.out;

  @override
  void paint(Canvas canvas, Size size) {
    if (t < words.at) return;
    final until = words.until;
    var leaving = 0.0;
    if (until != null) {
      leaving = progress(t, until, until + 450.ms, curve: Ease.leave);
      if (leaving >= 1) return;
    }

    final plain = words.plain;
    final whole = layout(words, maxWidth);
    final accents = words.accents;
    bool accented(int i) => accents.any((r) => i >= r.$1 && i < r.$2);
    final base = words.style.color ?? const Color(0xFFFFFFFF);
    final wordIndex = _wordIndexes(plain);

    if (words.marker && words.accent != null) {
      _paintMarker(canvas, whole, accents, leaving);
    }

    var lastX = 0.0;
    var lastY = 0.0;
    var lastH = 0.0;
    var shown = 0;
    for (var i = 0; i < plain.length; i++) {
      final ch = plain[i];
      final start = switch (words.reveal) {
        Reveal.letters || Reveal.typewriter => words.at + words.stagger * i,
        Reveal.words => words.at + words.stagger * wordIndex[i],
        Reveal.fade => words.at,
      };
      var p = switch (words.reveal) {
        Reveal.typewriter => t >= start ? 1.0 : 0.0,
        _ => progress(t, start, start + words.rise, curve: _rise),
      };
      if (p <= 0) continue;
      shown = i + 1;
      final caret = whole.getOffsetForCaret(TextPosition(offset: i), Rect.zero);
      final color = accented(i) && words.accent != null ? words.accent! : base;
      final glyph = TextPainter(
        text: TextSpan(
          text: ch,
          style: words.style.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lastX = caret.dx + glyph.width;
      lastY = caret.dy;
      lastH = glyph.height;
      if (ch.trim().isEmpty) continue;

      // Leaving, the letters go up and out in the order they came.
      final out = (leaving * 1.4 - i / math.max(plain.length, 1) * 0.4).clamp(
        0.0,
        1.0,
      );
      p = p * (1 - out);
      final alpha = switch (words.reveal) {
        Reveal.fade => p,
        _ => (p * 1.6).clamp(0.0, 1.0),
      };
      final rise = switch (words.reveal) {
        Reveal.typewriter => 0.0,
        Reveal.fade => (1 - p) * glyph.height * 0.25,
        _ => (1 - p) * glyph.height * 0.9,
      };
      final dy = out > 0 ? -out * glyph.height * 0.6 : rise;

      canvas.save();
      if (words.reveal == Reveal.letters || words.reveal == Reveal.words) {
        // The line the letters rise from: everything below it is hidden, so
        // a letter appears from nowhere rather than sliding up the screen.
        canvas.clipRect(
          Rect.fromLTRB(
            caret.dx - glyph.height,
            caret.dy - glyph.height,
            caret.dx + glyph.width + glyph.height,
            caret.dy + glyph.height,
          ),
        );
      }
      final paint = TextPainter(
        text: TextSpan(
          text: ch,
          style: words.style.copyWith(
            color: color.withValues(alpha: color.a * alpha),
            shadows: [
              for (final s in words.style.shadows ?? const <Shadow>[])
                Shadow(
                  color: s.color.withValues(alpha: s.color.a * alpha),
                  offset: s.offset,
                  blurRadius: s.blurRadius,
                ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      paint.paint(canvas, Offset(caret.dx, caret.dy + dy));
      canvas.restore();
    }

    if (words.reveal == Reveal.typewriter && leaving == 0) {
      final typing = shown < plain.length;
      final blink = (secondsOf(t) * 2).floor().isEven;
      if (typing || blink) {
        canvas.drawRect(
          Rect.fromLTWH(lastX + 2, lastY + lastH * 0.12, 3, lastH * 0.76),
          Paint()..color = words.accent ?? base,
        );
      }
    }
  }

  void _paintMarker(
    Canvas canvas,
    TextPainter whole,
    List<(int, int)> accents,
    double leaving,
  ) {
    final sweep =
        progress(
          t,
          words.landed - 200.ms,
          words.landed + 350.ms,
          curve: _rise,
        ) *
        (1 - leaving);
    if (sweep <= 0) return;
    final color = words.markerColor ?? words.accent!.withValues(alpha: 0.32);
    for (final (a, b) in accents) {
      for (final box in whole.getBoxesForSelection(
        TextSelection(baseOffset: a, extentOffset: b),
      )) {
        final r = box.toRect();
        final band = Rect.fromLTRB(
          r.left - 6,
          r.top + r.height * 0.45,
          r.left - 6 + (r.width + 12) * sweep,
          r.bottom - r.height * 0.05,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(band, const Radius.circular(4)),
          Paint()..color = color,
        );
      }
    }
  }

  static List<int> _wordIndexes(String text) {
    final out = <int>[];
    var word = 0;
    var inSpace = false;
    for (var i = 0; i < text.length; i++) {
      final space = text[i].trim().isEmpty;
      if (!space && inSpace) word++;
      inSpace = space;
      out.add(word);
    }
    return out;
  }

  @override
  bool shouldRepaint(WordsPainter old) =>
      old.t != t || old.words != words || old.maxWidth != maxWidth;
}
