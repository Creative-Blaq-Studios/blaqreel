import 'dart:io';
import 'package:flutter/painting.dart';

import 'package:yaml/yaml.dart';

/// A frame size and where it is safe to put words in it.
///
/// A reel is laid out in logical units ([logical]), the way an app is, and
/// drawn at [pixelRatio] — so a vertical reel is a 360×640 stage drawn three
/// times over into 1080×1920 pixels, and a phone screen placed on it keeps
/// the type sizes it has on a phone.
class Format {
  /// A name for file names and logs.
  final String name;

  /// The frame, in pixels.
  final Size pixels;

  /// Pixels per logical unit.
  final double pixelRatio;

  /// The part of the frame a platform's own buttons and captions leave
  /// alone, as fractions of each edge.
  final EdgeInsets safe;

  /// A format.
  const Format(
    this.name,
    this.pixels, {
    this.pixelRatio = 3,
    this.safe = const EdgeInsets.all(0.06),
  });

  /// 1080×1920, 9:16: Shorts, Reels, TikTok. The bottom fifth carries their
  /// captions and buttons, so words stay above it.
  static const vertical = Format(
    'vertical',
    Size(1080, 1920),
    safe: EdgeInsets.fromLTRB(0.06, 0.08, 0.12, 0.2),
  );

  /// 1920×1080, 16:9: YouTube and the website.
  static const wide = Format('wide', Size(1920, 1080));

  /// 1080×1080, 1:1.
  static const square = Format('square', Size(1080, 1080));

  /// 1080×1350, 4:5: the Instagram and Facebook feed.
  static const portrait = Format(
    'portrait',
    Size(1080, 1350),
    safe: EdgeInsets.fromLTRB(0.06, 0.06, 0.06, 0.08),
  );

  /// Every format, by name.
  static const all = [vertical, wide, square, portrait];

  /// Taller than it is wide.
  bool get isTall => pixels.height > pixels.width;

  /// Wider than it is tall.
  bool get isWide => pixels.width > pixels.height;

  /// The stage, in logical units.
  Size get logical => pixels / pixelRatio;

  /// A format by its name in reel.yaml.
  static Format named(String name) => switch (name) {
    'vertical' => vertical,
    'wide' => wide,
    'square' => square,
    'portrait' => portrait,
    _ => throw ArgumentError.value(name, 'format', 'not a known format'),
  };
}

/// What reel.yaml says about an app: its brand, its default frame rate and
/// format, and where FFmpeg is.
class ReelConfig {
  /// The app's name.
  final String name;

  /// Frames per second, unless a render says otherwise.
  final int fps;

  /// The default format.
  final Format format;

  /// Named brand colours: `ink`, `accent`, `paper`, and any others.
  final Map<String, Color> colors;

  /// Named font families: `display` for words, `text` for anything smaller.
  final Map<String, String> fonts;

  /// Where rendered videos and stills go, relative to the app.
  final String out;

  /// The FFmpeg binary.
  final String ffmpeg;

  /// A music bed for every reel, unless a reel says otherwise.
  final String? music;

  /// Where synthesized sounds are kept.
  final String sound;

  /// A config.
  const ReelConfig({
    required this.name,
    this.fps = 30,
    this.format = Format.vertical,
    this.colors = const {},
    this.fonts = const {},
    this.out = 'app_reels/out',
    this.ffmpeg = 'ffmpeg',
    this.music,
    this.sound = 'app_reels/sound',
  });

  /// Reads [path], usually `app_reels/reel.yaml`.
  factory ReelConfig.load(String path) {
    final doc = loadYaml(File(path).readAsStringSync());
    if (doc is! YamlMap) {
      throw FormatException('$path is not a YAML map');
    }
    final brand = doc['brand'];
    final colors = <String, Color>{};
    final fonts = <String, String>{};
    if (brand is YamlMap) {
      for (final MapEntry(:key, :value) in brand.entries) {
        final text = '$value';
        if (text.startsWith('#')) {
          colors['$key'] = _hex(text);
        }
      }
      final f = brand['fonts'];
      if (f is YamlMap) {
        for (final MapEntry(:key, :value) in f.entries) {
          fonts['$key'] = '$value';
        }
      }
    }
    return ReelConfig(
      name: '${doc['name'] ?? 'app'}',
      fps: (doc['fps'] as int?) ?? 30,
      format: Format.named('${doc['format'] ?? 'vertical'}'),
      colors: colors,
      fonts: fonts,
      out: '${doc['out'] ?? 'app_reels/out'}',
      ffmpeg: '${doc['ffmpeg'] ?? 'ffmpeg'}',
      music: doc['music'] == null ? null : '${doc['music']}',
      sound: '${doc['sound'] ?? 'app_reels/sound'}',
    );
  }

  /// The brand colour [name]; fails loudly when reel.yaml lacks it.
  Color color(String name) =>
      colors[name] ??
      (throw ArgumentError.value(name, 'color', 'not in reel.yaml brand'));

  /// The font family [name]; fails loudly when reel.yaml lacks it.
  String font(String name) =>
      fonts[name] ??
      (throw ArgumentError.value(name, 'font', 'not in reel.yaml brand.fonts'));

  static Color _hex(String text) {
    final hex = text.substring(1);
    final argb = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.parse(argb, radix: 16));
  }
}
