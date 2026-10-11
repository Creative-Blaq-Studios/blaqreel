import 'package:blaq_reel/blaq_reel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Scene _scene(String name, Duration length, {List<Layer> layers = const []}) =>
    Scene(
      name: name,
      length: length,
      camera: Camera.still(const CameraPose()),
      layers: layers,
      words: [
        Words(
          name,
          at: 500.ms,
          style: const TextStyle(fontSize: 10),
          sound: 'pop',
        ),
      ],
    );

void main() {
  const backdrop = Backdrop(top: Color(0xFF000000), bottom: Color(0xFF000000));

  group('Reel.timeline', () {
    test('Given cuts, when laid out, then scenes follow end to end', () {
      final reel = Reel(
        name: 'r',
        backdrop: backdrop,
        scenes: [_scene('a', 2.s), _scene('b', 3.s)],
      );
      expect(reel.timeline[1].start, 2.s);
      expect(reel.length, 5.s);
    });

    test('Given a transition, when laid out, then scenes overlap by it', () {
      final reel = Reel(
        name: 'r',
        backdrop: backdrop,
        scenes: [_scene('a', 2.s), _scene('b', 3.s), _scene('c', 1.s)],
        transitions: const [Transition.fade(length: Duration(seconds: 1))],
      );
      expect(reel.timeline[1].start, 1.s);
      expect(reel.timeline[2].start, 3.s);
      expect(reel.length, 4.s);
      expect(reel.timeline[1].enter!.kind, TransitionKind.fade);
      expect(reel.timeline[2].exit, isNull);
    });

    test('Given a fade, when halfway, then both scenes are half seen', () {
      final reel = Reel(
        name: 'r',
        backdrop: backdrop,
        scenes: [_scene('a', 2.s), _scene('b', 2.s)],
        transitions: const [Transition.fade(length: Duration(seconds: 1))],
      );
      const stage = Size(360, 640);
      expect(reel.timeline[0].effect(1500.ms, stage).opacity, 0.5);
      expect(reel.timeline[1].effect(1500.ms, stage).opacity, 0.5);
      expect(reel.timeline[0].leaving(1500.ms), isTrue);
    });

    test('Given a wipe, when it starts, then the next scene opens from 0', () {
      const wipe = Transition.wipe();
      expect(wipe.incoming(0, const Size(10, 10)).clip, 0);
      expect(wipe.incoming(1, const Size(10, 10)).clip, 1);
    });
  });

  group('Reel.cues', () {
    test('Given words, taps, typing and a swing, then each makes a cue', () {
      final reel = Reel(
        name: 'r',
        backdrop: backdrop,
        scenes: [
          _scene(
            'a',
            3.s,
            layers: [
              Layer.screen(
                const SizedBox(),
                taps: [Tap(where: Pick.text('Go'), at: 1.s)],
                typing: [TypeText(text: 'ab c', at: 2.s, sound: 'tick')],
              ),
            ],
          ),
          _scene('b', 3.s),
        ],
        transitions: const [Transition.swing()],
      );
      final sounds = [
        for (final c in reel.cues) '${c.sound}@${c.at.inMilliseconds}',
      ];
      expect(sounds, contains('tap@1000'));
      expect(sounds, contains('pop@500'));
      expect(sounds, contains('whoosh@2100'));
      expect(sounds.where((s) => s.startsWith('tick')), hasLength(3));
      expect(sounds, contains('pop@2600'));
    });
  });

  group('TypeText', () {
    test('Given typing, when partway, then that much is typed', () {
      final typing = TypeText(text: 'Hello', at: 1.s, perCharacter: 100.ms);
      expect(typing.typedAt(500.ms), '');
      expect(typing.typedAt(1.s), 'H');
      expect(typing.typedAt(1250.ms), 'Hel');
      expect(typing.typedAt(9.s), 'Hello');
    });
  });

  group('Words', () {
    test('Given braces, then they are taken out and mark the accent', () {
      const w = Words(
        'Split the {cart} bill',
        at: Duration.zero,
        style: TextStyle(),
      );
      expect(w.plain, 'Split the cart bill');
      expect(w.accents, [(10, 14)]);
    });

    test('Given a highlight, then it is an accent too', () {
      const w = Words(
        'Share.',
        at: Duration.zero,
        style: TextStyle(),
        highlight: '.',
      );
      expect(w.accents, [(5, 6)]);
    });

    test('Given words revealed by word, then they land per word', () {
      const w = Words(
        'One two three',
        at: Duration(seconds: 1),
        style: TextStyle(),
        reveal: Reveal.words,
        stagger: Duration(milliseconds: 100),
        rise: Duration(milliseconds: 500),
      );
      expect(w.landed, 1700.ms);
    });
  });
}
