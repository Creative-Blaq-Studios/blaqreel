import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'project.dart';
import 'studio_page.dart';

/// The studio: a preview of a reel in the browser, with a scrubber, frame
/// stepping, the timeline of scenes, words and cues, full-size stills on
/// demand, and a fresh preview whenever a file under `app_reels/` or `lib/`
/// changes.
class Studio {
  /// The app.
  final Project project;

  /// The reel.
  final String reel;

  /// Its format.
  final String format;

  /// The port to serve on.
  final int port;

  /// Whether file changes re-render.
  final bool watch;

  var _version = 0;
  var _rendering = false;
  var _queued = false;
  String _status = 'Starting';
  final List<String> _log = [];
  DateTime? _renderedAt;

  /// A studio.
  Studio(
    this.project, {
    required this.reel,
    required this.format,
    this.port = 4455,
    this.watch = true,
  });

  String get _dir => '${project.out}/studio';

  /// Serves until the process is stopped. Returns the address.
  Future<Uri> serve({void Function(Uri)? onReady}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final uri = Uri.parse('http://localhost:${server.port}/');
    server.listen(_handle);
    onReady?.call(uri);
    if (watch) _watch();
    unawaited(render());
    return uri;
  }

  /// Renders the preview again, or queues one if a render is running.
  Future<void> render() async {
    if (_rendering) {
      _queued = true;
      return;
    }
    _rendering = true;
    _status = 'Rendering';
    _log.clear();
    final watch = Stopwatch()..start();
    final code = await project.renderTest(
      {
        'BLAQ_REEL_TASK': 'preview',
        'BLAQ_REEL_NAME': reel,
        'BLAQ_REEL_FORMATS': format,
      },
      quiet: true,
      onLine: (line) {
        if (line.contains('blaq_reel:') ||
            line.contains('EXCEPTION') ||
            line.contains('Error')) {
          _log.add(line.trim());
          if (_log.length > 40) _log.removeAt(0);
        }
      },
    );
    _rendering = false;
    if (code == 0) {
      _version++;
      _renderedAt = DateTime.now();
      _status = 'Rendered in ${watch.elapsed.inSeconds}s';
    } else {
      _status = 'Render failed — see the log';
    }
    stdout.writeln('studio: $_status');
    if (_queued) {
      _queued = false;
      await render();
    }
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
        unawaited(render());
      });
    }

    for (final dir in [project.reels, '${project.root.path}/lib']) {
      if (Directory(dir).existsSync()) {
        Directory(dir).watch(recursive: true).listen(changed);
      }
    }
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    try {
      if (path == '/') {
        _send(req, 'text/html; charset=utf-8', utf8.encode(studioPage));
      } else if (path == '/api/state') {
        final meta = File('$_dir/$reel-$format.json');
        _send(
          req,
          'application/json',
          utf8.encode(
            jsonEncode({
              'version': _version,
              'rendering': _rendering,
              'status': _status,
              'renderedAt': _renderedAt?.toIso8601String(),
              'log': _log,
              'reel': meta.existsSync()
                  ? jsonDecode(meta.readAsStringSync())
                  : null,
            }),
          ),
        );
      } else if (path == '/api/render' && req.method == 'POST') {
        unawaited(render());
        _send(req, 'application/json', utf8.encode('{"ok":true}'));
      } else if (path == '/api/still' && req.method == 'POST') {
        final t = double.parse(req.uri.queryParameters['t'] ?? '0');
        final at = t.toStringAsFixed(2);
        final code = await project.renderTest({
          'BLAQ_REEL_TASK': 'stills',
          'BLAQ_REEL_NAME': reel,
          'BLAQ_REEL_FORMATS': format,
          'BLAQ_REEL_AT': at,
        }, quiet: true);
        final stem = format == project.format ? reel : '$reel-$format';
        final name = '$stem-${double.parse(at)}s.png';
        _send(
          req,
          'application/json',
          utf8.encode(
            jsonEncode({
              'ok': code == 0,
              'url': '/stills/$name',
              'path': '${project.out}/stills/$name',
            }),
          ),
        );
      } else if (path.startsWith('/files/')) {
        await _file(req, File('$_dir/${path.substring(7)}'));
      } else if (path.startsWith('/stills/')) {
        await _file(req, File('${project.out}/stills/${path.substring(8)}'));
      } else {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
      }
    } catch (e) {
      req.response.statusCode = HttpStatus.internalServerError;
      req.response.write('$e');
      await req.response.close();
    }
  }

  void _send(HttpRequest req, String type, List<int> body) {
    req.response.headers
      ..set(HttpHeaders.contentTypeHeader, type)
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    req.response.add(body);
    unawaited(req.response.close());
  }

  /// Serves [file], honouring Range requests so the video can be scrubbed.
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
