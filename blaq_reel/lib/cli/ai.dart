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

  /// Stages a screen the kit does not have yet, by asking Claude Code to
  /// edit `app_reels/`: the screen [name] from [file], or one matching
  /// [description]. Returns Claude's one-line summary.
  ///
  /// Claude may read anything, edit only with the file tools, and run only
  /// `dart analyze` and `dart format`; it is told to touch nothing outside
  /// `app_reels/`.
  Future<String> stageScreen({
    String? name,
    String? file,
    String? description,
    List<Map<String, Object?>> items = const [],
  }) async {
    final list = [
      for (final i in items)
        '- ${i['name']} (${i['kind']}, ${i['file']}): ${i['description'] ?? ''}',
    ].join('\n');
    final wanted = items.isNotEmpty
        ? "these from the app's inventory (app_reels/inventory.json):\n$list\n"
        : name != null
        ? 'the screen `$name`${file == null ? '' : ' (in `$file`)'}'
        : 'the screen the person describes as: "$description"';
    final prompt =
        """
Add $wanted to this Flutter app's BlaqReel kit, so the studio can use them in promo reels.

1. Find each widget in lib/. If a description fits several, take the one a person would mean. A sheet or a dialog is staged open, the way the app shows it: over the screen it opens from, or on its own if that reads better.
2. Stage it the way the other screens in app_reels/screens.dart and app_reels/kit.dart are staged: the real widget in a good demo moment, using the store-screenshot harnesses' demo data under app_shots/ if there is any (ids, fake data), the test fakes, and no network. If its constructor needs arguments, use the demo data's ids. If it needs a provider overridden to show something worth seeing, wrap it in a ProviderScope with that override, as sayItScreen does.
3. Register each in the `screens` map in app_reels/kit.dart with a short lowercase id and a label people would recognise.
4. Run `dart analyze app_reels` from this folder and fix what it reports.

Edit only files under app_reels/. Never change lib/ or anything else.
Reply with one line per screen: the id you used, and what it shows.
""";
    final ProcessResult r;
    try {
      r = await Process.run(
        'claude',
        [
          '-p',
          prompt,
          '--output-format',
          'json',
          '--permission-mode',
          'acceptEdits',
          '--allowedTools',
          'Read',
          'Grep',
          'Glob',
          'Edit',
          'Write',
          'Bash(dart analyze:*)',
          'Bash(dart format:*)',
        ],
        workingDirectory: project.root.path,
      ).timeout(const Duration(minutes: 8));
    } on ProcessException {
      throw const CliError(
        'Claude Code is not installed here (`claude` was not found). Stage '
        'the screen in app_reels/kit.dart by hand.',
      );
    }
    if (r.exitCode != 0) {
      throw CliError('Claude could not stage it: ${r.stderr}'.trim());
    }
    final out = jsonDecode('${r.stdout}') as Map<String, Object?>;
    return '${out['result'] ?? ''}'.trim();
  }

  /// Reads the app — its router, its screens, sheets and dialogs — and
  /// lists the places worth showing in a reel, by name, without staging
  /// any. With [lookFor], finds just what matches that description.
  /// Read-only: Claude may read and search, nothing else.
  Future<List<Map<String, Object?>>> inventory({String? lookFor}) async {
    final ask = lookFor == null
        ? 'List every place in this app a person can see that is worth showing in a promo reel: '
              'screens (start from the router, then lib/ for widgets named …Screen or …Page), '
              'bottom sheets and dialogs that do something a person would want to see. '
              'Leave out pure plumbing: splash, error pages, loading states, settings sub-pages nobody films.'
        : 'Find the place in this app the person describes as: "$lookFor". '
              'It may be a screen, a sheet or a dialog. List just that (or the few that fit).';
    final prompt =
        '''
$ask

Reply with one JSON array and nothing else. Each item:
{"name": "the widget class", "kind": "screen" | "sheet" | "dialog", "file": "lib/… path",
 "route": "its router location, or null", "description": "what a person sees there, in under twelve words"}
''';
    final ProcessResult r;
    try {
      r = await Process.run(
        'claude',
        [
          '-p',
          prompt,
          '--output-format',
          'json',
          '--allowedTools',
          'Read',
          'Grep',
          'Glob',
        ],
        workingDirectory: project.root.path,
      ).timeout(const Duration(minutes: 6));
    } on ProcessException {
      return _scan();
    }
    if (r.exitCode != 0) return _scan();
    final result = '${(jsonDecode('${r.stdout}') as Map)['result'] ?? ''}';
    final start = result.indexOf('[');
    final end = result.lastIndexOf(']');
    if (start < 0 || end <= start) return _scan();
    return [
      for (final i in jsonDecode(result.substring(start, end + 1)) as List)
        (i as Map).cast<String, Object?>(),
    ];
  }

  /// The inventory without the AI: every widget named …Screen in lib/.
  List<Map<String, Object?>> _scan() {
    final lib = Directory('${project.root.path}/lib');
    if (!lib.existsSync()) return const [];
    final pattern = RegExp(r'class (\w+(?:Screen|Sheet|Dialog))\b');
    return [
      for (final f in lib.listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          for (final m in pattern.allMatches(f.readAsStringSync()))
            {
              'name': m.group(1),
              'kind': m.group(1)!.endsWith('Sheet')
                  ? 'sheet'
                  : m.group(1)!.endsWith('Dialog')
                  ? 'dialog'
                  : 'screen',
              'file': f.path.substring(project.root.path.length + 1),
              'route': null,
              'description': null,
            },
    ];
  }
}
