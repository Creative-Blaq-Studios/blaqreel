import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'project.dart';
import 'studio_page.dart';

/// The formats a rendered file's name can end in.
const _formats = ['vertical', 'wide', 'square', 'portrait'];

/// The studio: every reel and every rendered video of an app in one page.
///
/// Pick a reel and a format to work on it: a quick preview renders, with a
/// scrubber, frame stepping, the timeline of scenes, words and cues, and
/// full-size stills on demand, and it renders again whenever a file under
/// `app_reels/` or `lib/` changes. Pick a finished video to watch it with
/// the same timeline. Render a finished video of what you are working on
/// from the page.
class Studio {
  /// The app.
  final Project project;

  /// The port to serve on.
  final int port;

  /// Whether file changes re-render.
  final bool watch;

  /// The reel being worked on.
  String reel;

  /// Its format.
  String format;

  var _version = 0;
  var _library = 0;
  String? _job;
  String _status = 'Starting';
  final List<String> _log = [];
  DateTime? _renderedAt;
  Future<void> _queue = Future.value();
  var _previewQueued = false;

  /// A studio.
  Studio(
    this.project, {
    required this.reel,
    required this.format,
    this.port = 4455,
    this.watch = true,
  });

  String get _dir => '${project.out}/studio';

  /// Serves until the process is stopped.
  Future<Uri> serve({void Function(Uri)? onReady}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final uri = Uri.parse('http://localhost:${server.port}/');
    server.listen(_handle);
    onReady?.call(uri);
    if (watch) _watch();
    unawaited(_describe());
    // A preview from an earlier session is shown as it is; saving a file
    // renders a fresh one.
    if (!File('$_dir/$reel-$format.mp4').existsSync()) unawaited(preview());
    return uri;
  }

  /// Runs [job] after every job before it: one render at a time.
  Future<void> _serial(String name, Future<void> Function() job) {
    final next = _queue.then((_) async {
      _job = name;
      try {
        await job();
      } finally {
        _job = null;
      }
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<int> _run(Map<String, String> defines, {bool log = true}) =>
      project.renderTest(
        defines,
        quiet: true,
        onLine: !log
            ? null
            : (line) {
                if (line.contains('blaq_reel:') ||
                    line.contains('EXCEPTION') ||
                    line.contains('Error')) {
                  _log.add(line.trim());
                  if (_log.length > 40) _log.removeAt(0);
                }
              },
      );

  /// Reads every reel's timeline in every format, for the library.
  Future<void> _describe() => _serial('Reading the reels', () async {
    await _run({
      'BLAQ_REEL_TASK': 'describe',
      'BLAQ_REEL_FORMATS': 'all',
    }, log: false);
    _library++;
  });

  /// Renders the preview of the reel being worked on. Asking while one is
  /// waiting to start does not queue another.
  Future<void> preview() {
    if (_previewQueued) return Future.value();
    _previewQueued = true;
    return _serial('Rendering the preview', () async {
      _previewQueued = false;
      final r = reel, f = format;
      _status = 'Rendering $r · $f';
      _log.clear();
      final watch = Stopwatch()..start();
      final code = await _run({
        'BLAQ_REEL_TASK': 'preview',
        'BLAQ_REEL_NAME': r,
        'BLAQ_REEL_FORMATS': f,
      });
      if (code == 0) {
        _version++;
        _renderedAt = DateTime.now();
        _status = 'Preview rendered in ${watch.elapsed.inSeconds}s';
      } else {
        _status = 'Render failed — see the log';
      }
      stdout.writeln('studio: $_status');
    });
  }

  /// Renders the finished video of the reel being worked on.
  Future<void> finalRender() {
    final r = reel, f = format;
    return _serial('Rendering $r · $f final', () async {
      _status = 'Rendering the final $r · $f';
      _log.clear();
      final watch = Stopwatch()..start();
      final code = await _run({
        'BLAQ_REEL_TASK': 'video',
        'BLAQ_REEL_NAME': r,
        'BLAQ_REEL_FORMATS': f,
      });
      _status = code == 0
          ? 'Final $r · $f rendered in ${watch.elapsed.inSeconds}s'
          : 'Final render failed — see the log';
      _library++;
      stdout.writeln('studio: $_status');
    });
  }

  void _watch() {
    Timer? debounce;
    void changed(FileSystemEvent e) {
      final path = e.path;
      if (!path.endsWith('.dart') && !path.endsWith('.yaml')) return;
      if (path.contains('/out/') || path.contains('/sound/')) return;
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 700), () {
        stdout.writeln('studio: ${path.split('/').last} changed');
        unawaited(_describe());
        unawaited(preview());
      });
    }

    for (final dir in [project.reels, '${project.root.path}/lib']) {
      if (Directory(dir).existsSync()) {
        Directory(dir).watch(recursive: true).listen(changed);
      }
    }
  }

  Map<String, Object?>? _json(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    } on FormatException {
      return null;
    }
  }

