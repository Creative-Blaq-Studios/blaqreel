import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'audio.dart';
import 'backdrop.dart';
import 'format.dart';
import 'ground.dart';
import 'layer.dart';
import 'packs/brand.dart';
import 'packs/dark_glow.dart';
import 'packs/glass_layers.dart';
import 'packs/kinetic_launch.dart';
import 'packs/story_ad.dart';
import 'scene.dart';
import 'time.dart';
import 'words.dart';

/// One of the app's screens, staged for reels: the widget in its demo
/// state, a name for people, and anything it always needs (a scroll back
/// to the top, say). Or, made with [ReelScreen.component], one piece of the
/// app on its own — a button, a card, a loading placeholder — that a beat
/// shows large on the ground with no phone around it.
class ReelScreen {
  /// The screen, staged.
  final Widget widget;

  /// What people call it.
  final String label;

  /// Scrolls it always needs.
  final List<Scroll> scrolls;

  /// For a component, the box it is laid out in; null for a screen.
  final Size? size;

  /// For a component, what a finger does to it in its beat: a press that
  /// puts a button into its loading state, say. Times are the beat's own.
  final List<Tap> taps;

  /// A screen.
  const ReelScreen(this.widget, {required this.label, this.scrolls = const []})
    : size = null,
      taps = const [];

  /// A piece of the app on its own, laid out at [size]: the widget the way
  /// it appears in the app, on a transparent ground.
  const ReelScreen.component(
    this.widget, {
    required this.label,
    required Size this.size,
    this.taps = const [],
  }) : scrolls = const [];

  /// Whether this is a piece of the app rather than a screen.
  bool get isComponent => size != null;
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

  static Color? _color(Object? v) {
    if (v is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) return null;
    return Color(0xFF000000 | int.parse(v.substring(1), radix: 16));
  }

  /// Words as a spec writes them: a style (`color`, `accent`, `size`,
  /// `weight`, `reveal`, `plate`, `layer`), and on a beat its timing
  /// (`at`, `until`, seconds) and where it sits in each frame (`places`:
  /// `{"vertical": {"pos": "bl", "dx": 0, "dy": 0, "width": 88}}`, `pos`
  /// a row t/m/b and a column l/c/r, `dx`/`dy` percent of the frame,
  /// `width` percent of the safe area).
  static GlassWords? _words(Object? v, Format format) {
    if (v is! Map) return null;
    final j = v.cast<String, Object?>();
    double? n(Object? x) => x is num ? x.toDouble() : null;
    final color = _color(j['color']);
    final place = (j['places'] as Map?)?[format.name];
    final p = place is Map ? place.cast<String, Object?>() : null;
    final pos = p?['pos'];
    final anchor = pos is String && pos.length == 2
        ? Alignment(
            switch (pos[1]) {
              'l' => -1,
              'r' => 1,
              _ => 0,
            },
            switch (pos[0]) {
              't' => -1,
              'b' => 1,
              _ => 0,
            },
          )
        : null;
    // A plate is light behind dark words and dark behind light ones.
    final dark = color == null || color.computeLuminance() < 0.4;
    final plate = switch (j['plate']) {
      'solid' => dark ? const Color(0xFFFFF8EC) : const Color(0xFF141414),
      'soft' => dark ? const Color(0x9EFFF8EC) : const Color(0x8C0E0E0E),
      'none' => const Color(0x00000000),
      _ => null,
    };
    final weight = n(j['weight']);
    return GlassWords(
      color: color,
      accent: _color(j['accent']),
      size: n(j['size']),
      weight: weight == null
          ? null
          : FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      reveal: switch (j['reveal']) {
        'letters' => Reveal.letters,
        'words' => Reveal.words,
        'type' || 'typewriter' => Reveal.typewriter,
        'fade' => Reveal.fade,
        _ => null,
      },
      at: n(j['at']) == null ? null : (n(j['at'])! * 1000).round().ms,
      until: n(j['until']) == null ? null : (n(j['until'])! * 1000).round().ms,
      anchor: anchor,
      offset: p == null
          ? null
          : Offset((n(p['dx']) ?? 0) / 100, (n(p['dy']) ?? 0) / 100),
      width: n(p?['width']) == null ? null : n(p!['width'])! / 100,
      plate: plate,
      plateBlur: j['plate'] == 'soft' ? 8 : (j['plate'] == null ? null : 0),
      behind: switch (j['layer']) {
        'behind' => true,
        'above' => false,
        _ => null,
      },
    );
  }

