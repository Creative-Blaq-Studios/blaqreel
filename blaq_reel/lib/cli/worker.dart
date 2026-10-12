import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'project.dart';

/// The studio's renderer, kept running between renders: `render_test.dart`
/// run once with the task `serve`, so the app is compiled once rather than
/// for every render — most of a short render's time. Jobs go to it as files
/// in `<out>/studio/jobs/`; see `_serve` in the runner.
class RenderWorker {
  /// The app it renders.
  final Project project;

  Process? _process;
  Completer<bool>? _up;

  /// Each job waiting, and the run of the worker it went to.
  final _pending = <String, (int, Completer<int>)>{};
  var _run = 0;
  void Function(String line)? _onLine;
  Timer? _heartbeat;
  var _count = 0;

  /// A worker for [project]; it starts on [start] or the first [run].
  RenderWorker(this.project);

  String get _jobs => '${project.out}/studio/jobs';

  /// Whether it is up and waiting for work.
  bool get ready => _up?.isCompleted == true && _process != null;

  /// Starts it, unless it is running: done ahead of the first render, which
  /// then skips the compiling. True once it is serving; false if it stopped
  /// before it could.
  Future<bool> start() {
    final running = _up;
    if (running != null) return running.future;
    final up = _up = Completer<bool>();
    final run = ++_run;
    final jobs = Directory(_jobs)..createSync(recursive: true);
    for (final f in jobs.listSync().whereType<File>()) {
      f.deleteSync();
    }
    // It stops by itself once the studio stops saying it is alive.
    _touch();
    _heartbeat ??= Timer.periodic(const Duration(seconds: 5), (_) => _touch());
    unawaited(() async {
      Process? p;
      try {
        p = _process = await project.startRenderTest({
          'BLAQ_REEL_TASK': 'serve',
        });
        final lines = [
          for (final s in [p.stdout, p.stderr])
            s
                .transform(utf8.decoder)
                .transform(const LineSplitter())
                .forEach(_handle),
        ];
        await p.exitCode;
        await Future.wait(lines);
      } finally {
        if (identical(_process, p)) _process = null;
        if (identical(_up, up)) _up = null;
        if (!up.isCompleted) up.complete(false);
        // A job it was on is run again the usual way.
        _pending.removeWhere((_, job) {
          if (job.$1 != run) return false;
          if (!job.$2.isCompleted) job.$2.complete(-1);
          return true;
        });
      }
    }());
    return up.future;
  }

  void _touch() {
    try {
      File('$_jobs/alive').writeAsStringSync('${DateTime.now()}');
    } on FileSystemException {
      // The out folder went away; the next start makes it again.
    }
  }

  void _handle(String line) {
    if (line.contains('blaq_reel: serving')) {
      if (!(_up?.isCompleted ?? true)) _up!.complete(true);
      return;
    }
    final done = RegExp(r'blaq_reel: job (\S+) done (-?\d+)').firstMatch(line);
    if (done != null) {
      _pending.remove(done[1])?.$2.complete(int.parse(done[2]!));
      return;
    }
    _onLine?.call(line);
  }

  /// Renders [job] (`{"task", "name", "formats", ...}`), passing its output
  /// lines to [onLine]. Its exit code, or null if the worker could not take
  /// it: the caller then renders the usual way.
  Future<int?> run(
    Map<String, Object?> job, {
    void Function(String line)? onLine,
  }) async {
    if (!await start()) return null;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_count++}';
    final result = Completer<int>();
    _pending[id] = (_run, result);
    _onLine = onLine;
    // Written whole before the worker can see it.
    File('$_jobs/$id.tmp')
      ..writeAsStringSync(jsonEncode(job))
      ..renameSync('$_jobs/$id.job');
    // Its answer is a line, and a file in case the line is lost.
    final done = File('$_jobs/$id.done');
    final poll = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (result.isCompleted || !done.existsSync()) return;
      final code = int.tryParse(done.readAsStringSync().trim());
      if (code != null) {
        _pending.remove(id);
        result.complete(code);
      }
    });
    final code = await result.future;
    poll.cancel();
    if (done.existsSync()) done.deleteSync();
    _onLine = null;
    return code < 0 ? null : code;
  }

  /// Stops it, because the app's code changed, and starts a fresh one so
  /// the next render finds it compiled.
  Future<void> restart() async {
    final p = _process;
    _up = null;
    if (p != null) {
      p.kill();
      await p.exitCode;
    }
    unawaited(start());
  }

  /// Stops it for good.
  void stop() {
    _heartbeat?.cancel();
    _process?.kill();
  }
}
