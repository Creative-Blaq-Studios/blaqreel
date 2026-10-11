import 'dart:convert';
import 'dart:io';

import 'claude_run.dart';
import 'project.dart';

/// Drafts a reel with Claude Code (`claude -p`) on the person's machine:
/// the words for chosen beats, or the whole thing — screens, parts and
/// words — from a brief. It is given the app's own copy and the parts the
/// map found, and told to claim nothing the app does not do.
class Drafter {
  /// The app.
  final Project project;

  /// Told of every step of every Claude run, as it happens.
  final void Function(ClaudeRun run)? onUpdate;

  /// A drafter.
  Drafter(this.project, {this.onUpdate});

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
          'kind': s['kind'] ?? 'screen',
          'parts': [
            for (final p in (s['parts']! as List).cast<Map<String, Object?>>())
              {'type': p['name'], 'text': p['text']},
          ],
        },
    ];
    // The person's own beats, each with its screen's parts to choose from.
    final byId = {for (final sc in screens) '${sc['id']}': sc};
    final chosen = [
      for (final b
          in (spec['beats'] as List? ?? const []).cast<Map<String, Object?>>())
        {
          'screen': b['screen'],
          'kind': byId['${b['screen']}']?['kind'] ?? 'screen',
          'partsChosen': b['parts'] ?? const [],
          'partsToChooseFrom': byId['${b['screen']}']?['parts'] ?? const [],
        },
    ];
    return '''
You are writing a promo reel for the Flutter app "${project.name}" with BlaqReel.
Pack: $pack. Format: ${spec['format'] ?? 'vertical'}.

The person's brief:
${brief.isEmpty ? '(none given: make the strongest case for the app)' : brief}

What the app really does, in its own words (use only claims found here):
${_copy()}

${all && chosen.isNotEmpty
        ? '''The person chose these screens, in this order. Keep every beat: the same screen, in the same order, one answer per beat. For each, pick 1 to 3 of that screen's parts to feature (keep the parts already chosen, if any), copying "type" and "text" exactly as listed; choose a "move"; and write its words. A "component" beat has no parts: leave "parts" empty.

Beats, each with its screen's parts:
${const JsonEncoder.withIndent(' ').convert(chosen)}'''
        : all
        ? '''Choose 4 to 6 beats. For each beat pick one screen by "id" from the screens below, and 1 to 3 of that screen's parts to feature, copying "type" and "text" exactly as listed. Each part should show what its beat is about; prefer cards, rows and photos over buttons and bars. A "component" is one piece of the app shown large on its own (a button going into its loading state, a loading placeholder): its beat has no parts, so leave "parts" empty, and use one only where the brief is about how the app feels.

Screens:
${const JsonEncoder.withIndent(' ').convert(screens)}'''
        : '''The beats are chosen already (screens and parts below). Keep them, in order, and write their words.

