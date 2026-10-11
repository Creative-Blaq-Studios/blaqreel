import 'package:blaq_reel/blaq_reel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String resolve(String s) => '/sfx/$s.wav';

  group('mixArgs', () {
    test('Given nothing to hear, then there is no mix', () {
      expect(
        mixArgs(
          video: 'v.mp4',
          out: 'o.mp4',
          length: 5.s,
          soundtrack: const Soundtrack(),
          cues: const [],
          resolve: resolve,
        ),
        isNull,
      );
    });

    test('Given cues, then each is delayed to its moment', () {
      final args = mixArgs(
        video: 'v.mp4',
        out: 'o.mp4',
        length: 5.s,
        soundtrack: const Soundtrack(cueGain: -6),
        cues: [Cue(1.s, 'tap'), Cue(2500.ms, 'whoosh', gain: 3)],
        resolve: resolve,
      )!;
      final graph = args[args.indexOf('-filter_complex') + 1];
      expect(args, containsAllInOrder(['-i', '/sfx/tap.wav']));
      expect(graph, contains('adelay=1000|1000,volume=-6.0dB'));
      expect(graph, contains('adelay=2500|2500,volume=-3.0dB'));
      expect(graph, contains('loudnorm=I=-16'));
      expect(graph, contains('atrim=0:5.000'));
      expect(args.last, 'o.mp4');
    });

    test('Given music and voice, then the music ducks under the voice', () {
      final args = mixArgs(
        video: 'v.mp4',
        out: 'o.mp4',
        length: 10.s,
        soundtrack: const Soundtrack(
          music: Music('m.m4a'),
          voice: [VoiceLine(Duration(seconds: 2), 'v1.m4a', 'Hello')],
          cues: false,
        ),
        cues: [Cue(1.s, 'tap')],
        resolve: resolve,
      )!;
      final graph = args[args.indexOf('-filter_complex') + 1];
      expect(graph, contains('sidechaincompress'));
      expect(graph, contains('afade=t=out:st=8.000'));
      expect(graph, isNot(contains('/sfx/tap.wav')));
      expect(args, isNot(contains('/sfx/tap.wav')));
    });
  });

  group('Sfx', () {
    test('Given a path that exists, then it is used as it is', () {
      expect(
        Sfx.resolve('pubspec.yaml', '/tmp/none', 'ffmpeg'),
        'pubspec.yaml',
      );
    });

    test('Given neither a name nor a file, then it fails loudly', () {
      expect(
        () => Sfx.resolve('no-such-sound', '/tmp/none', 'ffmpeg'),
        throwsArgumentError,
      );
    });
  });
}
