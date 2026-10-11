import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'time.dart';

/// Picks a widget in a screen as drawn.
///
/// ```dart
/// Pick((w) => w is WalletSummaryCard && w.members.isNotEmpty)
/// Pick.type<SayItTranscript>()
/// Pick.typeName('_Answer')              // a private widget
/// Pick.text('Done')                     // a Text or RichText
/// Pick.type<AppCard>().containing(Pick.text('Total'))
/// Pick.type<SayItRow>().nth(1)
/// ```
///
/// Without [inner], the first match in the tree wins (or the [index]th).
/// With it, the innermost match that has [inner] somewhere inside it wins:
/// the card around a label, not the page around the card.
class Pick {
  /// Whether a widget matches.
  final bool Function(Widget widget) test;

  /// Something the match must contain.
  final Pick? inner;

  /// Which match, counting from 0 in tree order.
  final int index;

  /// A pick by any test.
  const Pick(this.test, {this.inner, this.index = 0});

  /// Widgets of type [T].
  static Pick type<T>() => Pick((w) => w is T);

  /// Widgets whose type is called [name], private ones included.
  static Pick typeName(String name) =>
      Pick((w) => w.runtimeType.toString() == name);

  /// Text that is [text], or contains it with [contains], ignoring case
  /// with [anyCase].
  static Pick text(String text, {bool contains = false, bool anyCase = false}) {
    bool same(String s) {
      final a = anyCase ? s.toLowerCase() : s;
      final b = anyCase ? text.toLowerCase() : text;
      return contains ? a.contains(b) : a == b;
    }

    return Pick(
      (w) =>
          (w is Text && same(w.data ?? w.textSpan?.toPlainText() ?? '')) ||
          (w is RichText && same(w.text.toPlainText())),
    );
  }

  /// The widget with [key].
  static Pick key(Key key) => Pick((w) => w.key == key);

  /// This pick, but only matches with [inner] inside them; the innermost
  /// wins.
  Pick containing(Pick inner) => Pick(test, inner: inner, index: index);

  /// This pick's [n]th match, from 0.
  Pick nth(int n) => Pick(test, inner: inner, index: n);
}

/// A phone's screen: its size in logical units, its corner radius, and what
/// its system bars cover.
class Device {
  /// The screen, in logical units.
  final Size size;

  /// The screen's corner radius.
  final double radius;

  /// What the status bar and home indicator cover.
  final EdgeInsets padding;

  /// Whether it is drawn as a phone: a shadow, corners, an edge. A piece of
  /// the app shown on its own has none ([Device.bare]).
  final bool frame;

  /// A device.
  const Device(
    this.size, {
    required this.radius,
    required this.padding,
    this.frame = true,
  });

  /// No phone at all: a box of [size] that a piece of the app — a button, a
  /// card, a spinner — is laid out in, drawn on the ground as it is.
  const Device.bare(Size size)
    : this(size, radius: 0, padding: EdgeInsets.zero, frame: false);

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

/// Thickness for a layer, so it reads as a slab of glass when it turns:
/// [slices] copies of its outline, [depth] units deep behind it, in [color].
class Glass {
  /// How thick, in world units.
  final double depth;

  /// The edge's colour.
  final Color color;

  /// How many outlines draw the edge. More is smoother and slower.
  final int slices;

  /// A slab.
  const Glass({
    this.depth = 10,
    this.color = const Color(0x55FFFFFF),
    this.slices = 5,
  });
}

/// Any widget, placed in 3D: centred at [position] in the world, then moved
/// by its [motion].
///
/// A layer made with [Layer.screen] is one of the app's real screens: the
/// reel's host wraps it in the app's theme, fonts and demo data, it is drawn
/// at [Device.size] and clipped to the device's corners, and it can be acted
/// on — parts of it [lifts] off, a finger [taps] it, it [scrolls], text is
/// [typing] into it.
class Layer {
  /// The widget.
  final Widget child;

  /// The box it is laid out in.
  final Size size;

  /// Its centre, in world units from the world's centre.
  final Offset position;

  /// How it moves over its scene's time.
  final Motion motion;

  /// The device, for a screen; null for any other widget.
  final Device? device;

  /// Parts of the screen that leave it as layers of their own.
  final List<Lift> lifts;

  /// Fingers touching the screen.
  final List<Tap> taps;

  /// Scrolling the screen's scrollables.
  final List<Scroll> scrolls;

  /// Text typed into the screen's fields.
  final List<TypeText> typing;

  /// Drawn over the top of a screen, under its corners: the status bar.
  final Widget? statusBar;

  /// Stays on its course through the transition out of its scene instead of
  /// leaving with the rest of it.
  final bool carry;

  /// Thickness, so it reads as a slab when it turns.
  final Glass? glass;

  /// Corner radius, for its glass edge and shadow.
  final double radius;

  /// Builds the widget afresh for each moment of its scene, for widgets
  /// that animate by a value — a logo assembling, a number counting up.
  final Widget Function(Duration t)? builder;

  /// Stays out of the camera's depth of field: blurred only by its own
  /// motion. For set pieces — a floor, a frame — that should stay crisp.
  final bool ignoreFocus;

  /// A widget in 3D.
  Layer(
    this.child, {
    required this.size,
    this.position = Offset.zero,
    Motion? motion,
    this.carry = false,
    this.glass,
    this.radius = 0,
    this.ignoreFocus = false,
  }) : motion = motion ?? Motion(),
       builder = null,
       device = null,
       lifts = const [],
       taps = const [],
       scrolls = const [],
       typing = const [],
       statusBar = null;

