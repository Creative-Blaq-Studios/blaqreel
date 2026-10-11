import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backdrop.dart';
import 'camera.dart';
import 'format.dart';
import 'layer.dart';

/// The one adapter an app writes: how to draw one of its screens with the
/// app's theme, fonts and demo data, and no backend.
///
/// Most apps already have this in their widget tests. [wrap] takes a screen
/// (or a widget lifted from one) and returns it ready to draw. [ready] runs
/// once after the reel is first pumped: load fonts, let images decode.
/// [settle] runs again once lifted widgets have been cloned, so their own
/// images decode too.
class ReelHost {
  /// Wraps a screen in the app.
  final Widget Function(Widget screen) wrap;

  /// Runs once the reel is mounted.
  final Future<void> Function(WidgetTester tester)? ready;

  /// Runs once lifted widgets are in place.
  final Future<void> Function(WidgetTester tester)? settle;

  /// A host.
  const ReelHost({required this.wrap, this.ready, this.settle});
}

/// A whole video: its format and length, what it sits on, the camera, the
/// layers in the world, and the words over it.
class Reel {
  /// A name, for file names.
  final String name;

  /// The frame.
  final Format format;

  /// Frames per second.
  final int fps;

  /// How long it runs.
  final Duration length;

  /// What the world sits on.
  final Backdrop backdrop;

  /// The camera.
  final Camera camera;

  /// The world's layers.
  final List<Layer> layers;

  /// Words over the world, flat to the frame.
  final List<Words> words;

  /// A reel.
  const Reel({
    required this.name,
    required this.length,
    required this.backdrop,
    required this.camera,
    this.format = Format.vertical,
    this.fps = 30,
    this.layers = const [],
    this.words = const [],
  });
}
