import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'audio.dart';
import 'format.dart';
import 'layer.dart';
import 'packs/brand.dart';
import 'packs/dark_glow.dart';
import 'packs/glass_layers.dart';
import 'packs/kinetic_launch.dart';
import 'packs/story_ad.dart';
import 'scene.dart';
import 'time.dart';

/// One of the app's screens, staged for reels: the widget in its demo
/// state, a name for people, and anything it always needs (a scroll back
/// to the top, say).
class ReelScreen {
  /// The screen, staged.
  final Widget widget;

  /// What people call it.
  final String label;

  /// Scrolls it always needs.
  final List<Scroll> scrolls;

  /// A screen.
  const ReelScreen(this.widget, {required this.label, this.scrolls = const []});
}

/// What an app offers the studio's builder: its staged screens by id, its
/// logos, and the touches every reel of it shares.
class ReelKit {
  /// The screens a reel can use, by id.
  final Map<String, ReelScreen> screens;

  /// Logos by name, built from a scene's clock in a colour that reads on
  /// its ground: `mark` opens a reel, `wordmark` ends it.
  final Map<String, Widget Function(Duration t, Color color)> logos;

  /// The logos' boxes, by name.
  final Map<String, Size> logoSizes;

  /// Drawn over the top of each screen.
  final Widget? statusBar;

  /// What a lifted widget leaves.
  final Widget Function(double radius)? hole;

  /// The corner radius of the app's cards.
  final double liftRadius;

  /// The app's address, for end cards.
  final String? url;

  /// A kit.
  const ReelKit({
    required this.screens,
    this.logos = const {},
    this.logoSizes = const {},
    this.statusBar,
    this.hole,
    this.liftRadius = 24,
    this.url,
  });
}

/// A reel written as data, as the studio's builder writes it:
/// `app_reels/specs/<name>.json`. Parts are found by the names the map
/// gives them, so a spec needs no Dart.
///
/// ```json
/// { "pack": "glass", "look": "mesh", "open": "mark",
///   "beats": [ { "screen": "home", "word": "Share.",
///                "parts": [ { "type": "WalletSummaryCard", "text": "SHARED" } ] } ],
///   "end": { "logo": "wordmark", "line": "Shared money, no awkward chats." } }
/// ```
class ReelSpec {
  /// The spec as read.
  final Map<String, Object?> json;

  /// A spec.
  const ReelSpec(this.json);

  /// Reads [path].
  factory ReelSpec.load(String path) => ReelSpec(
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>,
  );

  /// Every spec in [dir], by file name.
  static Map<String, ReelSpec> all(String dir) {
    final d = Directory(dir);
    if (!d.existsSync()) return const {};
    return {
      for (final f in d.listSync().whereType<File>())
        if (f.path.endsWith('.json'))
          f.uri.pathSegments.last.replaceAll('.json', ''): ReelSpec.load(
            f.path,
          ),
    };
  }

  String get _pack => '${json['pack'] ?? 'glass'}';

  List<Map<String, Object?>> get _beats => [
    for (final b in (json['beats'] as List?) ?? const [])
      b as Map<String, Object?>,
  ];

  /// A part as the map names it: `{type, text?, nth?}`.
  static Pick pick(Map<String, Object?> part) {
    final type = '${part['type']}';
    var p = Pick((w) => w.runtimeType.toString() == type);
    final text = part['text'];
    if (text is String && text.isNotEmpty) {
      p = p.containing(Pick.text(text));
    }
    final nth = part['nth'];
    if (nth is int) p = p.nth(nth);
    return p;
  }

  static double _num(Object? v, double fallback) =>
      v is num ? v.toDouble() : fallback;

  static GlassLook? _look(Object? v) => v == null
      ? null
      : GlassLook.values.firstWhere(
          (l) => l.name == v,
          orElse: () => throw FormatException('Unknown look "$v"'),
        );