  /// A ground as a spec writes it: `{"pattern": "aurora", "speed": 1,
  /// "seed": 7, "beat": 120, "grain": true, "palette": {"top": "#…",
  /// "bottom": "#…", "colours": ["#…", "#…", "#…"], "light": false}}`.
  static Backdrop? _ground(Object? v) {
    if (v is! Map) return null;
    final j = v.cast<String, Object?>();
    final pal = (j['palette'] as Map?)?.cast<String, Object?>() ?? const {};
    final top = _color(pal['top']), bottom = _color(pal['bottom']);
    if (top == null || bottom == null) return null;
    final colours = [
      for (final c in (pal['colours'] as List?) ?? const []) ?_color(c),
    ];
    final light = pal['light'] == true;
    return Backdrop(
      top: top,
      bottom: bottom,
      vignette: light ? 0.12 : 0.45,
      light: light,
      motion: GroundMotion(
        pattern: GroundPattern.values.firstWhere(
          (p) => p.name == j['pattern'],
          orElse: () => GroundPattern.drift,
        ),
        colours: colours.isEmpty ? [top] : colours,
        speed: j['speed'] is num ? (j['speed']! as num).toDouble() : 1,
        seed: j['seed'] is num ? (j['seed']! as num).toInt() : 7,
        bpm: j['beat'] is num ? (j['beat']! as num).toDouble() : null,
        light: light,
        grain: j['grain'] == true ? 0.6 : 0,
      ),
    );
  }

  /// [a] over [b]: what [a] sets, else what [b] does.
  static GlassWords? _over(GlassWords? a, GlassWords? b) {
    if (a == null || b == null) return a ?? b;
    return GlassWords(
      color: a.color ?? b.color,
      accent: a.accent ?? b.accent,
      size: a.size ?? b.size,
      weight: a.weight ?? b.weight,
      reveal: a.reveal ?? b.reveal,
      at: a.at ?? b.at,
      until: a.until ?? b.until,
      anchor: a.anchor ?? b.anchor,
      offset: a.offset ?? b.offset,
      width: a.width ?? b.width,
      plate: a.plate ?? b.plate,
      plateBlur: a.plateBlur ?? b.plateBlur,
      behind: a.behind ?? b.behind,
    );
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
    // The reel's own ground, if it has one: it decides light and dark.
    final reelGround = _ground(json['ground']);
    Color logoColor(GlassLook l) =>
        (reelGround?.light ?? l.isLight) ? brand.ink : brand.paper;
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
    // The reel's words, which every beat's own sit over.
    final reelWords = _words(json['words'], format);
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
        // 'sweep' is what the builder first called the scan.
        sweep: b['move'] == 'sweep',
        move: GlassMove.values.firstWhere(
          (m) => m.name == b['move'],
          orElse: () => GlassMove.lift,
        ),
        zoom: _num(b['zoom'], 1),
        framing: framing == null
            ? Offset.zero
            : Offset(_num(framing[0], 0), _num(framing[1], 0)),
        scrolls: s.scrolls,
        piece: s.size,
        taps: s.taps,
        words: _over(_words(b['words'], format), reelWords),
        ground: _ground(b['ground']),
        // Each part's own landing place, height, size, turn, timing, scan.
        partMoves: [
          for (final p in (b['parts'] as List?) ?? const [])
            PartMove.fromJson((p as Map).cast<String, Object?>()),
        ],
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
        ground: reelGround,
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
              // Kinetic Launch's beats are screens; a component's beat
              // keeps its line and leaves the device out.
              screen: b['screen'] == null || screen(b).isComponent
                  ? null
                  : screen(b).widget,
              lift: b['screen'] == null || screen(b).isComponent
                  ? const []
                  : parts(b),
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
          // Dark Glow's camera travels past screens; components sit out.
          for (final b in _beats)
            if (!screen(b).isComponent)
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