Beats:
${const JsonEncoder.withIndent(' ').convert(spec['beats'] ?? [])}'''}

Rules: ${_packRules[pack] ?? _packRules['glass']}
Each beat may have "move", how its parts leave the screen: "lift" (straight up), "sweep" (up, with a scan line reading the first: for a receipt or a document), "spread" (pulled apart round the phone: for showing several things at once), "fan" (gathered and fanned like cards: for a set of similar items), "zoom" (the first comes forward large: for one figure or answer), "tap" (a finger picks the first: for something you press), "pop" (one by one with a spring: for quick wins), "orbit" (the camera circles while they lift: for a big moment). Vary them; don't use one move for every beat.
Also write "end": {"line": a closing line of at most six words}.
No numbers, testimonials or claims the copy above does not make. Plain, warm, direct.

Reply with one JSON object and nothing else:
{"beats":[{"screen":"…","parts":[{"type":"…","text":"…"}],"move":"…","word":"…","line":"…"}],"hook":[],"problem":[],"meetLine":"","proof":[],"end":{"line":"…"}}
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
    final run = await runClaude(
      project,
      task: all ? 'Drafting the whole reel' : 'Drafting the words',
      prompt: text,
      timeout: const Duration(minutes: 3),
      onUpdate: onUpdate,
    );
    if (!run.ok) {
      throw CliError('Claude did not answer: ${run.error ?? run.result}');
    }
    final result = run.result ?? '';
    final start = result.indexOf('{');
    final end = result.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw CliError('Claude answered without a draft: $result');
    }
    final draft =
        jsonDecode(result.substring(start, end + 1)) as Map<String, Object?>;
    final beats = (draft['beats'] as List?)?.length ?? 0;
    run.result = all ? 'Drafted $beats beats' : 'Drafted the words';
    run.steps.add(ClaudeStep(run.result!, 'note'));
    onUpdate?.call(run);
    return draft;
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

1. Find each widget in lib/ (or the app's shared UI package). If a description fits several, take the one a person would mean. A sheet or a dialog is staged open, the way the app shows it: over the screen it opens from, or on its own if that reads better.
   A component is a piece of the app shown on its own, large, with no phone around it: register it with `ReelScreen.component(widget, label: …, size: Size(w, h), taps: […])`. The widget is used the way the app uses it, centred (`Center(child: …)`), on no background; `size` is the box it is laid out in, a little larger than the widget. If it has a state worth seeing, bring it out: a button that shows a spinner while its onTap's future runs gets an onTap that waits about 1.8 seconds and `taps: [Tap(where: Pick.type<TheButton>(), at: 2.s, press: true)]`; something that animates by itself (a pulsing placeholder) needs nothing. Use the values the app's component showcase (a playground or widgetbook) gives it, if it has one.
2. Stage it the way the other screens in app_reels/screens.dart and app_reels/kit.dart are staged: the real widget in a good demo moment, using the store-screenshot harnesses' demo data under app_shots/ if there is any (ids, fake data), the test fakes, and no network. If its constructor needs arguments, use the demo data's ids. If it needs a provider overridden to show something worth seeing, wrap it in a ProviderScope with that override, as sayItScreen does.
3. Register each in the `screens` map in app_reels/kit.dart with a short lowercase id and a label people would recognise.
4. Run `dart analyze app_reels` from this folder and fix what it reports.

Edit only files under app_reels/. Never change lib/ or anything else.
Reply with one line per screen: the id you used, and what it shows.
""";
    final count = items.isNotEmpty ? items.length : 1;
    final run = await runClaude(
      project,
      task:
          'Staging ${count == 1 ? (items.isNotEmpty ? items.first['name'] : name ?? 'a screen') : '$count screens'}',
      prompt: prompt,
      args: const [
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
      onUpdate: onUpdate,
    );
    if (!run.ok) {
      throw CliError('Claude could not stage it: ${run.error ?? run.result}');
    }
    return run.result ?? '';
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
              'Then its own reusable widgets worth showing on their own, as kind "component": '
              'buttons (with their loading state), loading placeholders and spinners, progress rings and bars, '
              'badges, notices, amount displays — from its shared UI library and component showcase '
              '(a playground or widgetbook) if it has one. One item per widget class, not per variant. '
              'Leave out pure plumbing: error pages, settings sub-pages nobody films, layout helpers.'
        : 'Find the place in this app the person describes as: "$lookFor". '
              'It may be a screen, a sheet, a dialog, or one of its own widgets shown on its own (kind "component": '
              'a button, a spinner, a loading placeholder). List just that (or the few that fit).';
    final prompt =
        '''
$ask

Reply with one JSON array and nothing else. Each item:
{"name": "the widget class", "kind": "screen" | "sheet" | "dialog" | "component", "file": "its path from this folder",
 "route": "its router location, or null", "description": "what a person sees there, in under twelve words"}
''';
    final ClaudeRun run;
    try {
      run = await runClaude(
        project,
        task: lookFor == null
            ? 'Taking the inventory'
            : 'Looking for "$lookFor"',
        prompt: prompt,
        args: const ['--allowedTools', 'Read', 'Grep', 'Glob'],
        timeout: const Duration(minutes: 6),
        onUpdate: onUpdate,
      );
    } on CliError {
      return _scan();
    }
    if (!run.ok) return _scan();
    final result = run.result ?? '';
    void say(String summary) {
      run.result = summary;
      run.steps.add(ClaudeStep(summary, 'note'));
      onUpdate?.call(run);
    }

    final start = result.indexOf('[');
    final end = result.lastIndexOf(']');
    if (start < 0 || end <= start) return _scan();
    final found = [
      for (final i in jsonDecode(result.substring(start, end + 1)) as List)
        (i as Map).cast<String, Object?>(),
    ];
    say(
      found.isEmpty
          ? 'Found nothing that fits'
          : lookFor == null
          ? 'Listed ${found.length} places'
          : 'Found ${found.map((i) => i['name']).join(', ')}',
    );
    return found;
  }

  /// The inventory without the AI: every widget named …Screen, …Sheet or
  /// …Dialog in lib/.
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
