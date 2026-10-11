import 'dart:math' as math;
import 'dart:ui' show ImageFilter, TileMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' hide Layer;
import 'package:flutter/widgets.dart';

import 'backdrop.dart';
import 'camera.dart';
import 'layer.dart';
import 'reel.dart';
import 'scene.dart';
import 'time.dart';
import 'words.dart';

/// Where a layer is: its scene and its index in that scene.
typedef LayerKey = (int scene, int layer);

/// Where something acting on a layer is: its scene, layer and own index.
typedef PartKey = (int scene, int layer, int part);

/// A press the renderer should make in the app: where on the stage, in
/// logical units.
class Press {
  /// The point, in stage coordinates.
  final Offset at;

  /// A press.
  const Press(this.at);
}

/// Draws a [Reel] at the moment [time] holds.
///
/// Everything on the stage is a function of that moment, so the same moment
/// always draws the same frame. Every scene's screens are built once, when
/// the stage is, and kept — offstage while their scene is not showing — so
/// the clock never rebuilds the app: only transforms, blurs and opacities
/// around it change, and the scrolls and typing scenes ask for.
class ReelStage extends StatefulWidget {
  /// The reel.
  final Reel reel;

  /// How the app's screens are drawn.
  final ReelHost host;

  /// The moment to draw.
  final ValueListenable<Duration> time;

  /// A stage.
  const ReelStage({
    super.key,
    required this.reel,
    required this.host,
    required this.time,
  });

  @override
  State<ReelStage> createState() => ReelStageState();
}

/// The stage's state: the screens it has built and what it has found in
/// them.
class ReelStageState extends State<ReelStage> {
  /// Clear space kept around a lifted widget, so its own shadow is not cut
  /// off by the host's app around it.
  static const _liftPad = 24.0;

  final Map<LayerKey, GlobalKey> _keys = {};
  final Map<LayerKey, GlobalKey> _shots = {};
  final Map<LayerKey, Widget> _contents = {};
  final Map<PartKey, _Lifted> _lifted = {};
  final Map<PartKey, Rect> _tapRects = {};
  final Map<PartKey, ScrollPosition> _scrolls = {};
  final Map<PartKey, TextEditingController> _fields = {};

  Size get _stage => widget.reel.format.logical;

  /// Whether every [Lift] in every scene has been found and cloned.
  bool get ready {
    var n = 0;
    for (final s in widget.reel.scenes) {
      for (final l in s.layers) {
        n += l.lifts.length;
      }
    }
    return _lifted.length == n;
  }

  /// The lifts not found yet, as "scene/layer/lift" for an error message.
  List<String> get missing => [
    for (final (i, s) in widget.reel.scenes.indexed)
      for (final (j, l) in s.layers.indexed)
        for (var k = 0; k < l.lifts.length; k++)
          if (!_lifted.containsKey((i, j, k))) '${s.name}/layer $j/lift $k',
  ];

  @override
  void initState() {
    super.initState();
    final scenes = widget.reel.scenes;
    for (var i = 0; i < scenes.length; i++) {
      for (var j = 0; j < scenes[i].layers.length; j++) {
        final layer = scenes[i].layers[j];
        _keys[(i, j)] = GlobalKey();
        _shots[(i, j)] = GlobalKey();
        _contents[(i, j)] = layer.isScreen
            ? MediaQuery(
                data: layer.device!.media,
                child: widget.host.wrap(layer.child),
              )
            : layer.child;
      }
    }
    widget.time.addListener(_act);
  }

  /// Sets every scene's screens as they are when the scene starts — scrolled
  /// and typed into — and then looks for lifted widgets, once the next frame
  /// has laid that out. The renderer calls this once the host is ready.
  void prime() {
    for (final span in widget.reel.timeline) {
      _actOn(span, Duration.zero);
    }
    _lookAgain();
  }

  /// Looks for lifts after the next frame. A post-frame callback does not
  /// ask for a frame, and a test's pump draws one only when asked, so ask.
  void _lookAgain() {
    WidgetsBinding.instance
      ..addPostFrameCallback(_findLifts)
      ..scheduleFrame();
  }

