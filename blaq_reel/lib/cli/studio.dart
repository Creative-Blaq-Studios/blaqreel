import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai.dart';
import 'claude_run.dart';
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

  /// The latest Claude Code run the studio started, live.
  ClaudeRun? _agent;

  Drafter get _drafter => Drafter(project, onUpdate: (run) => _agent = run);

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

  String get _specs => '${project.reels}/specs';

  /// Draws every screen the app's kit offers, with its parts, for the
  /// builder's Screens and Parts steps.
  Future<void> catalogue() => _serial('Drawing the screens', () async {
    final code = await _run({'BLAQ_REEL_TASK': 'catalogue'}, log: false);
    if (code == 0) _library++;
  });

  /// The four styles, each drawn on [spec]'s first two beats: short
  /// previews to choose a style by eye. Written as hidden specs (`_style-…`)
  /// and rendered as studio previews.
  Future<bool> styles(Map<String, Object?> spec) {
    var ok = true;
    return _serial('Rendering the style previews', () async {
      final catalogue = _json('$_dir/catalogue/map.json');
      final screens = {
        for (final s
            in (catalogue?['screens'] as List? ?? const [])
                .cast<Map<String, Object?>>())
          '${s['id']}': s,
      };
      final beats = [
        for (final b
            in (spec['beats'] as List? ?? const [])
                .take(2)
                .cast<Map<String, Object?>>())
          _sampleBeat(b, screens),
      ];
      if (beats.isEmpty) {
        ok = false;
        return;
      }
      String brief() {
        final b = '${spec['brief'] ?? ''}'.trim();
        if (b.isEmpty) return 'Your story starts {here}.';
        final first = b.split(RegExp(r'(?<=[.!?])\s')).first;
        return first.length > 48 ? '${first.substring(0, 46)}…' : first;
      }

      Directory(_specs).createSync(recursive: true);
      void write(String pack, Map<String, Object?> extra) =>
          File('$_specs/_style-$pack.json').writeAsStringSync(
            jsonEncode({
              'pack': pack,
              'look': spec['look'] ?? 'mesh',
              'music': 'none',
              'beats': beats,
              ...extra,
            }),
          );
      write('glass', {});
      write('story', {
        'hook': [brief()],
      });
      write('kinetic', {'look': spec['look'] ?? 'mesh'});
      write('glow', {'look': 'ink'});
      for (final (names, format) in [
        ('_style-glass,_style-story', 'vertical'),
        ('_style-kinetic,_style-glow', 'wide'),
      ]) {
        _status = 'Rendering the style previews ($format)';
        final code = await _run({
          'BLAQ_REEL_TASK': 'preview',
          'BLAQ_REEL_NAME': names,
          'BLAQ_REEL_FORMATS': format,
        });
        if (code != 0) ok = false;
      }
      _status = ok ? 'Style previews rendered' : 'A style preview failed';
    }).then((_) => ok);
  }

  /// A beat for a style preview: its own words and parts if it has them,
  /// otherwise the screen's name and its biggest card.
  Map<String, Object?> _sampleBeat(
    Map<String, Object?> b,
    Map<String, Map<String, Object?>> screens,
  ) {
    final screen = screens['${b['screen']}'];
    final label = '${screen?['label'] ?? b['screen']}'
        .split(RegExp(r'[ ·]'))
        .first;
    var parts = (b['parts'] as List?) ?? const [];
    if (parts.isEmpty && screen != null) {
      final candidates =
          (screen['parts']! as List).cast<Map<String, Object?>>().where((p) {
            final n = '${p['name']}';
            return !n.contains('Btn') &&
                !n.contains('Island') &&
                !n.contains('Segmented') &&
                !n.contains('Bar');
          }).toList()..sort((a, c) {
            double area(Map<String, Object?> p) {
              final r = (p['rect']! as List).cast<num>();
              return (r[2] * r[3]).toDouble();
            }

            return area(c).compareTo(area(a));
          });
      parts = [
        if (candidates.isNotEmpty)
          {'type': candidates.first['name'], 'text': candidates.first['text']},
      ];
    }
    final word = '${b['word'] ?? ''}'.trim();
    final line = '${b['line'] ?? ''}'.trim();
    return {
      'screen': b['screen'],
      'parts': parts,
      'word': word.isNotEmpty ? word : '$label.',
      'line': line.isNotEmpty ? line : 'This is {$label}.',
      'length': 4.6,
      if (b['move'] != null) 'move': b['move'],
    };
  }

  /// Renders [look]s of spec [name] at [at] seconds into
  /// `studio/looks/<name>/`, one still each.
  Future<bool> looks(
    String name,
    String format,
    double at,
    List<String> looks,
  ) {
    var ok = true;
    return _serial('Rendering the grounds', () async {
      final dir = Directory('$_dir/looks/$name')..createSync(recursive: true);
      final stem = format == project.format ? name : '$name-$format';
      for (final look in looks) {
        _status = 'Rendering $name on $look';
        final code = await _run({
          'BLAQ_REEL_TASK': 'stills',
          'BLAQ_REEL_NAME': name,
          'BLAQ_REEL_FORMATS': format,
          'BLAQ_REEL_AT': '$at',
          'BLAQ_REEL_LOOK': look,
        });
        if (code != 0) {
          ok = false;
          return;
        }
        File(
          '${project.out}/stills/$stem-${at}s.png',
        ).renameSync('${dir.path}/$look.png');
      }
      _status = 'Grounds rendered';
    }).then((_) => ok);
  }

  /// Serves until the process is stopped.
  Future<Uri> serve({void Function(Uri)? onReady}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final uri = Uri.parse('http://localhost:${server.port}/');
    server.listen(_handle);
    onReady?.call(uri);
    if (watch) _watch();
    unawaited(_describe());
    if (!File('$_dir/catalogue/map.json').existsSync()) unawaited(catalogue());
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
        if (meta == null || '${meta['name']}'.startsWith('_')) continue;
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
            'agent': _agent?.toJson(),
          });
        case '/api/catalogue' when req.method == 'GET':
          _sendJson(req, _json('$_dir/catalogue/map.json'));
        case '/api/catalogue' when req.method == 'POST':
          unawaited(catalogue());
          _sendJson(req, {'ok': true});
        case '/api/specs':
          final dir = Directory(_specs);
          _sendJson(req, [
            if (dir.existsSync())
              for (final f in dir.listSync().whereType<File>())
                if (f.path.endsWith('.json') &&
                    !f.uri.pathSegments.last.startsWith('_'))
                  {
                    'name': f.uri.pathSegments.last.replaceAll('.json', ''),
                    'spec': _json(f.path),
                  },
          ]);
        case '/api/spec' when req.method == 'GET':
          _sendJson(req, _json('$_specs/${_safe(q['name'])}.json'));
        case '/api/spec' when req.method == 'PUT':
          final body = await utf8.decodeStream(req);
          final spec = jsonDecode(body);
          Directory(_specs).createSync(recursive: true);
          File('$_specs/${_safe(q['name'])}.json').writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(spec)}\n',
          );
          _sendJson(req, {'ok': true});
        case '/api/spec/preview' when req.method == 'POST':
          // Read the reels again (a new spec is a new reel), then work on it.
          reel = _safe(q['name']);
          format = q['format'] ?? format;
          unawaited(_describe());
          unawaited(preview());
          _version++;
          _sendJson(req, {'ok': true});
        case '/api/ai' when req.method == 'POST':
          final body =
              jsonDecode(await utf8.decodeStream(req)) as Map<String, Object?>;
          try {
            final draft = await _drafter.draft(
              spec: (body['spec'] as Map?)?.cast<String, Object?>() ?? {},
              brief: '${body['brief'] ?? ''}',
              all: body['all'] == true,
              catalogue: _json('$_dir/catalogue/map.json'),
            );
            _sendJson(req, {'ok': true, 'draft': draft});
          } on CliError catch (e) {
            _sendJson(req, {'ok': false, 'error': e.message});
          }
        case '/api/styles':
          if (req.method == 'POST') {
            final spec =
                jsonDecode(await utf8.decodeStream(req))
                    as Map<String, Object?>;
            final ok = await styles(spec);
            if (!ok) {
              _sendJson(req, {'ok': false});
              return;
            }
          }
          final stamp = DateTime.now().millisecondsSinceEpoch;
          _sendJson(req, {
            'ok': true,
            'clips': {
              for (final (pack, format) in [
                ('glass', 'vertical'),
                ('kinetic', 'wide'),
                ('glow', 'wide'),
                ('story', 'vertical'),
              ])
                if (File('$_dir/_style-$pack-$format.mp4').existsSync())
                  pack: '/files/_style-$pack-$format.mp4?v=$stamp',
            },
          });
        case '/api/screens/unstaged':
          _sendJson(req, _unstaged());
        case '/api/inventory' when req.method == 'GET':
          _sendJson(req, _inventory());
        case '/api/inventory/scan' when req.method == 'POST':
          await _serial('Taking the inventory with Claude', () async {
            _status = 'Claude is reading the app';
            final found = await _drafter.inventory();
            mergeInventory(project, found, replace: true);
          });
          _sendJson(req, _inventory());
        case '/api/inventory/find' when req.method == 'POST':
          final body =
              jsonDecode(await utf8.decodeStream(req)) as Map<String, Object?>;
          var added = <Map<String, Object?>>[];
          await _serial('Looking for it with Claude', () async {
            _status = 'Claude is looking';
            added = await _drafter.inventory(
              lookFor: '${body['description'] ?? ''}',
            );
            mergeInventory(project, added);
          });
          _sendJson(req, {..._inventory(), 'added': added});
        case '/api/screens/stage' when req.method == 'POST':
          final body =
              jsonDecode(await utf8.decodeStream(req)) as Map<String, Object?>;
          String? summary;
          String? error;
          await _serial('Staging a screen with Claude', () async {
            _status = 'Claude is staging the screen';
            try {
              summary = await _drafter.stageScreen(
                name: body['name'] as String?,
                file: body['file'] as String?,
                description: body['description'] as String?,
                items: [
                  for (final i in (body['items'] as List?) ?? const [])
                    (i as Map).cast<String, Object?>(),
                ],
              );
            } on CliError catch (e) {
              error = e.message;
            }
          });
          if (error == null) await catalogue();
          _sendJson(req, {
            'ok': error == null,
            'summary': summary,
            'error': error,
          });
        case '/api/looks' when req.method == 'POST':
          final name = _safe(q['name']);
          final ok = await looks(
            name,
            q['format'] ?? project.format,
            double.parse(q['at'] ?? '4.2'),
            (q['looks'] ?? 'ink,mesh,butter,studio,grid').split(','),
          );
          _sendJson(req, {'ok': ok});
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
          } else if (path.startsWith('/catalogue/')) {
            await _file(req, File('$_dir/catalogue/${path.substring(11)}'));
          } else if (path.startsWith('/looks/')) {
            await _file(req, File('$_dir/looks/${path.substring(7)}'));
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

  /// The inventory, each item marked with whether the kit stages it yet.
  Map<String, Object?> _inventory() {
    final file = File('${project.reels}/inventory.json');
    final staged = StringBuffer();
    for (final f in ['kit.dart', 'screens.dart']) {
      final k = File('${project.reels}/$f');
      if (k.existsSync()) staged.write(k.readAsStringSync());
    }
    if (!file.existsSync()) return {'items': const [], 'taken': null};
    final doc = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    return {
      'taken': doc['taken'],
      'items': [
        for (final i in (doc['items']! as List).cast<Map<String, Object?>>())
          {...i, 'staged': staged.toString().contains('${i['name']}')},
      ],
    };
  }

  /// Screens in the app's code that the kit does not offer yet: every
  /// `…Screen` widget in lib/ not named in app_reels/.
  List<Map<String, String>> _unstaged() {
    final staged = StringBuffer();
    for (final f in ['kit.dart', 'screens.dart']) {
      final file = File('${project.reels}/$f');
      if (file.existsSync()) staged.write(file.readAsStringSync());
    }
    final lib = Directory('${project.root.path}/lib');
    if (!lib.existsSync()) return const [];
    final found = <Map<String, String>>[];
    final pattern = RegExp(r'class (\w+Screen) extends');
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in pattern.allMatches(f.readAsStringSync())) {
        final name = m.group(1)!;
        if (staged.toString().contains(name)) continue;
        found.add({
          'name': name,
          'file': f.path.substring(project.root.path.length + 1),
        });
      }
    }
    found.sort((a, b) => a['name']!.compareTo(b['name']!));
    return found;
  }

  /// A name safe to use as a file name.
  static String _safe(String? name) {
    final n = (name ?? '').trim();
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,60}$').hasMatch(n)) {
      throw FormatException(
        'A reel name is lowercase letters, digits, - and _.',
      );
    }
    return n;
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

/// Adds [found] to the app's inventory (`app_reels/inventory.json`), or
/// with [replace] starts it afresh; items are kept unique by name.
void mergeInventory(
  Project project,
  List<Map<String, Object?>> found, {
  bool replace = false,
}) {
  final file = File('${project.reels}/inventory.json');
  final items = <String, Map<String, Object?>>{};
  if (!replace && file.existsSync()) {
    final doc = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    for (final i in (doc['items']! as List).cast<Map<String, Object?>>()) {
      items['${i['name']}'] = i;
    }
  }
  for (final i in found) {
    if (i['name'] == null) continue;
    items['${i['name']}'] = {...?items['${i['name']}'], ...i};
  }
  final list = items.values.toList()
    ..sort((a, b) {
      final k = '${a['kind']}'.compareTo('${b['kind']}');
      return k != 0 ? k : '${a['name']}'.compareTo('${b['name']}');
    });
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'taken': DateTime.now().toIso8601String(), 'items': list})}\n',
  );
}
