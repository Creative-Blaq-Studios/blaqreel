import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'project.dart';

/// One thing Claude did during a run, in words a person can follow.
class ClaudeStep {
  /// When.
  final DateTime at;

  /// What: "Reading lib/…/people_screen.dart", "Running dart analyze".
  final String text;

  /// `read`, `search`, `edit`, `run`, `say` or `note`.
  final String kind;

  /// A step.
  ClaudeStep(this.text, this.kind) : at = DateTime.now();

  /// As JSON.
  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'text': text,
    'kind': kind,
  };
}

/// A headless Claude Code session the studio started (`claude -p`), as it
/// happens: its session id (to resume it in a terminal), its steps, the
/// files it changed, and how it ended.
class ClaudeRun {
  /// What it was asked to do, for people: "Staging 2 screens".
  final String task;

  /// The folder it ran in.
  final String cwd;

  /// When it started.
  final DateTime started = DateTime.now();

  /// The session id, once Claude has said it.
  String? sessionId;

  /// What it has done so far.
  final List<ClaudeStep> steps = [];

  /// Files it wrote or edited, relative to [cwd].
  final Set<String> files = {};

  /// Whether it has finished.
  bool done = false;

  /// Whether it finished well.
  bool ok = false;

  /// Its final answer.
  String? result;

  /// What went wrong, if it did.
  String? error;

  /// A run.
  ClaudeRun(this.task, this.cwd);

  /// The command that reopens it in a terminal.
  String? get resume =>
      sessionId == null ? null : 'cd "$cwd" && claude --resume $sessionId';

  /// As JSON, for the studio.
  Map<String, Object?> toJson() => {
    'task': task,
    'started': started.toIso8601String(),
    'sessionId': sessionId,
    'resume': resume,
    'steps': [
      for (final s in steps.skip(steps.length > 80 ? steps.length - 80 : 0))
        s.toJson(),
    ],
    'files': files.toList()..sort(),
    'done': done,
    'ok': ok,
    'result': result,
    'error': error,
  };

  String _rel(Object? path) {
    final p = '${path ?? ''}';
    return p.startsWith('$cwd/') ? p.substring(cwd.length + 1) : p;
  }

  /// Takes one line of `--output-format stream-json`.
  void take(String line) {
    final Object? e;
    try {
      e = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (e is! Map) return;
    sessionId ??= e['session_id'] as String?;
    switch (e['type']) {
      case 'assistant':
        final content = (e['message'] as Map?)?['content'];
        for (final c in content is List ? content : const []) {
          if (c is! Map) continue;
          if (c['type'] == 'text') {
            final text = '${c['text']}'.trim().split('\n').first;
            if (text.isNotEmpty && !text.startsWith('Session:')) {
              steps.add(
                ClaudeStep(
                  text.length > 160 ? '${text.substring(0, 157)}…' : text,
                  'say',
                ),
              );
            }
          } else if (c['type'] == 'tool_use') {
            _tool('${c['name']}', (c['input'] as Map?) ?? const {});
          }
        }
      case 'result':
        done = true;
        ok = e['is_error'] != true && e['subtype'] == 'success';
        result = _withoutFooter('${e['result'] ?? ''}');
    }
  }

  void _tool(String name, Map<Object?, Object?> input) {
    switch (name) {
      case 'Read':
        steps.add(ClaudeStep('Reading ${_rel(input['file_path'])}', 'read'));
      case 'Grep':
        steps.add(
          ClaudeStep(
            'Searching for "${input['pattern']}"${input['path'] == null ? '' : ' in ${_rel(input['path'])}'}',
            'search',
          ),
        );
      case 'Glob':
        steps.add(ClaudeStep('Looking for ${input['pattern']}', 'search'));
      case 'Edit' || 'MultiEdit':
        final f = _rel(input['file_path']);
        files.add(f);
        steps.add(ClaudeStep('Editing $f', 'edit'));
      case 'Write':
        final f = _rel(input['file_path']);
        files.add(f);
        steps.add(ClaudeStep('Writing $f', 'edit'));
      case 'Bash':
        steps.add(ClaudeStep('Running ${input['command']}', 'run'));
      default:
        steps.add(ClaudeStep(name, 'note'));
    }
  }

  /// Drops a "Session: …" footer some setups add to every answer.
  static String _withoutFooter(String text) => text
      .split('\n')
      .where((l) => !l.trim().startsWith('Session:'))
      .join('\n')
      .trim();
}

/// Runs `claude -p [prompt]` in [project]'s folder with [args], streaming:
/// [onUpdate] is called after every step. Throws [CliError] when Claude
/// Code is missing; otherwise returns the run, finished well or not.
Future<ClaudeRun> runClaude(
  Project project, {
  required String task,
  required String prompt,
  List<String> args = const [],
  Duration timeout = const Duration(minutes: 8),
  void Function(ClaudeRun run)? onUpdate,
}) async {
  final run = ClaudeRun(task, project.root.path);
  onUpdate?.call(run);
  final Process process;
  try {
    process = await Process.start('claude', [
      '-p',
      prompt,
      '--output-format',
      'stream-json',
      '--verbose',
      ...args,
    ], workingDirectory: project.root.path);
  } on ProcessException {
    throw const CliError(
      'Claude Code is not installed here (`claude` was not found).',
    );
  }
  final errors = StringBuffer();
  final out = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
        run.take(line);
        onUpdate?.call(run);
      });
  final err = process.stderr.transform(utf8.decoder).forEach(errors.write);
  final code = await process.exitCode.timeout(
    timeout,
    onTimeout: () {
      process.kill();
      run.error = 'Stopped after ${timeout.inMinutes} minutes.';
      return -1;
    },
  );
  await Future.wait([out, err]);
  run.done = true;
  if (code != 0) {
    run.ok = false;
    run.error ??= '$errors'.trim().isEmpty
        ? 'Claude exited with $code.'
        : '$errors'.trim();
  }
  onUpdate?.call(run);
  return run;
}
