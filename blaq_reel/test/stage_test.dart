import 'dart:io';

import 'package:blaq_reel/blaq_reel.dart';
import 'package:blaq_reel/packs.dart';
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

  test('Given a spec part with its own move, when read, then every setting '
      'comes through and the rest is left to the beat\'s move', () {
    final own = PartMove.fromJson({
      'type': 'AppCard',
      'to': [-90, -250],
      'z': 200,
      'turn': 12,
      'delay': 400,
      'scan': true,
    })!;
    expect(own.to, const Offset(-90, -250));
    expect(own.z, 200);
    expect(own.turn, 12);
    expect(own.delay, const Duration(milliseconds: 400));
    expect(own.scan, isTrue);
    expect(own.scale, isNull);
    expect(PartMove.fromJson({'type': 'AppCard', 'text': 'Total'}), isNull);
  });
}