  @override
  void dispose() {
    widget.time.removeListener(_act);
    super.dispose();
  }

  // ── Finding things in screens ────────────────────────────────────────

  Element? _find(LayerKey key, Pick pick) {
    final root = _keys[key]?.currentContext;
    if (root is! Element) return null;
    final inner = pick.inner;
    var seen = 0;
    Element? match;

    if (inner == null) {
      void visit(Element e) {
        if (match != null) return;
        if (pick.test(e.widget) && seen++ == pick.index) {
          match = e;
          return;
        }
        e.visitChildren(visit);
      }

      root.visitChildren(visit);
      return match;
    }

    // Innermost first: a child that matches wins over its parent.
    bool holds(Element e) {
      var found = false;
      void look(Element c) {
        if (found) return;
        if (_matches(c, inner)) {
          found = true;
          return;
        }
        c.visitChildren(look);
      }

      e.visitChildren(look);
      return found;
    }

    bool visit(Element e) {
      var child = false;
      e.visitChildren((c) {
        if (match == null && visit(c)) child = true;
      });
      if (match != null) return true;
      if (!child && pick.test(e.widget) && holds(e)) {
        if (seen++ == pick.index) match = e;
        return true;
      }
      return child;
    }

    root.visitChildren((e) {
      if (match == null) visit(e);
    });
    return match;
  }

  static bool _matches(Element e, Pick pick) => pick.test(e.widget);

