import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
