import 'package:flutter/widgets.dart';

import 'time.dart';

/// A phone's screen: its size in logical units, its corner radius, and what
/// its system bars cover.
class Device {
  /// The screen, in logical units.
  final Size size;

  /// The screen's corner radius.
  final double radius;

  /// What the status bar and home indicator cover.
  final EdgeInsets padding;

  /// A device.
  const Device(this.size, {required this.radius, required this.padding});

  /// A 6.1-inch iPhone with a Dynamic Island: 393×852.
  static const iphone = Device(
    Size(393, 852),
    radius: 55,
    padding: EdgeInsets.only(top: 59, bottom: 34),
  );

  /// What a screen drawn on this device reads from [MediaQuery].
  MediaQueryData get media => MediaQueryData(
    size: size,
    devicePixelRatio: 3,
    padding: padding,
    viewPadding: padding,
    textScaler: TextScaler.noScaling,
  );
}

/// Any widget, placed in 3D: centred at [position] in the world, [z] units
/// toward the camera.
///
/// A layer made with [Layer.screen] is one of the app's real screens: the
/// reel's host wraps it in the app's theme, fonts and demo data, it is drawn
/// at [Device.size] and clipped to the device's corners, and parts of it can
/// [lifts] off it as layers of their own.
class Layer {
  /// The widget.
  final Widget child;

  /// The box it is laid out in.
  final Size size;

  /// Its centre, in world units from the world's centre.
  final Offset position;

  /// Depth over time, toward the camera.
  final Track z;

  /// Opacity over time.
  final Track opacity;

  /// Blur over time, on top of what the camera's focus gives it.
  final Track blur;

  /// The device, for a screen; null for any other widget.
  final Device? device;

  /// Parts of the screen that leave it as layers of their own.
  final List<Lift> lifts;

  /// Drawn over the top of a screen, under its corners: the status bar.
  final Widget? statusBar;

  /// A widget in 3D.
  Layer(
    this.child, {
    required this.size,
    this.position = Offset.zero,
    Track? z,
    Track? opacity,
    Track? blur,
  }) : z = z ?? Track.constant(0),
       opacity = opacity ?? Track.constant(1),
       blur = blur ?? Track.constant(0),
       device = null,
       lifts = const [],
       statusBar = null;

  /// One of the app's screens, as the host draws it, on [device].
  Layer.screen(
    this.child, {
    this.device = Device.iphone,
    this.position = Offset.zero,
    this.lifts = const [],
    this.statusBar,
    Track? z,
    Track? opacity,
    Track? blur,
  }) : size = device!.size,
       z = z ?? Track.constant(0),
       opacity = opacity ?? Track.constant(1),
       blur = blur ?? Track.constant(0);

  /// Whether this is an app screen.
  bool get isScreen => device != null;
}

/// A part of a screen that comes off it toward the camera as its own layer:
/// the real widget, found in the screen as drawn, cloned and placed exactly
/// over where it was.
///
/// What it leaves behind is [hole] — the page colour, usually — and a shadow
/// on the screen that spreads and softens as it rises.
class Lift {
  /// Picks the widget to lift. The first match in the screen wins.
  final bool Function(Widget widget) where;

  /// Height above the screen over time.
  final Track z;

  /// Extra scale over time, around the lifted widget's centre.
  final Track scale;

  /// Opacity over time. A lifted widget has left its screen, so it does not
  /// fade when the screen does.
  final Track opacity;

  /// Drawn where the widget was, under its shadow. Null leaves the original
  /// in place.
  final Widget? hole;

  /// The lifted widget's corner radius, for its shadow.
  final double radius;

  /// How dark the shadow is when fully risen, 0 to 1.
  final double shadow;

  /// The height at which the shadow is at its darkest.
  final double shadowHeight;

  /// A lift.
  Lift({
    required this.where,
    required this.z,
    Track? scale,
    Track? opacity,
    this.hole,
    this.radius = 24,
    this.shadow = 0.35,
    this.shadowHeight = 140,
  }) : scale = scale ?? Track.constant(1),
       opacity = opacity ?? Track.constant(1);
}

/// One or more words arriving on screen, drawn flat over the world.
///
/// Letters rise into place from under a line, one after another, [stagger]
/// apart, each taking [rise]. The part matching [highlight] takes [accent].
class Words {
  /// The words.
  final String text;

  /// When the first letter starts to rise.
  final Duration at;

  /// When they leave, or null to stay.
  final Duration? until;

  /// Their style. A display face, large.
  final TextStyle style;

  /// The part drawn in [accent].
  final String? highlight;

  /// The accent colour.
  final Color? accent;

  /// Where they sit inside the format's safe area.
  final Alignment align;

  /// Time between letters.
  final Duration stagger;

  /// Time each letter takes to rise.
  final Duration rise;

  /// Words.
  const Words(
    this.text, {
    required this.at,
    required this.style,
    this.until,
    this.highlight,
    this.accent,
    this.align = Alignment.bottomLeft,
    this.stagger = const Duration(milliseconds: 55),
    this.rise = const Duration(milliseconds: 700),
  });

  /// When the last letter has landed.
  Duration get landed => at + stagger * (text.length - 1) + rise;

  /// Seconds in, as a double, for logs.
  double get atSeconds => secondsOf(at);
}