  /// [e]'s box, in its screen's own coordinates.
  Rect? _rectIn(LayerKey key, Element e) {
    final rootBox = _keys[key]?.currentContext?.findRenderObject();
    final box = e.findRenderObject();
    if (rootBox is! RenderBox || box is! RenderBox) return null;
    if (!rootBox.hasSize || !box.hasSize || !box.attached) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(rootBox),
      Offset.zero & box.size,
    );
  }

  void _findLifts(Duration _) {
    if (!mounted) return;
    var found = false;
    final scenes = widget.reel.scenes;
    for (var i = 0; i < scenes.length; i++) {
      for (var j = 0; j < scenes[i].layers.length; j++) {
        final layer = scenes[i].layers[j];
        for (var k = 0; k < layer.lifts.length; k++) {
          if (_lifted.containsKey((i, j, k))) continue;
          final match = _find((i, j), layer.lifts[k].where);
          if (match == null) continue;
          final rect = _rectIn((i, j), match);
          if (rect == null) continue;
          _lifted[(i, j, k)] = _Lifted(
            rect,
            MediaQuery(
              data: layer.device?.media ?? MediaQuery.of(context),
              child: widget.host.wrap(
                Padding(
                  padding: const EdgeInsets.all(_liftPad),
                  child: SizedBox.fromSize(
                    size: rect.size,
                    child: match.widget,
                  ),
                ),
              ),
            ),
          );
          found = true;
        }
      }
    }
    if (found) setState(() {});
    if (!ready) _lookAgain();
  }

  // ── Acting on screens ────────────────────────────────────────────────

  /// Scrolls and types for the moment the clock has just moved to, before
  /// the frame is built.
  void _act() {
    final t = widget.time.value;
    for (final span in widget.reel.timeline) {
      if (span.shows(t)) _actOn(span, span.scene.local(t - span.start));
    }
  }

  void _actOn(SceneSpan span, Duration local) {
    final i = span.index;
    for (var j = 0; j < span.scene.layers.length; j++) {
      final layer = span.scene.layers[j];
      for (var k = 0; k < layer.scrolls.length; k++) {
        final position =
            _scrolls[(i, j, k)] ?? _scrollable((i, j), layer.scrolls[k].where);
        if (position == null || !position.hasContentDimensions) continue;
        _scrolls[(i, j, k)] = position;
        final target = layer.scrolls[k].offset
            .at(local)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        if (target != position.pixels) position.jumpTo(target);
      }
      for (var k = 0; k < layer.typing.length; k++) {
        final controller =
            _fields[(i, j, k)] ?? _field((i, j), layer.typing[k].where);
        if (controller == null) continue;
        _fields[(i, j, k)] = controller;
        final text = layer.typing[k].typedAt(local);
        if (controller.text != text) {
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
      for (var k = 0; k < layer.taps.length; k++) {
        final tap = layer.taps[k];
        if (local < tap.arrives - 100.ms || local > tap.leaves) continue;
        final match = _find((i, j), tap.where);
        final rect = match == null ? null : _rectIn((i, j), match);
        if (rect != null) _tapRects[(i, j, k)] = rect;
      }
    }
  }

  ScrollPosition? _scrollable(LayerKey key, Pick where) {
    final e = _find(key, where);
    if (e is StatefulElement && e.state is ScrollableState) {
      return (e.state as ScrollableState).position;
    }
    return null;
  }

  TextEditingController? _field(LayerKey key, Pick where) {
    final e = _find(key, where);
    if (e == null) return null;
    final w = e.widget;
    if (w is EditableText) return w.controller;
    TextEditingController? found;
    void visit(Element c) {
      if (found != null) return;
      final cw = c.widget;
      if (cw is EditableText) {
        found = cw.controller;
        return;
      }
      c.visitChildren(visit);
    }

    e.visitChildren(visit);
    return found;
  }

  /// The presses whose moment falls after [from] and at or before [to], on
  /// the stage, for the renderer to make.
  List<Press> pressesBetween(Duration from, Duration to) {
    final out = <Press>[];
    for (final span in widget.reel.timeline) {
      for (var j = 0; j < span.scene.layers.length; j++) {
        final layer = span.scene.layers[j];
        for (final tap in layer.taps.where((t) => t.press)) {
          final at = span.start + tap.at;
          if (at <= from || at > to) continue;
          final e = _find((span.index, j), tap.where);
          final box = e?.findRenderObject();
          if (box is! RenderBox || !box.hasSize) continue;
          out.add(Press(box.localToGlobal(tap.point.alongSize(box.size))));
        }
      }
    }
    return out;
  }

  // ── Mapping screens ──────────────────────────────────────────────────

  /// The screen [key] as drawn, flat, without the camera: for the map.
  RenderRepaintBoundary? screenBoundary(LayerKey key) {
    final ro = _shots[key]?.currentContext?.findRenderObject();
    return ro is RenderRepaintBoundary ? ro : null;
  }

  /// Every widget in screen [key] that could be lifted, tapped or featured:
  /// cards, panels, rows and fields big enough to read, each named the way
  /// the app's own code names it, with a [Pick] that finds it again.
  List<ScreenPart> mapScreen(LayerKey key) {
    final root = _keys[key]?.currentContext;
    final rootBox = root?.findRenderObject();
    if (root is! Element || rootBox is! RenderBox || !rootBox.hasSize) {
      return const [];
    }
    final screen = Offset.zero & rootBox.size;
    final byOwner = <Element, ScreenPart>{};
    final typeOrder = <String, List<Element>>{};

    void collectTypes(Element e) {
      (typeOrder[e.widget.runtimeType.toString()] ??= []).add(e);
      e.visitChildren(collectTypes);
    }

    root.visitChildren(collectTypes);

    void visit(Element e) {
      // Only the element that made a box: wrappers share their child's.
      final ro = e is RenderObjectElement ? e.renderObject : null;
      if (ro is RenderBox && ro.hasSize && _cardish(ro)) {
        final rect = _rectIn(key, e);
        // Photos count from a smaller size than panels: a receipt's
        // thumbnail is worth featuring.
        final min = ro is RenderImage ? 0.16 : 0.3;
        if (rect != null &&
            rect.width >= screen.width * min &&
            rect.height >= 30 &&
            rect.width * rect.height <= screen.width * screen.height * 0.75 &&
            screen.overlaps(rect)) {
          final owner = _owner(e, key, rect) ?? e;
          if (!byOwner.containsKey(owner)) {
            final part = _describe(owner, key, rect, typeOrder);
            // Only what shows: a card half off the side is outlined where it
            // can be seen.
            byOwner[owner] = ScreenPart(
              name: part.name,
              text: part.text,
              rect: part.rect.intersect(screen),
              pick: part.pick,
            );
          }
        }
      }
      e.visitChildren(visit);
    }

    root.visitChildren(visit);
    final named = byOwner.values.where((p) => !_wrapper(p.name)).toList();
    bool near(Rect a, Rect b) =>
        (a.left - b.left).abs() < 14 &&
        (a.top - b.top).abs() < 14 &&
        (a.right - b.right).abs() < 14 &&
        (a.bottom - b.bottom).abs() < 14;
    // A box the app did not name is kept only where no named one sits, and
    // never when it spans the screen: that is a page or a band, not a part.
    byOwner.removeWhere(
      (_, p) =>
          (_wrapper(p.name) || p.name.startsWith('Physical')) &&
          (named.any((n) => near(n.rect, p.rect)) ||
              p.rect.width >= screen.width * 0.94),
    );
    final entries = byOwner.values.toList()
      ..sort((a, b) {
        final dy = a.rect.top.compareTo(b.rect.top);
        return dy != 0 ? dy : a.rect.left.compareTo(b.rect.left);
      });
    return entries;
  }

  static bool _cardish(RenderBox ro) {
    if (ro is RenderPhysicalShape || ro is RenderPhysicalModel) return true;
    if (ro is RenderImage) return ro.image != null;
    // `Container(color:)` and `ColoredBox` paint with a private box.
    if (ro.runtimeType.toString() == '_RenderColoredBox') return true;
    if (ro is RenderEditable) return true;
    if (ro is RenderDecoratedBox) {
      final d = ro.decoration;
      if (d is BoxDecoration) {
        return d.color != null || d.border != null || d.gradient != null;
      }
      if (d is ShapeDecoration) return d.color != null || d.gradient != null;
    }
    return false;
  }

  /// Layout widgets the app also makes, which never name a feature.
  static const _generic = {
    'Padding',
    'SizedBox',
    'Column',
    'Row',
    'Container',
    'DecoratedBox',
    'Align',
    'Center',
    'Expanded',
    'Flexible',
    'Stack',
    'Positioned',
    'ConstrainedBox',
    'ClipRSuperellipse',
    'ClipRRect',
    'ClipPath',
    'Material',
    'InkWell',
    'GestureDetector',
    'Opacity',
    'Builder',
    'LayoutBuilder',
    'IntrinsicHeight',
    'IntrinsicWidth',
    'Wrap',
    'Semantics',
    'KeyedSubtree',
    'MediaQuery',
    'Theme',
    'DefaultTextStyle',
    'IconTheme',
    'Transform',
    'FractionallySizedBox',
    'AspectRatio',
    'Consumer',
    'HookBuilder',
    'ValueListenableBuilder',
    'AnimatedBuilder',
    'ListenableBuilder',
    'StreamBuilder',
    'FutureBuilder',
    'SafeArea',
    'ColoredBox',
    'Ink',
    'Card',
    'ListTile',
    'Text',
    'RichText',
  };

  /// Wrappers that sit around a feature without being one.
  static bool _wrapper(String name) =>
      _generic.contains(name) ||
      const [
        'Scope',
        'Menu',
        'Provider',
        'Listener',
        'Builder',
        'Theme',
        'Frame',
        'Consumer',
        'Notifier',
        'Region',
        'Detector',
        'Boundary',
      ].any(name.contains);

  /// The widget that owns [e]'s box: the outermost widget the app's own code
  /// made that draws exactly that box and is a feature rather than a
  /// wrapper. Null when the box belongs to nothing the app named.
  Element? _owner(Element e, LayerKey key, Rect rect) {
    Element? best;
    var depth = 0;
    Element? walk = e;
    final top = _keys[key]?.currentContext;
    while (walk != null && depth < 16) {
      final w = walk.widget;
      final name = w.runtimeType.toString();
      if (debugIsWidgetLocalCreation(w) && !_wrapper(name)) {
        final r = _rectIn(key, walk);
        if (r != null && _same(r, rect)) best = walk;
      }
      Element? parent;
      walk.visitAncestorElements((p) {
        parent = p;
        return false;
      });
      if (parent == null || parent == top) break;
      walk = parent;
      depth++;
    }
    return best;
  }

  static bool _same(Rect a, Rect b) =>
      (a.left - b.left).abs() < 6 &&
      (a.top - b.top).abs() < 6 &&
      (a.right - b.right).abs() < 6 &&
      (a.bottom - b.bottom).abs() < 6;

  ScreenPart _describe(
    Element owner,
    LayerKey key,
    Rect rect,
    Map<String, List<Element>> typeOrder,
  ) {
    final name = owner.widget.runtimeType.toString();
    final same = typeOrder[name] ?? [owner];
    final text = _firstText(owner);
    String pick;
    final base = name.startsWith('_')
        ? "Pick.typeName('$name')"
        : 'Pick.type<$name>()';
    if (same.length <= 1) {
      pick = base;
    } else if (text != null) {
      final quoted = text.replaceAll("'", r"\'");
      pick = "$base.containing(Pick.text('$quoted'))";
    } else {
      pick = '$base.nth(${same.indexOf(owner)})';
    }
    return ScreenPart(
      name: name,
      text: text,
      rect: _rectIn(key, owner) ?? rect,
      pick: pick,
    );
  }

  static String? _firstText(Element e) {
    String? found;
    void look(Element c) {
      if (found != null) return;
      final w = c.widget;
      final t = w is Text
          ? (w.data ?? w.textSpan?.toPlainText())
          : (w is RichText ? w.text.toPlainText() : null);
      if (t != null && t.trim().length > 1) {
        found = t.trim();
        return;
      }
      c.visitChildren(look);
    }

    e.visitChildren(look);
    return found;
  }

  // ── Drawing ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: stage,
          devicePixelRatio: widget.reel.format.pixelRatio,
        ),
        child: SizedBox.fromSize(
          size: stage,
          child: ValueListenableBuilder<Duration>(
            valueListenable: widget.time,
            builder: (context, t, _) => Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: BackdropPainter(widget.reel.backdrop, t),
                  ),
                ),
                for (final span in widget.reel.timeline)
                  Positioned.fill(
                    key: ValueKey('scene ${span.index}'),
                    child: _scene(span, t),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene(SceneSpan span, Duration t) {
    final scene = span.scene;
    final i = span.index;
    final showing = span.shows(t);
    final onScreen = t < span.start
        ? Duration.zero
        : (t >= span.end ? span.end - span.start : t - span.start);
    final local = scene.local(onScreen);
    final effect = showing ? span.effect(t, _stage) : SceneEffect.none;
    final leaving = span.leaving(t);
    final raw = scene.camera.at(local);
    final pose = effect.apply(raw);

    final world = <(double, int, Widget)>[];
    final carried = <(double, int, Widget)>[];
    for (var j = 0; j < scene.layers.length; j++) {
      final layer = scene.layers[j];
      final carry = leaving && layer.carry;
      _layerEntry(
        into: carry ? carried : world,
        key: (i, j),
        layer: layer,
        camera: scene.camera,
        pose: carry ? raw : pose,
        t: local,
      );
      for (var k = 0; k < layer.lifts.length; k++) {
        final lift = layer.lifts[k];
        final liftCarry = leaving && lift.carry;
        _liftEntry(
          into: liftCarry ? carried : world,
          key: (i, j, k),
          layer: layer,
          lift: lift,
          camera: scene.camera,
          pose: liftCarry ? raw : pose,
          t: local,
        );
      }
    }
    int order((double, int, Widget) a, (double, int, Widget) b) {
      final byDepth = a.$1.compareTo(b.$1);
      return byDepth != 0 ? byDepth : a.$2.compareTo(b.$2);
    }

    world.sort(order);
    carried.sort(order);

    final safe = widget.reel.format.safe;
    final stage = _stage;
    final safeWidth = stage.width * (1 - safe.left - safe.right);
    Widget body = Stack(
      children: [
        if (scene.backdrop != null)
          Positioned.fill(
            child: CustomPaint(painter: BackdropPainter(scene.backdrop!, t)),
          ),
        for (final (_, _, child) in world) child,
        for (final (k, words) in [
          for (final w in scene.words) w.fitted(safeWidth * w.maxWidth),
        ].indexed)
          Positioned.fill(
            key: ValueKey('words $k'),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                stage.width * safe.left,
                stage.height * safe.top,
                stage.width * safe.right,
                stage.height * safe.bottom,
              ),
              child: Align(
                alignment: words.align,
                child: CustomPaint(
                  size: WordsPainter.layout(
                    words,
                    safeWidth * words.maxWidth,
                  ).size,
                  painter: WordsPainter(
                    words,
                    local,
                    maxWidth: safeWidth * words.maxWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    final clip = effect.clip;
    if (clip != null) {
      final diagonal = math.sqrt(
        stage.width * stage.width + stage.height * stage.height,
      );
      body = ClipPath(
        clipper: _Circle(
          effect.clipCenter.withinRect(Offset.zero & stage),
          clip * diagonal,
        ),
        child: body,
      );
    }
    return Offstage(
      offstage: !showing,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: effect.opacity.clamp(0.0, 1.0),
              child: body,
            ),
          ),
          for (final (_, _, child) in carried) child,
        ],
      ),
    );
  }

  void _layerEntry({
    required List<(double, int, Widget)> into,
    required LayerKey key,
    required Layer layer,
    required Camera camera,
    required CameraPose pose,
    required Duration t,
  }) {
    final motion = layer.motion.at(t);
    final m = camera.project(
      pose: pose,
      stage: _stage,
      size: layer.size,
      position: layer.position,
      motion: motion,
    );
    final child = layer.isScreen
        ? _screen(key, layer, t)
        : layer.builder != null
        ? KeyedSubtree(key: _keys[key], child: layer.builder!(t))
        : KeyedSubtree(key: _keys[key], child: _contents[key]!);
    into.add((
      motion.z,
      into.length,
      _placed(
        key: ValueKey('layer ${key.$1}.${key.$2}'),
        matrix: m,
        size: layer.size,
        sigma: (layer.ignoreFocus ? 0 : pose.blurAt(motion.z)) + motion.blur,
        opacity: motion.opacity,
        glass: layer.glass,
        radius: layer.radius,
        child: child,
      ),
    ));
  }

  void _liftEntry({
    required List<(double, int, Widget)> into,
    required PartKey key,
    required Layer layer,
    required Lift lift,
    required Camera camera,
    required CameraPose pose,
    required Duration t,
  }) {
    final lifted = _lifted[key];
    if (lifted == null) return;
    final screen = layer.motion.at(t);
    final own = lift.motion.at(t);
    final box = lifted.rect.inflate(_liftPad);
    const rad = math.pi / 180;
    final m =
        camera.project(
            pose: pose,
            stage: _stage,
            size: layer.size,
            position: layer.position,
            motion: screen,
          )
          ..multiply(
            Matrix4.translationValues(
              lifted.rect.center.dx + own.x,
              lifted.rect.center.dy + own.y,
              -own.z,
            ),
          )
          ..multiply(Matrix4.rotationX(-own.tilt * rad))
          ..multiply(Matrix4.rotationY(own.turn * rad))
          ..multiply(Matrix4.rotationZ(own.roll * rad))
          ..multiply(Matrix4.diagonal3Values(own.scale, own.scale, 1))
          ..multiply(
            Matrix4.translationValues(-box.width / 2, -box.height / 2, 0),
          );
    final depth = screen.z + own.z;
    into.add((
      depth,
      into.length,
      _placed(
        key: ValueKey('lift ${key.$1}.${key.$2}.${key.$3}'),
        matrix: m,
        size: box.size,
        sigma: pose.blurAt(depth) + own.blur,
        opacity: own.opacity,
        glass: lift.glass,
        radius: lift.radius,
        inset: _liftPad,
        child: lift.sweep == null
            ? lifted.content
            : Stack(
                children: [
                  Positioned.fill(child: lifted.content),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(_liftPad),
                      child: CustomPaint(
                        painter: _SweepPainter(lift.sweep!, t, lift.radius),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ));
  }

  /// A box drawn through [matrix], softened by [sigma], with an optional
  /// glass edge behind it.
  Widget _placed({
    required Key key,
    required Matrix4 matrix,
    required Size size,
    required double sigma,
    required double opacity,
    required Widget child,
    Glass? glass,
    double radius = 0,
    double inset = 0,
  }) {
    final slab = <Widget>[];
    if (glass != null) {
      final shape = RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      );
      for (var s = glass.slices; s >= 1; s--) {
        slab.add(
          _at(
            matrix.clone()..multiply(
              Matrix4.translationValues(0, 0, glass.depth * s / glass.slices),
            ),
            size,
            Padding(
              padding: EdgeInsets.all(inset),
              child: DecoratedBox(
                decoration: ShapeDecoration(shape: shape, color: glass.color),
              ),
            ),
          ),
        );
      }
    }
    return Positioned.fill(
      key: key,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: ImageFiltered(
          enabled: sigma > 0.05,
          imageFilter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.decal,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [...slab, _at(matrix, size, child)],
          ),
        ),
      ),
    );
  }

  static Widget _at(Matrix4 matrix, Size size, Widget child) => Positioned(
    left: 0,
    top: 0,
    width: size.width,
    height: size.height,
    child: Transform(transform: matrix, child: child),
  );

  /// A device screen: its shadow, the app clipped to its corners, the status
  /// bar, what its lifted widgets leave, fingers, and a glass edge. A bare
  /// device ([Device.bare]) draws only the app, the lifts' traces and the
  /// fingers: a piece of the app on the ground as it is.
  Widget _screen(LayerKey key, Layer layer, Duration t) {
    final device = layer.device!;
    final radius = BorderRadius.circular(device.radius);
    final shape = RoundedSuperellipseBorder(borderRadius: radius);
    final (i, j) = key;

    final frame = device.frame;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (frame)
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: shape,
                shadows: const [
                  BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 70,
                    offset: Offset(0, 36),
                  ),
                ],
              ),
            ),
          ),
        Positioned.fill(
          child: ClipRSuperellipse(
            borderRadius: radius,
            clipBehavior: frame ? Clip.antiAlias : Clip.none,
            child: Stack(
              clipBehavior: frame ? Clip.hardEdge : Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _shots[key],
                    child: KeyedSubtree(
                      key: _keys[key],
                      child: _contents[key]!,
                    ),
                  ),
                ),
                if (frame && layer.statusBar != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: device.padding.top,
                    child: layer.statusBar!,
                  ),
                for (var k = 0; k < layer.lifts.length; k++)
                  if (_lifted[(i, j, k)] case final lifted?) ...[
                    if (layer.lifts[k].hole != null)
                      Positioned.fromRect(
                        rect: lifted.rect,
                        child: layer.lifts[k].hole!,
                      ),
                    _groundShadow(
                      layer.lifts[k],
                      lifted.rect,
                      layer.lifts[k].motion.z.at(t),
                    ),
                  ],
                for (var k = 0; k < layer.taps.length; k++)
                  if (_tapRects[(i, j, k)] case final rect?)
                    _finger(layer.taps[k], rect, t),
              ],
            ),
          ),
        ),
        if (frame)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: radius,
                    side: const BorderSide(
                      color: Color(0x47FFFFFF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The shadow a lifted widget casts on the screen it left: under it and a
  /// little below, darker and tighter near the surface, wider and softer as
  /// it rises.
  Widget _groundShadow(Lift lift, Rect rect, double height) {
    final h = height.clamp(0.0, double.infinity);
    final strength = (h / lift.shadowHeight).clamp(0.0, 1.0);
    if (strength <= 0) return const SizedBox.shrink();
    return Positioned.fromRect(
      rect: rect.shift(Offset(0, h * 0.16)).deflate(4),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(lift.radius),
          ),
          shadows: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, lift.shadow * strength),
              blurRadius: 10 + h * 0.3,
              spreadRadius: h * 0.02,
            ),
          ],
        ),
      ),
    );
  }

  /// A fingertip: it drifts in, presses with a ripple, lifts and fades.
  Widget _finger(Tap tap, Rect rect, Duration t) {
    if (t < tap.arrives || t > tap.leaves) return const SizedBox.shrink();
    final point = tap.point.withinRect(rect);
    final arrive = progress(t, tap.arrives, tap.at, curve: Ease.out);
    final press = progress(t, tap.at - 80.ms, tap.at + 120.ms);
    final release = progress(t, tap.at + 120.ms, tap.at + 260.ms);
    final fade = progress(t, tap.at + 300.ms, tap.leaves, curve: Ease.leave);
    final ripple = progress(t, tap.at, tap.at + 550.ms, curve: Ease.out);
    final down = press * (1 - release);
    const size = 46.0;
    final scale = 1.25 - 0.25 * arrive - 0.14 * down;
    final drift = const Offset(26, 34) * (1 - arrive);
    final alpha = arrive * (1 - fade);
    return Positioned(
      left: point.dx - 70 + drift.dx,
      top: point.dy - 70 + drift.dy,
      width: 140,
      height: 140,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (ripple > 0 && ripple < 1)
              Container(
                width: size + 80 * ripple,
                height: size + 80 * ripple,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color.fromRGBO(255, 255, 255, 0.7 * (1 - ripple)),
                    width: 2,
                  ),
                ),
              ),
            Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(255, 255, 255, 0.42 * alpha),
                  border: Border.all(
                    color: Color.fromRGBO(255, 255, 255, 0.9 * alpha),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.28 * alpha),
                      blurRadius: 16,
                      offset: Offset(0, 6 * (1 - down)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lifted {
  final Rect rect;
  final Widget content;

  const _Lifted(this.rect, this.content);
}

class _Circle extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _Circle(this.center, this.radius);

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_Circle old) =>
      old.center != center || old.radius != radius;
}