  /// The reels, by the timelines `describe` wrote.
  List<Map<String, Object?>> _reels() {
    final dir = Directory('$_dir/describe');
    final byName = <String, List<Map<String, Object?>>>{};
    if (dir.existsSync()) {
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.json')) continue;
        final meta = _json(f.path);
        if (meta == null) continue;
        (byName['${meta['name']}'] ??= []).add({
          'format': meta['format'],
          'length': meta['length'],
          'scenes': (meta['scenes']! as List).length,
        });
      }
    }
    return [
      for (final name in byName.keys.toList()..sort())
        {
          'name': name,
          'formats': byName[name]!
            ..sort(
              (a, b) => _formats
                  .indexOf('${a['format']}')
                  .compareTo(_formats.indexOf('${b['format']}')),
            ),
        },
    ];
  }

  /// What a rendered file is: its reel and format, from its name.
  (String, String) _parse(String file) {
    final stem = file.substring(0, file.length - 4);
    for (final f in _formats) {
      if (stem.endsWith('-$f')) {
        return (stem.substring(0, stem.length - f.length - 1), f);
      }
    }
    return (stem, project.format);
  }

  final Map<String, (DateTime, double)> _durations = {};

  double _duration(File file) {
    final modified = file.lastModifiedSync();
    final known = _durations[file.path];
    if (known != null && known.$1 == modified) return known.$2;
    final r = Process.runSync('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'csv=p=0',
      file.path,
    ]);
    final d = double.tryParse('${r.stdout}'.trim()) ?? 0;
    _durations[file.path] = (modified, d);
    return d;
  }

  /// The finished videos in `out/`, newest first.
  List<Map<String, Object?>> _videos() {
    final dir = Directory(project.out);
    if (!dir.existsSync()) return const [];
    final files =
        dir.listSync().whereType<File>().where((f) {
          final name = f.uri.pathSegments.last;
          return name.endsWith('.mp4') && !name.contains('.silent.');
        }).toList()..sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
        );
    return [
      for (final f in files)
        () {
          final name = f.uri.pathSegments.last;
          final (r, fmt) = _parse(name);
          return {
            'file': name,
            'reel': r,
            'format': fmt,
            'bytes': f.lengthSync(),
            'duration': _duration(f),
            'modified': f.lastModifiedSync().toIso8601String(),
          };
        }(),
    ];
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    final q = req.uri.queryParameters;
    try {
      switch (path) {
        case '/':
          _send(req, 'text/html; charset=utf-8', utf8.encode(studioPage));
        case '/api/state':
          _sendJson(req, {
            'version': _version,
            'library': _library,
            'job': _job,
            'status': _status,
            'renderedAt': _renderedAt?.toIso8601String(),
            'log': _log,
            'reel': reel,
            'format': format,
            'preview': _json('$_dir/$reel-$format.json'),
          });
        case '/api/library':
          _sendJson(req, {'reels': _reels(), 'videos': _videos()});
        case '/api/meta':
          _sendJson(
            req,
            _json('$_dir/describe/${q['reel']}-${q['format']}.json'),
          );
        case '/api/select' when req.method == 'POST':
          reel = q['reel'] ?? reel;
          format = q['format'] ?? format;
          _version++;
          if (!File('$_dir/$reel-$format.mp4').existsSync()) {
            unawaited(preview());
          }
          _sendJson(req, {'ok': true});
        case '/api/render' when req.method == 'POST':
          unawaited(preview());
          _sendJson(req, {'ok': true});
        case '/api/final' when req.method == 'POST':
          unawaited(finalRender());
          _sendJson(req, {'ok': true});
        case '/api/still' when req.method == 'POST':
          final t = double.parse(q['t'] ?? '0').toStringAsFixed(2);
          final r = q['reel'] ?? reel, f = q['format'] ?? format;
          var code = 1;
          await _serial('Rendering a still', () async {
            code = await _run({
              'BLAQ_REEL_TASK': 'stills',
              'BLAQ_REEL_NAME': r,
              'BLAQ_REEL_FORMATS': f,
              'BLAQ_REEL_AT': t,
            });
          });
          final stem = f == project.format ? r : '$r-$f';
          final name = '$stem-${double.parse(t)}s.png';
          _sendJson(req, {
            'ok': code == 0,
            'url': '/stills/$name',
            'path': '${project.out}/stills/$name',
          });
        default:
          if (path.startsWith('/files/')) {
            await _file(req, File('$_dir/${path.substring(7)}'));
          } else if (path.startsWith('/out/')) {
            await _file(req, File('${project.out}/${path.substring(5)}'));
          } else if (path.startsWith('/stills/')) {
            await _file(
              req,
              File('${project.out}/stills/${path.substring(8)}'),
            );
          } else if (path.startsWith('/thumbs/')) {
            await _thumb(req, path.substring(8));
          } else {
            req.response.statusCode = HttpStatus.notFound;
            await req.response.close();
          }
      }
    } catch (e) {
      req.response.statusCode = HttpStatus.internalServerError;
      req.response.write('$e');
      await req.response.close();
    }
  }

  /// A frame from a second into a finished video, made once per version of
  /// it.
  Future<void> _thumb(HttpRequest req, String name) async {
    final video = File('${project.out}/${name.replaceAll('.jpg', '.mp4')}');
    if (!video.existsSync() || name.contains('..')) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    final thumb = File('$_dir/thumbs/$name');
    if (!thumb.existsSync() ||
        thumb.lastModifiedSync().isBefore(video.lastModifiedSync())) {
      thumb.parent.createSync(recursive: true);
      await Process.run(project.ffmpeg, [
        '-y',
        '-loglevel',
        'error',
        '-ss',
        '1.2',
        '-i',
        video.path,
        '-frames:v',
        '1',
        '-vf',
        'scale=240:-2',
        thumb.path,
      ]);
    }
    await _file(req, thumb);
  }

  void _sendJson(HttpRequest req, Object? data) =>
      _send(req, 'application/json', utf8.encode(jsonEncode(data)));

  void _send(HttpRequest req, String type, List<int> body) {
    req.response.headers
      ..set(HttpHeaders.contentTypeHeader, type)
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    req.response.add(body);
    unawaited(req.response.close());
  }

  /// Serves [file], honouring Range requests so a video can be scrubbed.
  Future<void> _file(HttpRequest req, File file) async {
    final res = req.response;
    if (!file.existsSync() || file.path.contains('..')) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final length = file.lengthSync();
    final type = file.path.endsWith('.mp4')
        ? 'video/mp4'
        : file.path.endsWith('.png')
        ? 'image/png'
        : file.path.endsWith('.jpg')
        ? 'image/jpeg'
        : 'application/json';
    res.headers
      ..set(HttpHeaders.contentTypeHeader, type)
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    final range = req.headers.value(HttpHeaders.rangeHeader);
    final m = range == null
        ? null
        : RegExp(r'bytes=(\d*)-(\d*)').firstMatch(range);
    if (m == null) {
      res.contentLength = length;
      await res.addStream(file.openRead());
      await res.close();
      return;
    }
    final start = m.group(1)!.isEmpty ? 0 : int.parse(m.group(1)!);
    final end = m.group(2)!.isEmpty ? length - 1 : int.parse(m.group(2)!);
    res.statusCode = HttpStatus.partialContent;
    res.headers.set(
      HttpHeaders.contentRangeHeader,
      'bytes $start-$end/$length',
    );
    res.contentLength = end - start + 1;
    await res.addStream(file.openRead(start, end + 1));
    await res.close();
  }
}
