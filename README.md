# BlaqReel

**Promo videos made from a Flutter app's real screens.**

BlaqReel turns the screens you already built into short videos for social
media, YouTube and websites: real widgets floating in 3D, a moving camera,
words that arrive on the beat, typing, taps and sound. It is not a screen
recorder and not a mock-up tool. Every frame is your app's own widget tree,
drawn by Flutter inside `flutter test` on a fixed clock and encoded by
FFmpeg. Change the app, render again, and the video follows.

It is a dev dependency. Nothing ships in your app, and `lib/` is never
touched: everything lives in the app's own `app_reels/` folder.

> Status: 0.5, in use on Khumio, Creative Blaq Studios' finance app. Private
> repository; no licence chosen yet. BlaqReel is a working name.

---

## Contents

- [What's in this repository](#whats-in-this-repository)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Set it up in an app](#set-it-up-in-an-app)
- [Three ways to make a reel](#three-ways-to-make-a-reel)
- [The studio](#the-studio)
- [The builder, step by step](#the-builder-step-by-step)
- [Reels as data: the spec](#reels-as-data-the-spec), including [media](#media)
- [Reels as code](#reels-as-code)
- [The command line](#the-command-line)
- [Output](#output)
- [Length, pace and sound](#length-pace-and-sound)
- [Style packs](#style-packs)
- [The building blocks](#the-building-blocks)
- [Speed](#speed)
- [Things to know](#things-to-know)
- [Troubleshooting](#troubleshooting)
- [Developing BlaqReel](#developing-blaqreel)

---

## What's in this repository

| Path | What it is |
| --- | --- |
| [`blaq_reel/`](blaq_reel) | The Dart package: the engine (`package:blaq_reel/blaq_reel.dart`), four style packs (`package:blaq_reel/packs.dart`), and the command-line tool (`dart run blaq_reel …`) with the browser studio. |
| [`skill/blaq-reel/`](skill/blaq-reel) | An agent skill for Claude Code, Codex, Cursor or any AI agent: it sets BlaqReel up in an app and makes reels by conversation, step by step, offering generated media when the agent can make images or video. |
| [`AGENTS.md`](AGENTS.md) | The rules for AI agents working on BlaqReel itself. |

## How it works

```
 your app's screens ──► host.dart ──► the stage ──► flutter test ──► FFmpeg ──► MP4
 (real widgets,         (theme,       (3D layers,    (one frame      (encode, sound,
  demo data)            fonts, fakes)  camera, words) at a time)      every format)
```

1. **The host** (`app_reels/host.dart`) wraps any screen the way the app
   draws it: theme, fonts, providers, demo data. It is usually the same
   set-up your widget tests or store screenshots already use.
2. **A reel** is a run of scenes. Each scene places screens and widgets in
   3D, points a camera at them, lifts parts of a screen toward the viewer,
   types into real fields, taps real buttons, and sets words over it all.
3. **The renderer** runs inside `flutter test`, moves a fake clock one frame
   at a time, captures each frame and pipes it to FFmpeg, then mixes the
   music, voice-over and sound effects.

Because it is the real widget tree, a lifted card is the real card, an
amount typed into a money field is formatted by the app, and a reel never
goes stale when the design changes.

## Requirements

| Needed | For | Install |
| --- | --- | --- |
| Flutter 3.44 or newer (Dart 3.12+) | everything | flutter.dev |
| FFmpeg with libx264 | encoding, sound | `brew install ffmpeg` |
| Claude Code (`claude`), signed in | the AI features: drafting, writing an intro, finding and staging screens | claude.com/claude-code |
| macOS speech voices | placeholder voice-over only | built in |

`dart run blaq_reel doctor` checks all of it.

## Set it up in an app

These steps assume a Flutter app at `my_app/`.

### 1. Add the dependency

From the repository (it is private, so the machine needs access, e.g.
`gh auth login`):

```yaml
# my_app/pubspec.yaml
dev_dependencies:
  blaq_reel:
    git:
      url: https://github.com/Creative-Blaq-Studios/blaqreel.git
      path: blaq_reel
      ref: main
```

Or from a checkout beside the app, which is handier while working on
BlaqReel itself:

```yaml
dev_dependencies:
  blaq_reel:
    path: ../BlaqReel/blaq_reel
```

Then `flutter pub get`.

### 2. Create `app_reels/`

```bash
cd my_app
dart run blaq_reel init      # reel.yaml, host.dart, render_test.dart, a first reel, REELS.md
dart run blaq_reel doctor    # FFmpeg, Flutter, app_reels/
```

`init` keeps files that are already there (`--force` overwrites) and, with
Claude Code, takes an inventory of the app's screens (`--no-ai` skips it).

`app_reels/reel.yaml` holds the reel's settings and the brand:

```yaml
name: My App
fps: 30
format: vertical          # vertical, wide, square or portrait
out: app_reels/out
ffmpeg: /opt/homebrew/bin/ffmpeg
music: pad                # a synthesized placeholder; or a path to a track
sound: app_reels/sound    # built-in sound effects and the pad

brand:
  ink: "#17181A"
  accent: "#FFD97A"
  paper: "#F1F1F3"
  fonts:
    display: packages/my_shared/Gabarito
    text: packages/my_shared/PlusJakartaSans
```

### 3. Write the host

`app_reels/host.dart` is the one adapter between the app and BlaqReel:

```dart
final host = ReelHost(
  // Every screen, and every lifted widget, is drawn through this.
  wrap: (screen) => ProviderScope(
    overrides: demoOverrides,            // fake data, no network
    child: MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: Material(type: MaterialType.transparency, child: screen),
    ),
  ),
  // Optional: runs once mounted (warm an image cache, open a gate).
  ready: (tester) async {},
  // Optional: runs once lifted widgets are in place (icons decode again).
  settle: (tester) async {},
);
```

### 4. Offer screens to the studio: the kit

The studio's builder works from a **kit**: the screens and components a
reel can use, the logos, and touches every reel of the app shares. Write
`app_reels/kit.dart` and pass it to `blaqReelMain` in
`app_reels/render_test.dart`:

```dart
final kit = ReelKit(
  screens: {
    'home': const ReelScreen(HomeScreen(), label: 'Home'),
    'add': const ReelScreen(AddExpenseScreen(), label: 'Add expense'),
    // A piece of the app shown large on its own, doing what it does.
    'save': ReelScreen.component(
      AppBtn.filled(title: 'Save', onTap: () => Future.delayed(1800.ms)),
      label: 'Save button',
      size: const Size(320, 64),
      taps: [Tap(where: Pick.type<AppBtn>(), at: 1.s, press: true)],
    ),
  },
  // Built from the clock, so they animate: `mark` opens a reel,
  // `wordmark` ends it.
  logos: {
    'mark': (t, color) => AppMark(color: color, progress: progress(t, 150.ms, 1500.ms)),
    'wordmark': (t, color) => AppWordmark(color: color, progress: progress(t, 600.ms, 1700.ms)),
  },
  logoSizes: const {'mark': Size(220, 220), 'wordmark': Size(340, 110)},
  statusBar: const MyStatusBar(),   // drawn over every screen
  liftRadius: 24,                   // the app's card corners
  url: 'myapp.com',                 // the end card's address
);
```

```dart
// app_reels/render_test.dart
void main() {
  final config = ReelConfig.load('app_reels/reel.yaml');
  blaqReelMain(config: config, host: host, kit: kit, reels: {});
}
```

`init` does not write `kit.dart` yet. Ask Claude Code to "set BlaqReel up
in this app" (the skill writes it), or write it by hand. Once it exists,
the studio's **Screens → Add from the app** finds more screens and stages
them for you. Khumio's `app_reels/kit.dart` is a full example.

### 5. Tell the AI what the app does

Write `app_reels/copy.md`: what the app really does, in its own words. The
AI drafts only from claims it finds there.

### 6. Give the skill to your AI agent (once per machine)

The skill (`skill/blaq-reel/`) is plain Markdown any agent can follow:
`SKILL.md` for the workflow, `reference.md` for the facts. Point your agent
at it:

| Agent | How |
| --- | --- |
| Claude Code | `ln -s /path/to/BlaqReel/skill/blaq-reel ~/.claude/skills/blaq-reel` |
| Codex CLI | add to the app's `AGENTS.md` (or `~/.codex/AGENTS.md`): *"For promo videos, follow `/path/to/BlaqReel/skill/blaq-reel/SKILL.md` and its `reference.md`."* |
| Cursor | a rule in `.cursor/rules/blaq-reel.mdc` saying the same, or add the two files to the chat |
| Any other | give it the two files and ask it to follow `SKILL.md` |

An agent that can generate images or video will offer to make media for
the reel: a background, a hand for the taps, stickers, a looping clip.

## Three ways to make a reel

| Way | Best for | Start with |
| --- | --- | --- |
| **The studio's builder** | Making it yourself, with the AI drafting as much or as little as you want | `dart run blaq_reel studio`, then **Build** |
| **An AI agent** (Claude Code, Codex, Cursor…) | Describing it and deciding at each step, no studio needed | "Make a 30-second promo for this app" |
| **Dart** | Full control, custom scenes, new packs | a file in `app_reels/cuts/` |

All three render the same way. The builder and the skill save a reel as
data in `app_reels/specs/<name>.json`; Dart reels are registered in
`render_test.dart`.

## The studio

```bash
dart run blaq_reel studio [<reel>]     # http://localhost:4455
```

| Option | Default | |
| --- | --- | --- |
| `--format`, `-f` | the reel's | the format to preview |
| `--port` | 4455 | |
| `--[no-]watch` | on | render again when a file under `app_reels/` or `lib/` changes |
| `--[no-]open` | on | open the browser |

**Library** shows every rendered video and every reel. Pick a reel to work
on it live: a quick preview renders, and saving a file renders it again.
The timeline shows scenes, transitions, words, sound cues and voice-over.
A rendered video has **Reveal in Finder** and **Open**; **Clean up…** clears
out working files, and older finals if you choose, showing what goes and
how much space it frees first.

| Key | In the Library |
| --- | --- |
| Space | play, pause |
| ← → | one frame |
| ⇧ ← → | one second |
| `[` `]` | previous, next scene |
| S | a full-size still at the playhead |
| C | copy the time, for notes |
| R | render the preview again |
| L | loop the scene |

**Build** is the builder, below. Whenever the studio asks Claude Code for
something, it runs a headless session on your own Claude Code in the app's
folder, and a **Claude Code** panel shows each step live, the files it
changed, and the command to reopen the session.

## The builder, step by step

1. **Screens.** Every screen and component the kit offers, drawn for real.
   Each one you add becomes a beat. **Add from the app** lists what the AI
   found in the app and stages the ones you pick.

2. **Brief & style.** Name, style pack, frame, **Length** (say 30 s; every
   beat stays and plays faster to fit), **Sound** (Music & effects,
   Effects only, Silent), what the reel should get across, and who writes
   the story: the AI, you then the AI, or you.

3. **Ground.** What the screens sit on: a look (ink, mesh, butter, echo,
   studio, grid) or a moving ground, one of ten patterns (drift, aurora,
   breathe, orbit, light sweep, bokeh, grid flow, liquid mesh, ribbons,
   light rays) in a palette, at a pace, with film grain or a pulse on the
   beat. **Generate** makes new grounds from the brand's colours. A beat can
   have its own.

4. **Parts.** Each beat in two modes. **Pick**: the screen with its cards,
   rows, fields and photos numbered; click what to feature, in order.
   **Animate**: the timeline editor.
   - **The frame.** The beat plays live in its real frame (9:16, 4:5, 1:1,
     16:9) using the renderer's own camera, timing and word layout, so
     what you set is what renders. **Safe** shows the platform's safe zone.
   - **The move.** Start from one (Lift, Lift + scan, Spread, Fan, Zoom
     in, Tap, Pop, Orbit). Then give each part its own landing place (drag
     it), height, size, tilt, turn, roll, start, rise time, scan line, and
     layer (bring forward, send back).
   - **Typing.** A part holding a text field can type into it, as a
     keyboard does: "5000" in a money field shows R5,000.00.
   - **The words.** Colour, accent (`{braces}`), size, weight, reveal,
     timing, and a place per frame: drag them (they snap to the safe zone
     and the centre), anchor them, set a width, a plate, or put them behind
     the phone. The editor warns when they cover a part.
   - **The timeline.** Drag a bar to retime it; drag the beat's end to set
     its length. Numbers scrub like a design tool's: drag the label, or ↑ ↓,
     with Shift ×10 and Alt ×0.1. `[` `]` step through beats; Space plays.
   - **Warnings.** A part the screen no longer has, or one inside another
     lifted part (it would show twice), gets a ⚠ and a one-click remove.
   - **Render.** The editor sketches from a flat shot of each screen, which
     cannot show what the app itself does (formatting, taps). **Render**
     renders just this beat with the real screens in about five seconds
     and plays it over the frame.
   - **Skip** leaves a beat out of the video and keeps it in the reel.
   - **Intro and Outro** sit either side of the beats. The intro can say
     up to three hook lines before the logo, written by you or by the AI
     from a description. The outro is the end card: logo, line, address,
     the reel's screens fanned behind it, and how soft they are. Every
     piece can be clicked, dragged and styled like the beat's words, and
     each logo plays its own animation (or zooms in). Both keep the exact
     seconds you give them.

5. **Story.** The words per beat and the end card; for a Story Ad, the
   hook, problem and proof. **Draft with the AI** writes them from the brief,
   the parts and `copy.md`; **Let the AI build it** picks screens, parts and
   words from the brief alone.

6. **Preview.** The reel plays in a theatre at its own shape, with a scrub
   bar marked at each beat (click a chip to jump, double-click to edit that
   beat). **Export**: tick the formats, choose the sound and Full or Quick,
   and **Render N finals**.

## Reels as data: the spec

A reel the builder makes is `app_reels/specs/<name>.json`. Parts are found
by the names the map gives them, so a spec needs no Dart. Specs whose name
starts with `_` are the studio's scratch files and stay out of the lists.

```json
{
  "pack": "glass",
  "format": "vertical",
  "look": "mesh",
  "length": 30,
  "sound": "effects",
  "open": { "logo": "mark", "lines": ["Who paid for {groceries}?"], "length": 3.4 },
  "beats": [
    {
      "screen": "add",
      "word": "Add it.",
      "move": "tap",
      "parts": [
        { "type": "TextField", "to": [-9, -174], "scale": 1.18,
          "typing": { "text": "5000", "at": 4150, "every": 220 } },
        { "type": "AppCard", "text": "FOR", "layer": 2 }
      ],
      "words": { "places": { "vertical": { "pos": "bl", "dy": 9.2 } } }
    }
  ],
  "end": { "logo": "wordmark", "line": "Shared money, no awkward chats.", "length": 4.7 }
}
```

### The reel

| Key | Values | |
| --- | --- | --- |
| `pack` | `glass`, `kinetic`, `glow`, `story` | the style pack |
| `format` | `vertical`, `wide`, `square`, `portrait` | |
| `look` | `ink`, `mesh`, `butter`, `echo`, `studio`, `grid` | the ground's look |
| `ground` | a [ground](#a-ground) | a moving ground for the whole reel |
| `words` | a [words style](#words) | how every beat's words look |
| `length` | seconds | the video's length: the beats speed up or slow down to fit; the intro and end card keep theirs |
| `pace` | number | how fast the beats play, if `length` is not set |
| `sound` | `all`, `effects`, `silent` | silent renders no audio track |
| `music` | `none`, or a path | `none` is the same as `"sound": "effects"` |
| `open` | an [intro](#the-intro-and-the-end), a logo name, or `false` | |
| `end` | an [end card](#the-intro-and-the-end) | |
| `flip` | `true` | the beats swing the other way, first to the left |
| `motionBlur` | frames | blended per output frame |
| `hook`, `problem`, `meetLine`, `proof` | lines | Story Ad only |

### A beat

| Key | |
| --- | --- |
| `screen` | the kit's id for the screen or component |
| `word` | its words (Glass Layers, Story Ad); `line` for Kinetic Launch and Dark Glow |
| `parts` | what lifts, in order: [parts](#a-part) |
| `move` | `lift`, `scan`, `spread`, `fan`, `zoom`, `tap`, `pop`, `orbit` |
| `length` | seconds; 5.6 by default |
| `words` | its own [words style](#words), over the reel's |
| `look`, `ground` | its own ground |
| `zoom`, `framing` | the screen's size and place in frame |
| `media` | [pictures and clips](#media) in this beat |
| `type`, `typeInto` | text typed into a field that stays on the screen, and which field |
| `skip` | `true` leaves it out of the video |

### A part

| Key | |
| --- | --- |
| `type`, `text`, `nth` | which widget: its type, the text inside it, and which of several |
| `to` | `[x, y]` where it lands, from the screen's centre |
| `z`, `scale`, `tilt`, `turn`, `roll` | height, size, rotation in degrees |
| `delay`, `rise` | ms after the screen settles; ms to rise |
| `scan` | `true` for a scan line as it rises |
| `layer` | stacking among the beat's parts, whatever their heights |
| `typing` | `{ "text", "at" (ms into the beat), "every" (ms a key), "sound" }` |

### Words

`color`, `accent`, `size` (80 is a beat word in 9:16), `weight` (100–900),
`reveal` (`letters`, `words`, `type`, `fade`), `at`, `until` (seconds),
`plate` (`none`, `soft`, `solid`), `layer` (`behind` for behind the phone),
and `places`, one per format: `{ "vertical": { "pos": "bl", "dx": 0, "dy": 5, "width": 80 } }`.
`pos` is two letters, `t`/`m`/`b` then `l`/`c`/`r`; `dx`, `dy` and `width`
are percentages of the frame.

### The intro and the end

| Key | Intro (`open`) | End card (`end`) |
| --- | --- | --- |
| `logo` | `mark` by default; `null` for none | `wordmark` by default; `null` for none |
| `length` | seconds; about 1.4 a line, plus 2 for a logo | 4.7 |
| `lines`, `reveal` | hook lines before the logo, and how they arrive | |
| `line`, `url` | | a closing line; the address (`false` for none, the kit's by default) |
| `words` | the lines' style | |
| `lineWords`, `urlWords` | | the line's and address's style |
| `logoScale`, `logoPlaces` | the logo's size, and place per format | same |
| `entrance` | `zoom` for the studio's zoom on top of the logo's own animation | same |
| `fan`, `blur` | | the screens fanned behind it (`false` for none), and how soft (0–4) |
| `off` | `true` turns it off and keeps its settings | same |

### A ground

```json
{ "pattern": "mesh", "speed": 1, "seed": 7, "beat": 120, "grain": true,
  "palette": { "top": "#F5E6C8", "bottom": "#E8E2F4",
               "colours": ["#FFD97A", "#F2A65A", "#C9B8F0"], "light": true } }
```

`pattern` is one of `drift`, `aurora`, `breathe`, `orbit`, `sweep`,
`bokeh`, `grid`, `mesh`, `ribbons`, `rays`. `beat` pulses the first colour
at that tempo. Light grounds take dark words.

### Media

Pictures and clips, generated by an AI or your own, live in
`app_reels/media/`:

```json
"ground": {"image": "app_reels/media/bg.png", "dim": 0.2},
"hand": {"image": "app_reels/media/hand.png", "tip": [0.32, 0.04], "width": 200},
"media": [
  {"image": "app_reels/media/spark.png", "box": [70, 8, 22, 12],
   "at": 1.2, "until": 4, "move": "float"},
  {"frames": "app_reels/media/waves", "fps": 30, "box": [0, 0, 100, 100],
   "behind": true, "fit": "cover", "opacity": 0.6}
]
```

- **A ground picture** fills the frame behind everything and breathes
  slowly; `dim` darkens it (or lightens a light one) so screens and words
  read on it.
- **A hand** does every tap in place of the round fingertip; `tip` is where
  its fingertip is in the picture, as fractions.
- **Media** go on the reel, a beat, the intro or the end card: a picture, or
  a folder of frames (`dart run blaq_reel media frames clip.mp4 --name
  waves` turns a video into one). `box` is left, top, width and height in
  percent of the frame; `at` and `until` in seconds; `behind` puts it behind
  the screens; `move` is `none`, `float`, `rise`, `drift`, `zoom`, `spin` or
  `pop`; `fit` is `contain`, `cover` or `fill`.

## Reels as code

A Dart reel is a function from a format to a `Reel`, registered in
`render_test.dart`:

```dart
// app_reels/cuts/promo.dart
Reel promo(ReelConfig config, Format format) => GlassLayers(
  brand: Brand.from(config),
  format: format,
  open: (t) => AppMark(progress: progress(t, 150.ms, 1500.ms)),
  beats: [
    GlassBeat(
      'Share.',
      screen: homeScreen,
      lift: [Pick.type<WalletSummaryCard>()],
      move: GlassMove.spread,
    ),
    GlassBeat(
      'Add it.',
      screen: const AddExpenseScreen(),
      lift: [Pick.type<TextField>()],
      partMoves: [PartMove(typing: PartTyping('186'))],
    ),
  ],
  end: GlassEnd(logo: (t) => const AppWordmark(), logoSize: const Size(340, 110),
      line: 'Shared money, no awkward chats.'),
).build('promo');
```

```dart
reels: {'promo': (format) => promo(config, format)},
```

Below the packs, scenes can be written directly with layers, cameras and
tracks: see [The building blocks](#the-building-blocks) and the skill's
`reference.md`.

## The command line

Run from the app's folder: `dart run blaq_reel <command>`.

| Command | What it does |
| --- | --- |
| `init` | Write `app_reels/`. `--force` overwrites; `--no-ai` skips the inventory. |
| `doctor` | Check FFmpeg, Flutter and `app_reels/`. |
| `list` | The reels, their scenes and lengths. |
| `render <reel>` | Render to MP4 and print where each video went, with a link. `-f vertical,wide`, `-f all`, `--fps`, `--no-audio`, `--open`, `--reveal` (show it in Finder). |
| `stills <reel> --at 1,3.5` | PNG stills at those seconds. |
| `studio [<reel>]` | The studio, above. |
| `map <reel>` | Every screen in a reel with each part that could be featured, numbered, on a page. |
| `looks <reel> --at 4.2` | That moment on every Glass Layers ground, side by side. |
| `storyboard <reel>` | A frame per scene with its timing, words and sounds, and room for notes. |
| `inventory` | The app's screens, sheets and dialogs worth showing, found with Claude Code, into `app_reels/inventory.json`. `--find "the settings sheet"` looks for one. |
| `sfx` | Write the built-in sounds; `--pad 30` also writes a 30-second placeholder pad. |
| `voice` | Placeholder voice-over with the macOS voices: `--text`, `--script`, `--voice`, `--rate`. |
| `media frames <video>` | Turn a clip into frames a reel can play, in `app_reels/media/<name>/`: `--name`, `--fps`, `--width`. |
| `clean` | Clear out `app_reels/out/`: scratch previews, stills, pages, thumbnails, stray files. `--finals` also removes older finished videos, keeping the newest (`--keep 3` keeps three); `--dry-run` lists what would go. |

## Output

Everything goes to `app_reels/out/` (git-ignored):

| File | |
| --- | --- |
| `<reel>.mp4` | the final, in reel.yaml's format |
| `<reel>-<format>.mp4` | finals in the other formats |
| `stills/` | stills |
| `studio/` | previews, the catalogue of screens and logos, the render worker's jobs |
| `last.log` | the last render's full log |

A new render of the same reel and format replaces the old file; `clean`
clears out the rest (see the command line). Finals are
1080p H.264 with motion blur and a little grain against banding; Quick
finals are half size. Sound is mixed to −16 LUFS.

## Length, pace and sound

- **Length.** Say how long the video should be. Every beat stays; the beats
  play faster or slower to fit. The intro and the end card keep exactly the
  seconds they are given, so a 30-second reel with a 2-second intro and a
  4-second end card gives the beats the other 24. Music and voice-over keep
  their speed; sound effects move with their moments.
- **The intro and outro** are timed to the second, and the logos play their
  own animation from when they appear.
- **Sound.** Music & effects, Effects only, or Silent (no audio track).
  Effects are made by FFmpeg: taps, ticks, whooshes, a chime, a rise. The
  music is a synthesized pad until `music:` in reel.yaml points at a track.

## Style packs

`import 'package:blaq_reel/packs.dart';` Each pack is a cut with slots:
give it a brand, screens and words; it supplies the camera, timing,
transitions and layout for each format.

| Pack | Shape |
| --- | --- |
| `GlassLayers` | Intro → beats: one word each, the screen's cards lift off as glass layers, focus follows them → end card over the screens fanned out. The studio's main pack. |
| `KineticLaunch` | Lines arrive word by word with the key part in the accent; devices sweep in beside them. |
| `DarkGlow` | One unbroken camera past glowing screens on a dark ground, a title and line at each. |
| `StoryAd` | Hook → problem → meet the app → Glass beats → proof → call to action, with voice-over per part and the music ducked under it. |

## The building blocks

`import 'package:blaq_reel/blaq_reel.dart';`

| Block | |
| --- | --- |
| `Reel`, `Scene`, `Transition` | Scenes on their own clocks, overlapping through cut, fade, swing, zoom-through, wipe or rise. `Reel.pace` and `steady` scenes set how fast it plays. |
| `Layer.screen`, `Layer.component`, `Layer.timed`, `Motion`, `Glass` | A screen on a device, a piece of the app on its own, a widget rebuilt from the clock; each with its own motion tracks and a slab edge. |
| `Lift`, `Pick` | A part of a screen coming off toward the camera, live (it shows what the screen does after it lifts), found by type, text, position or nesting. |
| `Tap`, `Scroll`, `TypeText` | A finger with a ripple (and a real tap), the real scrollable scrolled, keys typed into the real field through its formatters. |
| `Camera`, `Shot`, `CameraPose` | Tilt, turn, roll, zoom, pan, focus and aperture, eased or tracked. |
| `Words`, `Reveal` | Letters or words rising, typed or faded; accent markup, wrapping, plates. |
| `Backdrop`, `GroundMotion`, `GroundPattern` | Gradient grounds, the ten moving patterns, and a picture (`image`). |
| `Media`, `MediaMove`, `TapHand`, `ReelImage` | Pictures and clips in the frame, how they move, a hand for taps, a picture decoded for the test's clock. |
| `Track`, `Ease`, `TimeWarp`, `ReelClock` | Values over time, eases, slow motion, frame `n` at `n / fps`. |
| `Soundtrack`, `Music`, `VoiceLine`, `Cue`, `Sfx` | Music, voice-over that ducks it, cues, built-in sounds. |
| `ReelHost`, `ReelKit`, `ReelSpec`, `ReelRenderer`, `blaqReelMain` | The adapter, the kit, specs, rendering, and the test entry the CLI drives. |

## Speed

The studio keeps a **render worker** running: `render_test.dart` is
compiled once when the studio starts (and again when the app's code
changes), then renders job after job. Renders skip `pub get` while the
packages are up to date.

| Render | About |
| --- | --- |
| one beat, from the editor | 5 s |
| the intro or the outro | 3–6 s |
| a 70-second preview (half size) | 50 s |
| a 30-second quick final | under a minute |
| a full 1080p final | longer: four times the pixels, and motion blur draws extra frames |

## Things to know

- **A lifted widget is a copy drawn outside its screen**, through the host's
  wrap. Inherited widgets between the screen and it (a currency scope, say)
  are not there; a row with an InkWell needs the wrap to supply `Material`.
- **Lifts are found once**, after the scene's opening scroll and typing.
- **Native views don't draw in tests** (camera previews, maps, web views,
  video players). Stage a still in their place.
- **Real I/O never finishes inside a widget test's fake clock.** Anything
  touching disk or a process in a scene goes through `tester.runAsync`.
- **The editor sketches; the renderer decides.** The editor works from flat
  shots of the screens and the logos' captured frames. Use **Render** for
  the real thing whenever the app's own behaviour matters.
- **A part from an older catalogue** may no longer exist on its screen; the
  editor flags it.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `doctor` says FFmpeg is missing or lacks libx264 | `brew install ffmpeg`, and set `ffmpeg:` in reel.yaml to its path |
| A render hangs with no error | Something awaits real I/O inside the fake clock: wrap it in `tester.runAsync` |
| A screen draws blank or throws | The host's wrap is missing a provider, theme or demo data that screen needs; the full error is in `app_reels/out/last.log` |
| The studio's Screens step is empty | There is no kit: write `app_reels/kit.dart` and pass it to `blaqReelMain` |
| A part lands in the wrong place, or twice | Check the editor's ⚠ warnings; refresh the catalogue (Screens) after the app changes |
| AI buttons fail | Install Claude Code and sign in; the studio runs `claude -p` in the app's folder |
| A preview looks out of date | The studio re-renders on save; press R, or restart it after changing BlaqReel itself |

## Developing BlaqReel

```bash
cd blaq_reel
flutter pub get
dart analyze
flutter test
dart format lib test bin
```

| Path | |
| --- | --- |
| `blaq_reel/lib/src/` | the engine: stage, renderer, scenes, camera, words, grounds, sound, spec reader, runner |
| `blaq_reel/lib/src/packs/` | the style packs |
| `blaq_reel/lib/cli/` | the command line, the studio server, its page, the builder, the editor and the AI drafter |
| `blaq_reel/test/` | engine and spec tests |
| `blaq_reel/CHANGELOG.md` | what changed, release by release |
| `skill/blaq-reel/` | the agent skill: `SKILL.md` (the workflow) and `reference.md` (the facts) |
| `AGENTS.md` | the rules for AI agents working on BlaqReel, above all: the skill and this README change with the code |

The first app is Khumio: `Khumio/khumio/app_reels/` shows a full host,
kit, Dart reels and builder specs.