  /// A widget built from its scene's clock each frame: `builder(t)`.
  Layer.timed(
    Widget Function(Duration t) this.builder, {
    required this.size,
    this.position = Offset.zero,
    Motion? motion,
    this.carry = false,
    this.glass,
    this.radius = 0,
    this.ignoreFocus = false,
  }) : motion = motion ?? Motion(),
       child = const SizedBox.shrink(),
       device = null,
       lifts = const [],
       taps = const [],
       scrolls = const [],
       typing = const [],
       statusBar = null;

  /// One of the app's screens, as the host draws it, on [device].
  Layer.screen(
    this.child, {
    this.device = Device.iphone,
    this.position = Offset.zero,
    Motion? motion,
    this.lifts = const [],
    this.taps = const [],
    this.scrolls = const [],
    this.typing = const [],
    this.statusBar,
    this.carry = false,
    this.glass,
  }) : size = device!.size,
       radius = device.radius,
       builder = null,
       ignoreFocus = false,
       motion = motion ?? Motion();

  /// A piece of the app on its own — a button, a card, a spinner — at
  /// [size], with no phone around it. The host draws it as it draws a
  /// screen (the app's theme, fonts and demo data), so it can be tapped,
  /// typed into and lifted like one.
  Layer.component(
    Widget child, {
    required Size size,
    Offset position = Offset.zero,
    Motion? motion,
    List<Lift> lifts = const [],
    List<Tap> taps = const [],
    List<TypeText> typing = const [],
    bool carry = false,
  }) : this.screen(
         child,
         device: Device.bare(size),
         position: position,
         motion: motion,
         lifts: lifts,
         taps: taps,
         typing: typing,
         carry: carry,
       );

  /// Whether this is an app screen, or a piece of the app on its own.
  bool get isScreen => device != null;
}

/// A part of a screen that comes off it toward the camera as its own layer:
/// the real widget, found in the screen as drawn, cloned and placed exactly
/// over where it was, then moved by [motion] — `z` is its height above the
/// screen.
///
/// What it leaves behind is [hole] — the page colour, usually — and a shadow
/// on the screen that spreads and softens as it rises.
class Lift {
  /// Picks the widget to lift.
  final Pick where;

  /// How it moves, from where it sat. It does not fade when its screen does.
  final Motion motion;

  /// Drawn where the widget was, under its shadow. Null leaves the original
  /// in place.
  final Widget? hole;

  /// The lifted widget's corner radius, for its shadow and glass.
  final double radius;

  /// How dark the shadow is when fully risen, 0 to 1.
  final double shadow;

  /// The height at which the shadow is at its darkest.
  final double shadowHeight;

  /// Stays on its course through the transition out of its scene.
  final bool carry;

  /// Thickness, so it reads as a slab when it turns.
  final Glass? glass;

  /// A scan line passing over it, as if it were being read.
  final Sweep? sweep;

  /// A lift.
  Lift({
    required this.where,
    Motion? motion,
    this.hole,
    this.radius = 24,
    this.shadow = 0.35,
    this.shadowHeight = 140,
    this.carry = false,
    this.glass,
    this.sweep,
  }) : motion = motion ?? Motion();
}

/// A scan line that passes down over a lifted widget from [at], taking
/// [length], with a glow trailing behind it: the widget being read.
class Sweep {
  /// When the line starts at the top.
  final Duration at;

  /// How long it takes to reach the bottom.
  final Duration length;

  /// Its colour.
  final Color color;

  /// A sweep.
  const Sweep({
    required this.at,
    this.length = const Duration(milliseconds: 1100),
    this.color = const Color(0xFFFFD97A),
  });
}

/// A fingertip touching a widget in a screen: it arrives, presses at [at],
/// ripples, and leaves.
///
/// With [press] set, the press is real: the renderer taps the app at that
/// moment, so a switch flips or a sheet opens exactly as it would on a
/// phone. Leave it off for anything that navigates through a router the
/// host does not have.
class Tap {
  /// Picks the widget to touch.
  final Pick where;

  /// When it presses.
  final Duration at;

  /// Whether the app receives the tap.
  final bool press;

  /// Where on the widget, as an alignment.
  final Alignment point;

  /// The sound cue at the press, or null for none.
  final String? sound;

  /// A tap.
  const Tap({
    required this.where,
    required this.at,
    this.press = false,
    this.point = Alignment.center,
    this.sound = 'tap',
  });

  /// When the finger first appears.
  Duration get arrives => at - 450.ms;

  /// When it has gone.
  Duration get leaves => at + 650.ms;
}

/// Scrolls a scrollable in a screen to [offset] over time — the real
/// scrollable, so lists build what scrolls into view.
class Scroll {
  /// Picks the scrollable. Defaults to the first vertical one.
  final Pick where;

  /// The scroll offset over the scene's time.
  final Track offset;

  /// A scroll.
  Scroll({Pick? where, required this.offset})
    : where = where ?? Pick(_vertical);

  static bool _vertical(Widget w) =>
      w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical;
}

/// Types [text] into a real text field in a screen, a character every
/// [perCharacter] from [at].
class TypeText {
  /// Picks the field: an `EditableText` or anything above one.
  final Pick where;

  /// What is typed.
  final String text;

  /// When typing starts.
  final Duration at;

  /// Time between characters.
  final Duration perCharacter;

  /// The sound cue per character, or null for none.
  final String? sound;

  /// Typing.
  TypeText({
    Pick? where,
    required this.text,
    required this.at,
    this.perCharacter = const Duration(milliseconds: 55),
    this.sound,
  }) : where = where ?? Pick.type<EditableText>();

  /// How much has been typed at [t].
  String typedAt(Duration t) {
    if (t < at) return '';
    final n = (t - at).inMicroseconds ~/ perCharacter.inMicroseconds + 1;
    return text.substring(0, n.clamp(0, text.length));
  }

  /// When the last character lands.
  Duration get done => at + perCharacter * (text.length - 1);
}
