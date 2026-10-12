import 'dart:io';
import 'dart:ui' show PictureRecorder;

import 'package:blaq_reel/blaq_reel.dart';
import 'package:blaq_reel/packs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A card, the kind of thing a reel lifts.
class _Card extends StatelessWidget {
  final String label;
  final Widget? child;

  const _Card(this.label, {this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    color: const Color(0xFFFFFFFF),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Text(label), ?child],
    ),
  );
}

/// A screen with an outer card holding an inner card, a long list, and a
/// field.
class _Screen extends StatelessWidget {
  final TextEditingController field;

  const _Screen(this.field);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFEEEEEE),
    child: Column(
      children: [
        const _Card(
          'Outer',
          child: SizedBox(width: 300, child: _Card('Total')),
        ),
        SizedBox(
          height: 200,
          child: ListView(
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 40, child: Text('Row $i')),
            ],
          ),
        ),
        EditableText(
          controller: field,
          focusNode: FocusNode(),
          style: const TextStyle(fontSize: 14),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF888888),
        ),
      ],
    ),
  );
}

/// A field that keeps its own controller and shouts what it is given, the
/// way an app's formatted field does.
class _Shouty extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const _Shouty(this.onChanged);

  @override
  State<_Shouty> createState() => _ShoutyState();
}

class _ShoutyState extends State<_Shouty> {
  final controller = TextEditingController();
  final focus = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Card(
    'Name',
    child: SizedBox(
      width: 200,
      child: EditableText(
        controller: controller,
        focusNode: focus,
        style: const TextStyle(fontSize: 14),
        cursorColor: const Color(0xFF000000),
        backgroundCursorColor: const Color(0xFF888888),
        inputFormatters: [
          TextInputFormatter.withFunction(
            (_, next) => next.copyWith(text: next.text.toUpperCase()),
          ),
        ],
        onChanged: widget.onChanged,
      ),
    ),
  );
}

final host = ReelHost(
  wrap: (screen) => Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: screen,
    ),
  ),
);