/// A widget in a screen that could be featured: its type, the first text in
/// it, where it is in the screen, and a [Pick] that finds it.
class ScreenPart {
  /// Its type, as the app names it.
  final String name;

  /// The first text inside it.
  final String? text;

  /// Where it is in its screen, in the screen's own units.
  final Rect rect;

  /// Dart that picks it: paste into a `lift:` or `Tap(where:)`.
  final String pick;

  /// An entry.
  const ScreenPart({
    required this.name,
    required this.text,
    required this.rect,
    required this.pick,
  });

  /// As JSON.
  Map<String, Object?> toJson() => {
    'name': name,
    'text': text,
    'rect': [rect.left, rect.top, rect.width, rect.height],
    'pick': pick,
  };
}

class _SweepPainter extends CustomPainter {
  final Sweep sweep;
  final Duration t;
  final double radius;

  const _SweepPainter(this.sweep, this.t, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress(t, sweep.at, sweep.at + sweep.length, curve: Ease.inOut);
    if (p <= 0) return;
    final fade =
        1 -
        progress(
          t,
          sweep.at + sweep.length,
          sweep.at + sweep.length + const Duration(milliseconds: 350),
        );
    if (fade <= 0) return;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
    );
    final y = size.height * p;
    // The glow it leaves behind, fading upward.
    final trail = Rect.fromLTRB(0, y - size.height * 0.35, size.width, y);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sweep.color.withValues(alpha: 0),
            sweep.color.withValues(alpha: 0.28 * fade),
          ],
        ).createShader(trail),
    );
    // The line itself, with a soft halo.
    canvas.drawRect(
      Rect.fromLTRB(0, y - 6, size.width, y + 6),
      Paint()
        ..color = sweep.color.withValues(alpha: 0.35 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, y - 1.5, size.width, y + 1.5),
      Paint()..color = sweep.color.withValues(alpha: fade),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.t != t;
}
