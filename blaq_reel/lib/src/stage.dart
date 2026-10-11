import 'dart:ui' show ImageFilter, TileMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'backdrop.dart';
import 'camera.dart';
import 'layer.dart';
import 'reel.dart';
import 'words_painter.dart';

/// Draws a [Reel] at the moment [time] holds.
///
/// Everything on the stage is a function of that moment, so the same moment
/// always draws the same frame. The app's own screens are built once and
/// never rebuilt by the clock: only the transforms, blurs and opacities
/// around them change.
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

/// The stage's state: which lifted widgets have been found in their screens.
class ReelStageState extends State<ReelStage> {
  /// Clear space kept around a lifted widget, so its own shadow is not cut
  /// off by the host's app around it.
  static const _liftPad = 24.0;

  late final List<GlobalKey> _keys;
  late final List<Widget> _contents;
  final Map<(int, int), _Lifted> _lifted = {};

  /// Whether every [Lift] has been found and cloned.
  bool get lifted =>
      _lifted.length ==
      widget.reel.layers.fold<int>(0, (n, l) => n + l.lifts.length);

  @override
  void initState() {
    super.initState();
    final layers = widget.reel.layers;
    _keys = [for (var i = 0; i < layers.length; i++) GlobalKey()];
    _contents = [
      for (final layer in layers)
        layer.isScreen
            ? MediaQuery(
                data: layer.device!.media,
                child: widget.host.wrap(layer.child),
              )
            : layer.child,
    ];
    if (!lifted) WidgetsBinding.instance.addPostFrameCallback(_findLifts);
  }

  /// Looks for each lifted widget in its screen as drawn, and clones it,
  /// with its place in the screen, once it is laid out.
  void _findLifts(Duration _) {
    if (!mounted) return;
    var found = false;
    final layers = widget.reel.layers;
    for (var i = 0; i < layers.length; i++) {
      final root = _keys[i].currentContext;
      if (root is! Element) continue;
      final rootBox = root.findRenderObject();
      if (rootBox is! RenderBox || !rootBox.hasSize) continue;
      for (var j = 0; j < layers[i].lifts.length; j++) {
        if (_lifted.containsKey((i, j))) continue;
        final lift = layers[i].lifts[j];
        Element? match;
        void visit(Element e) {
          if (match != null) return;
          if (lift.where(e.widget)) {
            match = e;
            return;
          }
          e.visitChildren(visit);
        }

        root.visitChildren(visit);
        final box = match?.findRenderObject();
        if (box is! RenderBox || !box.hasSize) continue;
        final rect = MatrixUtils.transformRect(
          box.getTransformTo(rootBox),
          Offset.zero & box.size,
        );
        _lifted[(i, j)] = _Lifted(
          rect,
          MediaQuery(
            data: layers[i].device?.media ?? MediaQuery.of(context),
            child: widget.host.wrap(
              Padding(
                padding: const EdgeInsets.all(_liftPad),
                child: SizedBox.fromSize(size: rect.size, child: match!.widget),
              ),
            ),
          ),
        );
        found = true;
      }
    }
    if (found) setState(() {});
    if (!lifted) WidgetsBinding.instance.addPostFrameCallback(_findLifts);
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.reel.format.logical;
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
            builder: (context, t, _) => _frame(t, stage),
          ),
        ),
      ),
    );
  }

  Widget _frame(Duration t, Size stage) {
    final reel = widget.reel;
    final camera = reel.camera;
    final pose = camera.at(t);
    final world = <(double, int, Widget)>[];

    for (var i = 0; i < reel.layers.length; i++) {
      final layer = reel.layers[i];
      final z = layer.z.at(t);
      world.add((
        z,
        world.length,
        _place(
          key: ValueKey('layer $i'),
          camera: camera,
          pose: pose,
          stage: stage,
          size: layer.size,
          position: layer.position,
          z: z,
          opacity: layer.opacity.at(t),
          blur: layer.blur.at(t),
          child: layer.isScreen ? _screen(i, layer, t) : _contents[i],
        ),
      ));

      for (var j = 0; j < layer.lifts.length; j++) {
        final lifted = _lifted[(i, j)];
        if (lifted == null) continue;
        final lift = layer.lifts[j];
        final lz = z + lift.z.at(t);
        final box = lifted.rect.inflate(_liftPad);
        world.add((
          lz,
          world.length,
          _place(
            key: ValueKey('lift $i.$j'),
            camera: camera,
            pose: pose,
            stage: stage,
            size: box.size,
            position:
                layer.position +
                box.center -
                Offset(layer.size.width / 2, layer.size.height / 2),
            z: lz,
            opacity: lift.opacity.at(t),
            blur: 0,
            child: Transform.scale(
              scale: lift.scale.at(t),
              child: lifted.content,
            ),
          ),
        ));
      }
    }

    // Far things first. Ties keep the order they were added in.
    world.sort((a, b) {
      final byDepth = a.$1.compareTo(b.$1);
      return byDepth != 0 ? byDepth : a.$2.compareTo(b.$2);
    });

    final safe = reel.format.safe;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: BackdropPainter(reel.backdrop, t)),
        ),
        for (final (_, _, child) in world) child,
        for (final (k, words) in reel.words.indexed)
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
                  size: WordsPainter.layout(words).size,
                  painter: WordsPainter(words, t),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// A box of [size] placed in the world by the camera, softened by its
  /// distance from focus plus [blur].
  Widget _place({
    required Key key,
    required Camera camera,
    required CameraPose pose,
    required Size stage,
    required Size size,
    required Offset position,
    required double z,
    required double opacity,
    required double blur,
    required Widget child,
  }) {
    final sigma = pose.blurAt(z) + blur;
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
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: size.width,
                height: size.height,
                child: Transform(
                  transform: camera.project(
                    pose: pose,
                    stage: stage,
                    size: size,
                    position: position,
                    z: z,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A device screen: its shadow, the app clipped to its corners, the status
  /// bar, the holes and shadows its lifted widgets leave, and a glass edge.
  Widget _screen(int i, Layer layer, Duration t) {
    final device = layer.device!;
    final radius = BorderRadius.circular(device.radius);
    final shape = RoundedSuperellipseBorder(borderRadius: radius);

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: KeyedSubtree(key: _keys[i], child: _contents[i]),
                ),
                if (layer.statusBar != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: device.padding.top,
                    child: layer.statusBar!,
                  ),
                for (var j = 0; j < layer.lifts.length; j++)
                  if (_lifted[(i, j)] case final lifted?) ...[
                    if (layer.lifts[j].hole != null)
                      Positioned.fromRect(
                        rect: lifted.rect,
                        child: layer.lifts[j].hole!,
                      ),
                    _groundShadow(
                      layer.lifts[j],
                      lifted.rect,
                      layer.lifts[j].z.at(t),
                    ),
                  ],
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: radius,
                  side: const BorderSide(color: Color(0x47FFFFFF), width: 1.5),
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
}

class _Lifted {
  final Rect rect;
  final Widget content;

  const _Lifted(this.rect, this.content);
}
