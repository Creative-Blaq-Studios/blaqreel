import 'dart:convert';
import 'dart:io';

import 'project.dart';

/// Drafts a reel with Claude Code (`claude -p`) on the person's machine:
/// the words for chosen beats, or the whole thing — screens, parts and
/// words — from a brief. It is given the app's own copy and the parts the
/// map found, and told to claim nothing the app does not do.
class Drafter {
  /// The app.
  final Project project;

  /// A drafter.
  Drafter(this.project);

  static const _packRules = {
    'glass':
        'Each beat has "word": one or two words ending in a full stop '
        '("Share.", "Say it."). Verbs the person does, not features.',
    'kinetic':
        'Each beat has "line": a short line of at most six words with its key '
        'part in braces ("Split the {bill}.").',
    'glow':
        'Each beat has "word": a title of two or three words with the key '
        'part in braces ("Shared {money}"), and "line": one plain sentence '
        'under ten words.',
    'story':
        'Each beat has "word" as for Glass Layers. Also write "hook": three '
        'short questions a user of this app asks themselves, the key word '
        'in braces; "problem": two short lines, key part in braces; '
        '"meetLine": "Meet {AppName}."; "proof": two short lines that are '
        'true from the copy below, key part in braces.',
  };

  String _copy() {
    for (final f in ['app_reels/copy.md', 'app_reels/REELS.md']) {
      final file = File('${project.root.path}/$f');
      if (file.existsSync()) return file.readAsStringSync();
    }
    return '';
  }

  /// The prompt for [spec] and [brief]; [all] asks for screens and parts
  /// too, from [catalogue].
  String prompt({
    required Map<String, Object?> spec,
    required String brief,
    required bool all,
    required Map<String, Object?>? catalogue,
  }) {
    final pack = '${spec['pack'] ?? 'glass'}';
    final screens = [
      for (final s
          in (catalogue?['screens'] as List? ?? const [])
              .cast<Map<String, Object?>>())
        {
          'id': s['id'],
          'label': s['label'],
          'parts': [
            for (final p in (s['parts']! as List).cast<Map<String, Object?>>())
              {'type': p['name'], 'text': p['text']},
          ],
        },
    ];
    return '''
You are writing a promo reel for the Flutter app "${project.name}" with BlaqReel.
Pack: $pack. Format: ${spec['format'] ?? 'vertical'}.

The person's brief:
${brief.isEmpty ? '(none given: make the strongest case for the app)' : brief}

What the app really does, in its own words (use only claims found here):
${_copy()}

${all ? '''Choose 4 to 6 beats. For each beat pick one screen by "id" from the screens below, and 1 to 3 of that screen's parts to feature, copying "type" and "text" exactly as listed. Each part should show what its beat is about; prefer cards, rows and photos over buttons and bars.

Screens:
${const JsonEncoder.withIndent(' ').convert(screens)}''' : '''The beats are chosen already (screens and parts below). Keep them, in order, and write their words.

Beats:
${const JsonEncoder.withIndent(' ').convert(spec['beats'] ?? [])}'''}

Rules: ${_packRules[pack] ?? _packRules['glass']}
Also write "end": {"line": a closing line of at most six words}.
No numbers, testimonials or claims the copy above does not make. Plain, warm, direct.

Reply with one JSON object and nothing else:
{"beats":[{"screen":"…","parts":[{"type":"…","text":"…"}],"word":"…","line":"…"}],"hook":[],"problem":[],"meetLine":"","proof":[],"end":{"line":"…"}}
''';
  }

  /// Asks Claude; returns its JSON object, or throws with what went wrong.
  Future<Map<String, Object?>> draft({
    required Map<String, Object?> spec,
    required String brief,
    required bool all,
    required Map<String, Object?>? catalogue,
  }) async {
    final text = prompt(
      spec: spec,
      brief: brief,
      all: all,
      catalogue: catalogue,
    );
    final ProcessResult r;
    try {
      r = await Process.run(
        'claude',
        ['-p', text, '--output-format', 'json'],
        workingDirectory: project.root.path,
      ).timeout(const Duration(minutes: 3));
    } on ProcessException {
      throw const CliError(
        'Claude Code is not installed here (`claude` was not found). Write '
        'the story by hand, or install Claude Code.',
      );
    }
    if (r.exitCode != 0) {
      throw CliError('Claude did not answer: ${r.stderr}'.trim());
    }
    final out = jsonDecode('${r.stdout}') as Map<String, Object?>;
    final result = '${out['result'] ?? ''}';
    final start = result.indexOf('{');
    final end = result.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw CliError('Claude answered without a draft: $result');
    }
    return jsonDecode(result.substring(start, end + 1)) as Map<String, Object?>;
  }
}