void main() {
  const backdrop = Backdrop(top: Color(0xFF101010), bottom: Color(0xFF000000));

  Reel reel(TextEditingController field, {List<Lift> lifts = const []}) => Reel(
    name: 'test',
    backdrop: backdrop,
    format: const Format('small', Size(360, 640), pixelRatio: 1),
    scenes: [
      Scene(
        name: 'one',
        length: 2.s,
        camera: Camera.still(const CameraPose(zoom: 0.5)),
        layers: [
          Layer.screen(
            _Screen(field),
            lifts: lifts,
            scrolls: [Scroll(offset: Track.from(0).to(1.s, 400, Ease.linear))],
            typing: [TypeText(text: 'Hello', at: 0.s, perCharacter: 100.ms)],
          ),
        ],
      ),
    ],
  );

  testWidgets('Given a pick containing text, when mounted, then the '
      'innermost card around it lifts', (tester) async {
    final field = TextEditingController();
    final r = ReelRenderer(
      tester,
      reel(
        field,
        lifts: [
          Lift(
            where: Pick.type<_Card>().containing(Pick.text('Total')),
            motion: Motion(z: Track.constant(80)),
          ),
        ],
      ),
      host: host,
    );
    await r.mount();
    await r.seek(500.ms);

    // The inner card is drawn twice: in its screen, and lifted.
    expect(find.text('Total', skipOffstage: false), findsNWidgets(2));
    // The outer card was not lifted.
    expect(find.text('Outer', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Given a pick that matches nothing, when mounted, then it '
      'says which lift', (tester) async {
    final r = ReelRenderer(
      tester,
      reel(TextEditingController(), lifts: [Lift(where: Pick.text('Nowhere'))]),
      host: host,
    );
    StateError? error;
    try {
      await r.mount();
    } on StateError catch (e) {
      error = e;
    }
    expect(error?.message, contains('one/layer 0/lift 0'));
  });

  testWidgets('Given a scroll and typing, when the clock moves, then the '
      'real list scrolls and the real field fills', (tester) async {
    final field = TextEditingController();
    final r = ReelRenderer(tester, reel(field), host: host);
    await r.mount();
    await r.seek(500.ms);
    final list = tester.state<ScrollableState>(
      find.byType(Scrollable, skipOffstage: false).first,
    );
    expect(list.position.pixels, closeTo(200, 1));
    expect(field.text, 'Hello');

    await r.seek(1.s);
    expect(list.position.pixels, closeTo(400, 1));
  });

  testWidgets('Given a reel, when a still is saved, then it is a PNG at the '
      'format size', (tester) async {
    final dir = Directory.systemTemp.createTempSync('blaq_reel');
    addTearDown(() => dir.deleteSync(recursive: true));
    final r = ReelRenderer(tester, reel(TextEditingController()), host: host);
    await r.mount();
    final path = '${dir.path}/still.png';
    await r.still(1.s, path);
    final bytes = File(path).readAsBytesSync();
    // PNG signature, then the IHDR width and height.
    expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
    final data = bytes.buffer.asByteData();
    expect(data.getUint32(16), 360);
    expect(data.getUint32(20), 640);
  });

  testWidgets('Given a Glass Layers pack, when built for each format, then '
      'it lays out without errors', (tester) async {
    for (final format in Format.all) {
      final built = GlassLayers(
        brand: const Brand(
          ink: Color(0xFF111111),
          accent: Color(0xFFFFD97A),
          paper: Color(0xFFF5F5F5),
          display: 'Ahem',
          text: 'Ahem',
        ),
        format: format,
        open: (t) => const SizedBox(width: 50, height: 50),
        beats: [
          GlassBeat('One.', screen: _Screen(TextEditingController())),
          GlassBeat('Two.', screen: _Screen(TextEditingController())),
        ],
        end: GlassEnd(
          logo: (t) => const SizedBox(width: 80, height: 20),
          logoSize: const Size(80, 20),
          line: 'A line.',
        ),
      ).build('glass');
      expect(built.scenes, hasLength(4));
      final r = ReelRenderer(tester, built, host: host);
      await r.mount();
      for (final t in [
        0.5,
        3.0,
        6.0,
        built.length.inMilliseconds / 1000 - 0.1,
      ]) {
        await r.seek(t.s);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Given every other pack, when built for each format, then it '
      'lays out without errors', (tester) async {
    const brand = Brand(
      ink: Color(0xFF111111),
      accent: Color(0xFFFFD97A),
      paper: Color(0xFFF5F5F5),
      display: 'Ahem',
      text: 'Ahem',
    );
    Widget screen() => _Screen(TextEditingController());
    Widget logo(Duration t) => const SizedBox(width: 80, height: 20);
    for (final format in Format.all) {
      final reels = [
        KineticLaunch(
          brand: brand,
          format: format,
          beats: [
            KineticBeat('One {two}.', screen: screen()),
            const KineticBeat('Words {alone}.'),
          ],
          logo: logo,
          line: 'A {line}.',
          url: 'example.com',
        ).build('kinetic'),
        DarkGlow(
          brand: brand,
          format: format,
          stops: [
            GlowStop(screen: screen(), title: 'One', line: 'First.'),
            GlowStop(screen: screen(), title: 'Two'),
          ],
          logo: logo,
        ).build('glow'),
        StoryAd(
          brand: brand,
          format: format,
          hook: const ['Who {paid}?'],
          problem: const ['It gets {awkward}.'],
          meet: logo,
          beats: [GlassBeat('One.', screen: screen())],
          proof: const ['{True} things only.'],
          end: GlassEnd(logo: logo, logoSize: const Size(80, 20)),
          voice: const {'hook': StoryVoice('hook.m4a', 'Who paid?')},
        ).build('story'),
      ];
      for (final reel in reels) {
        final r = ReelRenderer(tester, reel, host: host);
        await r.mount();
        final end = reel.length.inMilliseconds / 1000;
        for (var t = 0.25; t < end; t += 1.5) {
          await r.seek(t.s);
        }
        expect(tester.takeException(), isNull, reason: reel.name);
      }
    }
  });

  test('Given a Story Ad with voice, then each line sits on its part', () {
    final reel = StoryAd(
      brand: const Brand(
        ink: Color(0xFF111111),
        accent: Color(0xFFFFD97A),
        paper: Color(0xFFF5F5F5),
        display: 'Ahem',
        text: 'Ahem',
      ),
      hook: const ['One.', 'Two.'],
      meet: (t) => const SizedBox(),
      beats: const [],
      end: GlassEnd(logo: (t) => const SizedBox(), logoSize: Size.zero),
      voice: const {
        'meet': StoryVoice('meet.m4a', 'Meet it.', delay: Duration.zero),
      },
    ).build('story');
    final meet = reel.timeline.firstWhere((s) => s.scene.name == 'meet');
    expect(reel.soundtrack.voice.single.at, meet.start);
  });

  test('Given a beat with its own look, then its scene paints that ground', () {
    const brand = Brand(
      ink: Color(0xFF111111),
      accent: Color(0xFFFFD97A),
      paper: Color(0xFFF5F5F5),
      display: 'Ahem',
      text: 'Ahem',
    );
    final glass = GlassLayers(
      brand: brand,
      look: GlassLook.mesh,
      beats: const [
        GlassBeat('Same.', screen: SizedBox()),
        GlassBeat('Own.', screen: SizedBox(), look: GlassLook.butter),
      ],
    );
    final reel = glass.build('looks');
    expect(reel.scenes[0].backdrop, isNull);
    expect(
      reel.scenes[1].backdrop!.top,
      glass.backdropOf(GlassLook.butter).top,
    );
  });

  testWidgets('Given a screen, when mapped, then each card is listed with a '
      'pick that finds it', (tester) async {
    final r = ReelRenderer(tester, reel(TextEditingController()), host: host);
    await r.mount();
    await r.seek(100.ms);
    final stage = tester.state<ReelStageState>(find.byType(ReelStage));
    final parts = stage.mapScreen((0, 0));
    expect(parts.map((p) => p.text), containsAll(['Outer', 'Total']));
    final total = parts.firstWhere((p) => p.text == 'Total');
    expect(total.rect.width, greaterThan(0));
    expect(total.pick, contains('Total'));
  });

  testWidgets('Given a component pressed in a Glass Layers beat, when the '
      'clock passes the press, then the real widget was tapped and it took '
      'its pending work with it when closed', (tester) async {
    var presses = 0;
    final button = GestureDetector(
      onTap: () {
        presses++;
        // Work a button waits on: it must not outlive the render.
        Future<void>.delayed(const Duration(seconds: 2));
      },
      child: const _Card('Go'),
    );
    final reel = GlassLayers(
      brand: const Brand(
        ink: Color(0xFF111111),
        paper: Color(0xFFFFFFFF),
        accent: Color(0xFFFFD97A),
        display: 'Display',
        text: 'Text',
      ),
      format: const Format('small', Size(360, 640), pixelRatio: 1),
      beats: [
        GlassBeat(
          'Press.',
          screen: Center(child: button),
          piece: const Size(200, 80),
          taps: [Tap(where: Pick.type<_Card>(), at: 1.s, press: true)],
        ),
      ],
    ).build('piece');
    final r = ReelRenderer(tester, reel, host: host);
    await r.mount();
    for (var t = 0; t <= 1500; t += 100) {
      await r.seek(Duration(milliseconds: t));
    }
    expect(presses, 1);
    final layer = reel.scenes.single.layers.last;
    expect(layer.device?.frame, isFalse);
    await r.close();
  });

  testWidgets('Given a lifted field with typing, when the clock passes it, '
      'then each key goes through the field as a keyboard\'s would, the '
      'lifted copy shows it too, and going back types it again', (
    tester,
  ) async {
    final changes = <String>[];
    final reel = GlassLayers(
      brand: const Brand(
        ink: Color(0xFF111111),
        paper: Color(0xFFFFFFFF),
        accent: Color(0xFFFFD97A),
        display: 'Display',
        text: 'Text',
      ),
      format: const Format('small', Size(360, 640), pixelRatio: 1),
      beats: [
        GlassBeat(
          'Type.',
          screen: Center(child: _Shouty(changes.add)),
          lift: [Pick.type<_Card>()],
          partMoves: [
            PartMove(
              typing: PartTyping('abc', at: 3200.ms, every: 100.ms),
            ),
          ],
        ),
      ],
    ).build('vertical');
    final r = ReelRenderer(tester, reel, host: host);
    await r.mount();
    for (var t = 0; t <= 3600; t += 100) {
      await r.seek(Duration(milliseconds: t));
    }
    final shown = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((e) => e.controller.text)
        .toList();
    expect(shown, hasLength(2));
    expect(shown, everyElement('ABC'));
    expect(changes.toSet(), {'A', 'AB', 'ABC'});

    await r.seek(3300.ms);
    final again = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((e) => e.controller.text);
    expect(again, everyElement('AB'));
    await r.close();
  });

  test('Given a reel at a pace, then it plays shorter, its moments come '
      'sooner in the video, and its description is on the video\'s clock', () {
    final reel = Reel.single(
      name: 'paced',
      length: 4.s,
      backdrop: backdrop,
      camera: Camera.still(const CameraPose()),
      cues: [Cue(2.s, 'tap')],
    ).withPace(1.25);
    expect(reel.playedLength, 3200.ms);
    expect(reel.played(2.s), 1600.ms);
    expect(reel.atVideo(1600.ms), 2.s);
    final described = describeReel(reel);
    expect(described['length'], closeTo(3.2, 1e-9));
    expect((described['cues']! as List).single, {'at': 1.6, 'sound': 'tap'});
    expect(described['pace'], 1.25);
  });

  test(
    'Given a reel with steady scenes at either end, when paced to a '
    'length, then they keep their own and the scenes between take the rest',
    () {
      Scene scene(String name, Duration l) => Scene(
        name: name,
        length: l,
        camera: Camera.still(const CameraPose()),
      );
      final reel = Reel(
        name: 'steady',
        backdrop: backdrop,
        scenes: [
          scene('open', 2.s),
          scene('a', 4.s),
          scene('b', 4.s),
          scene('end', 3.s),
        ],
      ).withPace(1, steady: {'open', 'end'});
      expect(reel.length, 13.s);
      final paced = reel.withPace(reel.paceFor(9.s));
      expect(paced.pace, closeTo(2, 1e-9));
      expect(paced.playedLength, 9.s);
      expect(paced.played(1.s), 1.s);
      expect(paced.played(6.s), 4.s);
      expect(paced.played(12.s), 8.s);
      expect(paced.atVideo(4.s), 6.s);
      expect(paced.atVideo(8.s), 12.s);
    },
  );

  test('Given a spec part with its own move, when read, then every setting '
      'comes through and the rest is left to the beat\'s move', () {
    final own = PartMove.fromJson({
      'type': 'AppCard',
      'to': [-90, -250],
      'z': 200,
      'turn': 12,
      'delay': 400,
      'rise': 900,
      'scan': true,
      'typing': {'text': '186', 'every': 120},
      'layer': 2,
    })!;
    expect(own.to, const Offset(-90, -250));
    expect(own.z, 200);
    expect(own.turn, 12);
    expect(own.delay, const Duration(milliseconds: 400));
    expect(own.rise, const Duration(milliseconds: 900));
    expect(own.scan, isTrue);
    expect(own.typing?.text, '186');
    expect(own.typing?.every, const Duration(milliseconds: 120));
    expect(own.typing?.at, isNull);
    expect(own.layer, 2);
    expect(own.scale, isNull);
    expect(PartMove.fromJson({'type': 'AppCard', 'text': 'Total'}), isNull);
  });

  test('Given a beat with its own words over the reel\'s, when built, then '
      'the beat\'s win, the reel\'s fill the rest, and they sit where set', () {
    const brand = Brand(
      ink: Color(0xFF111111),
      accent: Color(0xFFFFD97A),
      paper: Color(0xFFF5F5F5),
      display: 'Ahem',
      text: 'Ahem',
    );
    final reel = GlassLayers(
      brand: brand,
      format: const Format('small', Size(360, 640), pixelRatio: 1),
      words: const GlassWords(color: Color(0xFF2B4BFF), size: 96),
      beats: [
        GlassBeat(
          'Share it all.',
          screen: const SizedBox(),
          words: const GlassWords(
            color: Color(0xFFFF0000),
            anchor: Alignment.topCenter,
            offset: Offset(0, 0.04),
            width: 0.7,
            plate: Color(0xFFFFF8EC),
            behind: true,
          ),
        ),
      ],
    ).build('words');
    final w = reel.scenes.single.words.single;
    expect(w.style.color, const Color(0xFFFF0000));
    expect(w.style.fontSize, 96);
    expect(w.align, Alignment.topCenter);
    expect(w.textAlign, TextAlign.center);
    expect(w.offset, const Offset(0, 0.04));
    expect(w.maxWidth, 0.7);
    expect(w.fit, isFalse);
    expect(w.plate, const Color(0xFFFFF8EC));
    expect(w.behind, isTrue);
  });

  test('Given words that wrap, when a word is longer than a line, then the '
      'type shrinks until it fits rather than breaking the word', () {
    const words = Words(
      'Extraordinarily long.',
      at: Duration.zero,
      style: TextStyle(fontSize: 100, fontFamily: 'Ahem'),
    );
    final sized = words.fitted(300);
    final widest = (TextPainter(
      text: TextSpan(text: 'Extraordinarily', style: sized.style),
      textDirection: TextDirection.ltr,
    )..layout()).width;
    expect(sized.style.fontSize, lessThan(100));
    expect(widest, lessThanOrEqualTo(300));
  });

  test('Given a ground of each pattern, light and dark, when painted, then it '
      'draws without error', () {
    for (final pattern in GroundPattern.values) {
      for (final light in [true, false]) {
        final recorder = PictureRecorder();
        BackdropPainter(
          Backdrop(
            top: const Color(0xFF14121F),
            bottom: const Color(0xFF07060C),
            light: light,
            motion: GroundMotion(
              pattern: pattern,
              colours: const [
                Color(0xFF7B6CF6),
                Color(0xFFFFD97A),
                Color(0xFF2E8BFF),
              ],
              light: light,
              bpm: 120,
            ),
          ),
          const Duration(milliseconds: 1500),
        ).paint(Canvas(recorder), const Size(360, 640));
        recorder.endRecording().dispose();
      }
    }
  });
}
