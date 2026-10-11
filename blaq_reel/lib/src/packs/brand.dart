import 'package:flutter/painting.dart';

import '../format.dart';

/// An app's look, as a style pack needs it: reel.yaml's colours and faces.
class Brand {
  /// The darkest colour: text on light grounds, the ground of dark reels.
  final Color ink;

  /// The one bright colour.
  final Color accent;

  /// The lightest colour: text on dark grounds, the ground of light reels.
  final Color paper;

  /// The face for words on screen.
  final String display;

  /// The face for small type.
  final String text;

  /// The weight words are set in.
  final double weight;

  /// A brand.
  const Brand({
    required this.ink,
    required this.accent,
    required this.paper,
    required this.display,
    required this.text,
    this.weight = 800,
  });

  /// The brand reel.yaml describes: `ink`, `accent` and `paper` colours,
  /// `display` and `text` faces.
  factory Brand.from(ReelConfig config) => Brand(
    ink: config.color('ink'),
    accent: config.color('accent'),
    paper: config.color('paper'),
    display: config.font('display'),
    text: config.fonts['text'] ?? config.font('display'),
  );

  /// The display face at [size], in [color].
  TextStyle words(double size, Color color, {double tracking = -0.035}) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontVariations: [FontVariation('wght', weight)],
        letterSpacing: size * tracking,
        height: 1.02,
        color: color,
      );

  /// The text face at [size], in [color].
  TextStyle small(double size, Color color, {double weight = 500}) => TextStyle(
    fontFamily: text,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
    letterSpacing: size * 0.01,
    height: 1.3,
    color: color,
  );
}
