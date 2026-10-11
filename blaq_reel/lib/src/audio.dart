import 'time.dart';

export 'sfx.dart';

/// A sound at a moment: a name from [Sfx] (`tap`, `whoosh`, …) or a path to
/// a file.
class Cue {
  /// When it plays.
  final Duration at;

  /// What plays.
  final String sound;

  /// Its level, in dB from its own.
  final double gain;

  /// A cue.
  const Cue(this.at, this.sound, {this.gain = 0});

  /// The same sound at [at].
  Cue copyAt(Duration at) => Cue(at, sound, gain: gain);
}

/// A music bed under the whole reel. `Music(Music.pad)` is a soft
/// synthesized pad the length of the reel: a placeholder until real music is
/// chosen.
class Music {
  /// The built-in placeholder pad.
  static const pad = 'pad';

  /// The file.
  final String path;

  /// Its level, in dB.
  final double gain;

  /// Fade in at the start.
  final Duration fadeIn;

  /// Fade out at the end.
  final Duration fadeOut;

  /// How far into the file the reel starts.
  final Duration offset;

  /// Music.
  const Music(
    this.path, {
    this.gain = -6,
    this.fadeIn = const Duration(milliseconds: 600),
    this.fadeOut = const Duration(seconds: 2),
    this.offset = Duration.zero,
  });
}

/// One line of voice-over, as a recorded file, from [at]. [text] is what it
/// says, for captions.
class VoiceLine {
  /// When it starts.
  final Duration at;

  /// The recording.
  final String path;

  /// What it says.
  final String text;

  /// Its level, in dB.
  final double gain;

  /// A line.
  const VoiceLine(this.at, this.path, this.text, {this.gain = 0});
}

/// Music, voice-over and cues. Under voice-over the music ducks.
class Soundtrack {
  /// The bed.
  final Music? music;

  /// Voice-over lines.
  final List<VoiceLine> voice;

  /// Whether the reel's cues play.
  final bool cues;

  /// Level of every cue, in dB.
  final double cueGain;

  /// Whether music ducks under voice-over.
  final bool duck;

  /// A soundtrack. The default plays the reel's cues and nothing else.
  const Soundtrack({
    this.music,
    this.voice = const [],
    this.cues = true,
    this.cueGain = -6,
    this.duck = true,
  });

  /// No sound at all.
  static const silent = Soundtrack(cues: false);
}

/// Builds the FFmpeg arguments that lay a [Soundtrack] and [cues] under a
/// silent video, writing [out]. Pure: it runs nothing.
///
/// [resolve] turns a cue's sound into a file. Returns null when there is
/// nothing to hear.
List<String>? mixArgs({
  required String video,
  required String out,
  required Duration length,
  required Soundtrack soundtrack,
  required List<Cue> cues,
  required String Function(String sound) resolve,
}) {
  final played = soundtrack.cues ? cues : const <Cue>[];
  if (soundtrack.music == null && soundtrack.voice.isEmpty && played.isEmpty) {
    return null;
  }
  final seconds = secondsOf(length).toStringAsFixed(3);
  final inputs = <String>['-i', video];
  final filters = <String>[];
  final finals = <String>[];
  var n = 1;
  String ms(Duration d) => '${d.inMilliseconds}';

  final music = soundtrack.music;
  if (music != null) {
    inputs.addAll(['-i', music.path]);
    final fadeOutAt = secondsOf(length - music.fadeOut).toStringAsFixed(3);
    filters.add(
      '[$n:a]atrim=start=${secondsOf(music.offset)},asetpts=PTS-STARTPTS,'
      'afade=t=in:d=${secondsOf(music.fadeIn)},'
      'afade=t=out:st=$fadeOutAt:d=${secondsOf(music.fadeOut)},'
      'volume=${music.gain}dB[music]',
    );
    n++;
  }

  if (soundtrack.voice.isNotEmpty) {
    final labels = <String>[];
    for (final line in soundtrack.voice) {
      inputs.addAll(['-i', line.path]);
      filters.add(
        '[$n:a]adelay=${ms(line.at)}|${ms(line.at)},'
        'volume=${line.gain}dB[v$n]',
      );
      labels.add('[v$n]');
      n++;
    }
    filters.add(
      '${labels.join()}amix=inputs=${labels.length}:normalize=0[voice]',
    );
    if (music != null && soundtrack.duck) {
      filters
        ..add('[voice]asplit=2[voiceA][voiceB]')
        ..add(
          '[music][voiceA]sidechaincompress=threshold=0.03:ratio=6:'
          'attack=15:release=350[ducked]',
        );
      finals.addAll(['[ducked]', '[voiceB]']);
    } else {
      if (music != null) finals.add('[music]');
      finals.add('[voice]');
    }
  } else if (music != null) {
    finals.add('[music]');
  }

  if (played.isNotEmpty) {
    final labels = <String>[];
    for (final cue in played) {
      inputs.addAll(['-i', resolve(cue.sound)]);
      final gain = cue.gain + soundtrack.cueGain;
      filters.add(
        '[$n:a]adelay=${ms(cue.at)}|${ms(cue.at)},volume=${gain}dB[c$n]',
      );
      labels.add('[c$n]');
      n++;
    }
    filters.add(
      '${labels.join()}amix=inputs=${labels.length}:normalize=0[cues]',
    );
    finals.add('[cues]');
  }

  final mix = finals.length == 1
      ? '${finals.single}anull'
      : '${finals.join()}amix=inputs=${finals.length}:normalize=0';
  // Social platforms play at about -14 LUFS; -16 leaves them headroom and
  // still sounds full on a phone.
  filters.add(
    '$mix,loudnorm=I=-16:TP=-1.5:LRA=11,alimiter=limit=0.9,'
    'apad,atrim=0:$seconds[audio]',
  );

  return [
    '-y',
    '-loglevel',
    'error',
    ...inputs,
    '-filter_complex',
    filters.join(';'),
    '-map',
    '0:v',
    '-map',
    '[audio]',
    '-c:v',
    'copy',
    '-c:a',
    'aac',
    '-b:a',
    '192k',
    '-ar',
    '48000',
    '-movflags',
    '+faststart',
    out,
  ];
}
