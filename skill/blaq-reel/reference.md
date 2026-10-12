# BlaqReel reference

Everything an agent needs to write and render a reel. Paths are relative
to the app's folder; commands run there as `dart run blaq_reel <command>`.

- [Setting up](#setting-up)
- [The spec](#the-spec): a reel as data, `app_reels/specs/<name>.json`
- [Media](#media)
- [The command line](#the-command-line)
- [Output](#output)
- [Reels in Dart](#reels-in-dart)

## Setting up

```yaml
# pubspec.yaml
dev_dependencies:
  blaq_reel:
    git:
      url: https://github.com/Creative-Blaq-Studios/blaqreel.git
      path: blaq_reel
      ref: main
    # or: path: ../BlaqReel/blaq_reel
```

`dart run blaq_reel init` writes `app_reels/`: `reel.yaml`, `host.dart`,
`render_test.dart`, a first reel in `cuts/`, `REELS.md`. Then:

```yaml
# app_reels/reel.yaml
name: My App
fps: 30
format: vertical          # vertical 1080×1920, wide 1920×1080, square, portrait 4:5
out: app_reels/out
ffmpeg: /opt/homebrew/bin/ffmpeg
music: pad                # a synthesized placeholder, or a path to a track
sound: app_reels/sound
brand: {ink: "#17181A", accent: "#FFD97A", paper: "#F1F1F3",
        fonts: {display: packages/my_shared/Gabarito, text: packages/my_shared/PlusJakartaSans}}
```

```dart
// app_reels/host.dart: how a screen is drawn
final host = ReelHost(
  wrap: (screen) => ProviderScope(
    overrides: demoOverrides,
    child: MaterialApp(theme: AppTheme.light, debugShowCheckedModeBanner: false,
      home: Material(type: MaterialType.transparency, child: screen)),
  ),
  ready: (tester) async {},    // once mounted: load fonts, warm caches
  settle: (tester) async {},   // once lifted parts are copied
);

// app_reels/kit.dart: what a spec can use
final kit = ReelKit(
  screens: {
    'home': const ReelScreen(HomeScreen(), label: 'Home'),
    'save': ReelScreen.component(SaveButton(), label: 'Save button',
        size: const Size(320, 64),
        taps: [Tap(where: Pick.type<SaveButton>(), at: 1.s, press: true)]),
  },
  logos: {   // built from the clock, so they animate
    'mark': (t, color) => AppMark(color: color, progress: progress(t, 150.ms, 1500.ms)),
    'wordmark': (t, color) => AppWordmark(color: color),
  },
  logoSizes: const {'mark': Size(220, 220), 'wordmark': Size(340, 110)},
  statusBar: const MyStatusBar(), liftRadius: 24, url: 'myapp.com',
);

// app_reels/render_test.dart
void main() {
  final config = ReelConfig.load('app_reels/reel.yaml');
  blaqReelMain(config: config, host: host, kit: kit, reels: {});
}
```

Every spec in `app_reels/specs/` is then a reel, by its file name. Names
starting with `_` are the studio's scratch files.

## The spec

```json
{
  "pack": "glass",
  "format": "vertical",
  "look": "mesh",
  "length": 30,
  "sound": "effects",
  "open": {"logo": "mark", "lines": ["Who paid for {groceries}?"]},
  "beats": [
    {"screen": "home", "word": "Share.", "move": "spread",
     "parts": [{"type": "WalletSummaryCard"}, {"type": "AppCard", "text": "Activity"}]},
    {"screen": "add", "word": "Add it.", "move": "tap",
     "parts": [{"type": "TextField", "typing": {"text": "186"}}]}
  ],
  "end": {"logo": "wordmark", "line": "Shared money, no awkward chats."}
}
```

### The reel

| Key | Values |
| --- | --- |
| `pack` | `glass` (Glass Layers), `kinetic` (Kinetic Launch), `glow` (Dark Glow), `story` (Story Ad) |
| `format` | `vertical`, `wide`, `square`, `portrait` |
| `look` | `ink`, `mesh`, `butter`, `echo`, `studio`, `grid` |
| `ground` | a [ground](#a-ground) for the whole reel |
| `words` | a [words style](#words) for every beat |
| `length` | seconds the video runs; the beats speed up or slow down to fit, the intro and end card keep their own |
| `pace` | how fast the beats play, when no `length` |
| `sound` | `all` (music and effects), `effects`, `silent` (no audio track) |
| `music` | `none`, or a path |
| `open` | the [intro](#the-intro-and-the-end-card), a logo's name, or `false` |
| `end` | the [end card](#the-intro-and-the-end-card) |
| `media` | [pictures and clips](#media) over the whole reel, on its clock as made |
| `hand` | a [hand](#media) for every tap |
| `flip` | `true`: the beats swing the other way, the first to the left |
| `motionBlur` | frames blended per output frame |
| `hook`, `problem`, `meetLine`, `proof` | Story Ad's lines |

### A beat

| Key | |
| --- | --- |
| `screen` | the kit's id |
| `word` | Glass Layers and Story Ad: one or two words ending in a full stop; `line` for Kinetic Launch and Dark Glow, with `{braces}` for the accent |
| `parts` | what lifts, in order: [parts](#a-part) (up to six) |
| `move` | `lift`, `scan`, `spread`, `fan`, `zoom`, `tap`, `pop`, `orbit` |
| `length` | seconds, 5.6 by default |
| `words` | this beat's [words style](#words) over the reel's |
| `look`, `ground` | its own ground |
| `media` | pictures and clips in this beat |
| `zoom`, `framing` | the screen's size, and `[x, y]` its place, in frame |
| `type`, `typeInto` | text typed into a field that stays on the screen (not lifted), and which field: `{"type": "TextField", "text": null}`; the screen's first field if no `typeInto` |
| `skip` | `true`: left out of the video, kept in the spec |

### A part

| Key | |
| --- | --- |
| `type`, `text`, `nth` | which widget: its type name, text inside it, which of several |
| `to` | `[x, y]` where it lands, from the screen's centre in screen units |
| `z` | height it rises to (100–250 typical) |
| `scale`, `tilt`, `turn`, `roll` | size, and degrees |
| `delay` | ms after the screen settles before it rises |
| `rise` | ms it takes to rise |
| `scan` | `true`: a scan line reads it as it rises |
| `layer` | stacking among the beat's parts, lowest drawn first |
| `typing` | `{"text": "186", "at": ms into the beat, "every": ms per key, "sound": false}` |

### Words

| Key | |
| --- | --- |
| `color`, `accent` | `#RRGGBB` |
| `size` | 80 is a beat word in 9:16 |
| `weight` | 100–900 |
| `reveal` | `letters`, `words`, `type`, `fade` |
| `at`, `until` | seconds into the beat |
| `plate` | `none`, `soft`, `solid` |
| `layer` | `behind` puts them behind the phone |
| `places` | per format: `{"vertical": {"pos": "bl", "dx": 0, "dy": 5, "width": 80}}`; `pos` is `t`/`m`/`b` then `l`/`c`/`r`; `dx`, `dy`, `width` are percent of the frame |

### The intro and the end card

| Key | Intro (`open`) | End card (`end`) |
| --- | --- | --- |
| `logo` | `mark` by default; `null` for none | `wordmark` by default; `null` for none |
| `length` | seconds; about 1.4 a line, plus 2 for a logo | 4.7 |
| `lines`, `reveal` | up to three hook lines before the logo, and how they arrive | |
| `line`, `url` | | the closing line; the address (`false` for none, the kit's by default) |
| `words` | the lines' style | |
| `lineWords`, `urlWords` | | the line's and address's style |
| `logoScale`, `logoPlaces` | size; place per format `{"vertical": {"dx": 0, "dy": -5}}` | same |
| `entrance` | `zoom` adds the studio's zoom to the logo's own animation | same |
| `fan`, `blur` | | the reel's screens fanned behind it (`false` for none); how soft, 0–4 |
| `media` | pictures in the intro | pictures in the end card |
| `off` | `true`: off, settings kept | same |

### A ground

A moving pattern:

```json
{"pattern": "mesh", "speed": 1, "seed": 7, "beat": 120, "grain": true,
 "palette": {"top": "#F5E6C8", "bottom": "#E8E2F4",
             "colours": ["#FFD97A", "#F2A65A", "#C9B8F0"], "light": true}}
```

`pattern`: `drift`, `aurora`, `breathe`, `orbit`, `sweep`, `bokeh`, `grid`,
`mesh`, `ribbons`, `rays`. `beat` pulses at that tempo. Light grounds take
dark words.

A picture: `{"image": "app_reels/media/bg.png", "dim": 0.2, "light": false}`.

## Media

Pictures (PNG, JPEG, WebP) and clips live in `app_reels/media/`.

```json
"media": [
  {"image": "app_reels/media/spark.png", "box": [70, 8, 22, 12],
   "at": 1.2, "until": 4, "move": "float", "fit": "contain"},
  {"frames": "app_reels/media/waves", "fps": 30, "box": [0, 0, 100, 100],
   "behind": true, "fit": "cover", "opacity": 0.6}
],
"hand": {"image": "app_reels/media/hand.png", "tip": [0.32, 0.04], "width": 200}
```

| Key | |
| --- | --- |
| `image` or `frames` | a picture, or a folder of frames played in name order, looping |
| `fps` | the frames' rate |
| `box` | `[left, top, width, height]` in percent of the frame |
| `at`, `until` | seconds on the scene's clock (on a reel, its clock as made) |
| `behind` | behind the screens and lifted parts |
| `fit` | `contain`, `cover`, `fill` |
| `move` | `none`, `float`, `rise`, `drift`, `zoom`, `spin`, `pop` |
| `opacity` | 0–1 |

A hand's `tip` is where the fingertip is in its picture, as fractions:
`[0.32, 0.04]` is a third of the way across, at the top.

## The command line

| Command | |
| --- | --- |
| `init [--force] [--no-ai]` | write `app_reels/` |
| `doctor` | check FFmpeg, Flutter, `app_reels/` |
| `list` | reels, scenes, lengths |
| `map <reel>` | every screen with its parts numbered, on a page |
| `looks <reel> --at 4.2` | that moment on every ground |
| `storyboard <reel>` | a frame per scene, with notes |
| `stills <reel> --at 1,3.5 [-f wide]` | PNGs in `out/stills/` |
| `render <reel> [-f vertical,wide \| all] [--fps 60] [--no-audio] [--open] [--reveal]` | MP4s; prints each path and link |
| `studio [<reel>] [-f wide] [--port 4455] [--no-watch] [--no-open]` | the studio in the browser; it re-renders when files change unless `--no-watch` |
| `media frames <video> [--name x] [--fps 30] [--width 720]` | a clip as frames in `app_reels/media/<name>/` |
| `media cutout <photo> [--name hand] [--subject person\|object] [--region "x,y x,y …"] [--no-solid] [--fade rb] [--drop-dark] [--tip left] [--credit "…"]` | a subject cut out of a photo into `app_reels/media/<name>.png`; prints its size and, with `--tip`, the fingertip for `"hand"`. macOS uses Vision; elsewhere `rembg` |
| `clean [--finals] [--keep 1] [--dry-run]` | clear out `app_reels/out/` |
| `inventory [--find "the settings sheet"]` | the app's screens worth showing, found with Claude Code |
| `sfx [--pad 30]` | the built-in sounds and a placeholder pad |
| `voice --script app_reels/voice/script.yaml [--voice Tessa]` | placeholder voice-over (macOS) |

## Output

`app_reels/out/`: `<reel>.mp4` in reel.yaml's format, `<reel>-<format>.mp4`
in others, `stills/`, pages in `map/`, `looks/`, `storyboard/`, the studio's
previews in `studio/`, the last run's full log in `last.log`. A new render
of the same reel and format replaces the old file.

## Reels in Dart

For what specs can't do. Register in `render_test.dart`:
`reels: {'promo': (format) => promo(config, format)}`.

```dart
Reel promo(ReelConfig config, Format format) => GlassLayers(
  brand: Brand.from(config), format: format,
  open: (t) => AppMark(progress: progress(t, 150.ms, 1500.ms)),
  beats: [
    GlassBeat('Share.', screen: const HomeScreen(),
        lift: [Pick.type<WalletCard>()], move: GlassMove.spread),
    GlassBeat('Add it.', screen: const AddExpenseScreen(),
        lift: [Pick.type<TextField>()],
        partMoves: [PartMove(typing: PartTyping('186'))],
        media: [Media(image: 'app_reels/media/spark.png',
            box: const Rect.fromLTWH(.7, .08, .22, .12), move: MediaMove.float)]),
  ],
  end: GlassEnd(logo: (t) => const AppWordmark(), logoSize: const Size(340, 110),
      line: 'Shared money, no awkward chats.'),
).build('promo');
```

Below the packs:

```dart
Scene(name: 'Share.', length: 5.s,
  camera: Camera.tracks(tilt: Track.from(15).to(1.5.s, 6, Ease.arrive), zoom: Track.constant(.5)),
  layers: [
    Layer.screen(const HomeScreen(),
      lifts: [Lift(where: Pick.type<WalletCard>(), motion: Motion(z: Track.from(0).hold(1.5.s).to(3.s, 200)))],
      taps: [Tap(where: Pick.text('Done'), at: 3.s, press: true)],
      scrolls: [Scroll(offset: Track.from(0).to(2.s, 600))],
      typing: [TypeText(text: '186', at: 1.s)]),
    Layer.timed((t) => AppMark(progress: progress(t, 0.s, 1.s)), size: const Size(200, 200)),
  ],
  words: [Words('Share{.}', at: 2.s, until: 4.5.s, reveal: Reveal.letters)],
  media: [Media(image: 'app_reels/media/spark.png', box: const Rect.fromLTWH(.7, .1, .2, .1))],
  cues: [Cue(1.5.s, 'rise')],   // tap tick pop rise whoosh chime, or a path
)
```

| Block | |
| --- | --- |
| `Pick` | `Pick.type<T>()`, `.nth(1)`, `Pick.typeName('_Private')`, `Pick.text('Total', contains: true)`, `.containing(...)`, `Pick.key(...)` |
| `Track`, `Ease` | `Track.from(0).to(1.s, 100, Ease.out).hold(2.s)`; `Ease.out`, `arrive`, `inOut`, `leave`, `linear`, `pop` |
| `Camera` | `tilt`, `turn`, `roll`, `zoom`, `panX`, `panY`, `focus`, `aperture`, `blur` |
| `Transition` | `cut`, `fade`, `swing`, `zoomThrough`, `wipe`, `rise` |
| `Backdrop` | `top`, `bottom`, `glows`, `vignette`, `motion` (a `GroundMotion`), `image`, `imageDim` |
| `Reel` | `pace`, `steady`, `media`, `hand`, `copyWith(...)` |

Inside `flutter test`, real I/O only finishes in `tester.runAsync` or done
synchronously; anything awaited on disk or a process outside it hangs
without an error.