  /// The reel, for [format], drawn with [kit].
  Reel build({
    required String name,
    required ReelKit kit,
    required ReelConfig config,
    required Format format,
  }) {
    final brand = Brand.from(config);
    final look = _look(json['look']) ?? GlassLook.ink;
    Color logoColor(GlassLook l) => l.isLight ? brand.ink : brand.paper;
    Widget Function(Duration)? logo(Object? key, GlassLook l) {
      final b = key == null ? null : kit.logos['$key'];
      return b == null ? null : (t) => b(t, logoColor(l));
    }

    Size logoSize(Object? key, Size fallback) =>
        kit.logoSizes['$key'] ?? fallback;

    ReelScreen screen(Map<String, Object?> b) {
      final id = '${b['screen']}';
      return kit.screens[id] ??
          (throw FormatException('No screen "$id" in the kit'));
    }

    List<Pick> parts(Map<String, Object?> b) => [
      for (final p in (b['parts'] as List?) ?? const [])
        pick(p as Map<String, Object?>),
    ];

    final music = switch (json['music']) {
      null => config.music == null ? null : Music(config.music!, gain: -8),
      'none' => null,
      final m => Music('$m', gain: -8),
    };
    final end = json['end'] as Map<String, Object?>?;
    final fps = (json['fps'] as int?) ?? config.fps;

    GlassBeat glassBeat(Map<String, Object?> b) {
      final s = screen(b);
      final framing = b['framing'] as List?;
      return GlassBeat(
        '${b['word'] ?? ''}',
        screen: s.widget,
        lift: parts(b),
        liftRadius: kit.liftRadius,
        length: _num(b['length'], 5.6).s,
        look: _look(b['look']),
        sweep: b['move'] == 'sweep',
        zoom: _num(b['zoom'], 1),
        framing: framing == null
            ? Offset.zero
            : Offset(_num(framing[0], 0), _num(framing[1], 0)),
        scrolls: s.scrolls,
        typing: [
          if (b['type'] is String && '${b['type']}'.isNotEmpty)
            TypeText(
              // Into the field the builder chose, or the screen's first.
              where: b['typeInto'] is Map
                  ? pick((b['typeInto']! as Map).cast<String, Object?>())
                  : null,
              text: '${b['type']}',
              at: 700.ms,
              perCharacter: 60.ms,
              sound: 'tick',
            ),
        ],
      );
    }

    GlassEnd? glassEnd() => end == null
        ? null
        : GlassEnd(
            logo:
                logo(end['logo'] ?? 'wordmark', look) ??
                (t) => const SizedBox(),
            logoSize: logoSize(end['logo'] ?? 'wordmark', const Size(340, 110)),
            line: end['line'] as String?,
            url: (end['url'] ?? kit.url) as String?,
            length: _num(end['length'], 4.7).s,
          );

    return switch (_pack) {
      'glass' => GlassLayers(
        brand: brand,
        format: format,
        fps: fps,
        look: look,
        statusBar: kit.statusBar,
        hole: kit.hole,
        music: music,
        motionBlur: (json['motionBlur'] as int?) ?? 1,
        open: logo(json['open'], look),
        openSize: logoSize(json['open'], const Size(220, 220)),
        beats: [for (final b in _beats) glassBeat(b)],
        end: glassEnd(),
      ).build(name),
      'kinetic' => KineticLaunch(
        brand: brand,
        format: format,
        fps: fps,
        statusBar: kit.statusBar,
        hole: kit.hole,
        music: music,
        dark: json['look'] != null && !look.isLight,
        beats: [
          for (final b in _beats)
            KineticBeat(
              '${b['line'] ?? b['word'] ?? ''}',
              screen: b['screen'] == null ? null : screen(b).widget,
              lift: b['screen'] == null ? const [] : parts(b),
              liftRadius: kit.liftRadius,
              length: _num(b['length'], 4.2).s,
            ),
        ],
        logo: end == null
            ? null
            : logo(end['logo'] ?? 'wordmark', GlassLook.mesh),
        logoSize: logoSize(end?['logo'] ?? 'wordmark', const Size(320, 100)),
        line: end?['line'] as String?,
        url: (end?['url'] ?? kit.url) as String?,
      ).build(name),
      'glow' => DarkGlow(
        brand: brand,
        format: format,
        fps: fps,
        statusBar: kit.statusBar,
        hole: kit.hole,
        music: music,
        motionBlur: (json['motionBlur'] as int?) ?? 2,
        stops: [
          for (final b in _beats)
            GlowStop(
              screen: screen(b).widget,
              title: '${b['word'] ?? ''}',
              line: b['line'] as String?,
              lift: parts(b),
              liftRadius: kit.liftRadius,
              scrolls: screen(b).scrolls,
            ),
        ],
        logo: end == null
            ? null
            : logo(end['logo'] ?? 'wordmark', GlassLook.ink),
        logoSize: logoSize(end?['logo'] ?? 'wordmark', const Size(320, 100)),
        url: (end?['url'] ?? kit.url) as String?,
      ).build(name),
      'story' => StoryAd(
        brand: brand,
        format: format,
        fps: fps,
        statusBar: kit.statusBar,
        hole: kit.hole,
        music: music,
        hook: [for (final l in (json['hook'] as List?) ?? const []) '$l'],
        problem: [for (final l in (json['problem'] as List?) ?? const []) '$l'],
        meet:
            logo(json['open'] ?? 'mark', GlassLook.ink) ??
            (t) => const SizedBox(),
        meetSize: logoSize(json['open'] ?? 'mark', const Size(200, 200)),
        meetLine: json['meetLine'] as String?,
        beats: [for (final b in _beats) glassBeat(b)],
        proof: [for (final l in (json['proof'] as List?) ?? const []) '$l'],
        end:
            glassEnd() ??
            GlassEnd(logo: (t) => const SizedBox(), logoSize: Size.zero),
      ).build(name),
      _ => throw FormatException('Unknown pack "$_pack"'),
    };
  }
}
