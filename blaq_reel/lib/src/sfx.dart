import 'dart:io';

/// The built-in sounds, synthesized by FFmpeg the first time they are
/// needed, so a reel has taps and whooshes with no files to find.
abstract final class Sfx {
  /// Each sound's FFmpeg source.
  static const sources = <String, String>{
    'tap':
        "aevalsrc=exprs='0.55*sin(2*PI*2100*t)*exp(-t*95)"
        "+0.35*sin(2*PI*820*t)*exp(-t*55)':d=0.16:s=48000",
    'tick': "aevalsrc=exprs='0.3*sin(2*PI*3300*t)*exp(-t*150)':d=0.06:s=48000",
    'pop':
        "aevalsrc=exprs='0.5*sin(2*PI*(420+760*t)*t)*exp(-t*20)':d=0.3:s=48000",
    'rise':
        "aevalsrc=exprs='0.22*sin(2*PI*(260+420*t*t)*t)*sin(PI*t/0.7)':"
        'd=0.7:s=48000',
    'whoosh':
        'anoisesrc=d=0.75:c=pink:a=0.7:s=48000,'
        'bandpass=f=1100:width_type=o:w=2.2,'
        "volume='pow(sin(PI*t/0.75),2)':eval=frame",
    'chime':
        "aevalsrc=exprs='0.22*(sin(2*PI*880*t)+0.55*sin(2*PI*1318.5*t)"
        "+0.35*sin(2*PI*1760*t)+0.15*sin(2*PI*2637*t))*exp(-t*2.6)':"
        'd=2.4:s=48000',
  };

  /// The file for [sound] in [dir]: a path is returned as it is; a built-in
  /// name is synthesized there with [ffmpeg] if it is not there yet.
  static String resolve(String sound, String dir, String ffmpeg) {
    final source = sources[sound];
    if (source == null) {
      if (!File(sound).existsSync()) {
        throw ArgumentError.value(sound, 'sound', 'no such file or Sfx name');
      }
      return sound;
    }
    final file = File('$dir/$sound.wav');
    if (!file.existsSync()) {
      file.parent.createSync(recursive: true);
      _run(ffmpeg, [
        '-y',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        source,
        '-ac',
        '2',
        file.path,
      ]);
    }
    return file.path;
  }

  /// Writes a soft ambient pad of [length] to [path]: four slow chords, a
  /// placeholder until real music is chosen.
  static void pad(String path, Duration length, String ffmpeg) {
    final seconds = (length.inMilliseconds / 1000).ceil() + 1;
    // Dmaj9, Bm9, Gmaj7, Aadd9 — four seconds each, every chord swelling in
    // and out so the changes never click.
    const chords = [
      [146.83, 220.0, 277.18, 329.63, 440.0],
      [123.47, 185.0, 220.0, 277.18, 369.99],
      [98.0, 196.0, 246.94, 293.66, 369.99],
      [110.0, 164.81, 220.0, 246.94, 329.63],
    ];
    final terms = <String>[];
    for (var c = 0; c < chords.length; c++) {
      final gate =
          'between(mod(t,16),${c * 4},${c * 4 + 4})'
          '*pow(sin(PI*mod(t,4)/4),0.7)';
      final notes = chords[c]
          .map((f) => 'sin(2*PI*$f*t)+0.25*sin(2*PI*${f * 2}*t)')
          .join('+');
      terms.add('$gate*($notes)');
    }
    final expr = '0.045*(${terms.join('+')})*(1+0.08*sin(2*PI*0.25*t))';
    File(path).parent.createSync(recursive: true);
    _run(ffmpeg, [
      '-y',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      "aevalsrc=exprs='$expr':d=$seconds:s=48000",
      '-af',
      'lowpass=f=2400,aecho=0.8:0.7:120|260:0.25|0.18,'
          'afade=t=in:d=1.5,loudnorm=I=-20:TP=-2',
      '-ac',
      '2',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      path,
    ]);
  }

  static void _run(String ffmpeg, List<String> args) {
    final r = Process.runSync(ffmpeg, args);
    if (r.exitCode != 0) {
      throw ProcessException(ffmpeg, args, '${r.stderr}', r.exitCode);
    }
  }
}
