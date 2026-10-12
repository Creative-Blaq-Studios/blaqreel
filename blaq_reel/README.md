# blaq_reel

Promo videos made from a Flutter app's real screens. Working name.

You describe the video; a reel is written as a few short Dart files in the
app's own `app_reels/`; BlaqReel draws the app's real widgets in 3D inside
`flutter test`, one frame at a time on a fixed clock, and FFmpeg encodes them
with music, voice-over and sound cues, in every format. The app stays as it
is: blaq_reel is a dev dependency and `lib/` is never touched.

Khumio is the first app: `Khumio/khumio/app_reels/`.

## In an app

```yaml
# pubspec.yaml
dev_dependencies:
  blaq_reel:
    path: ../../BlaqReel/blaq_reel   # or git, once it has a remote
```

```bash
dart run blaq_reel init      # app_reels/: reel.yaml, host.dart, a first reel, REELS.md
dart run blaq_reel doctor    # FFmpeg (libx264, tmix, loudnorm…), Flutter, app_reels/
```

Then fill in `app_reels/host.dart`, the one adapter: given a screen, return
it ready to draw with the app's theme, fonts and demo data. An app with
widget tests already has this.

## The builder

`blaq_reel studio`, then **Build**: a reel made step by step, in the page.

1. **Screens**: every screen the app's kit offers, drawn for real, and
   below them its components (a button, a loading placeholder) shown on
   their own; each one you add is a beat. **Add from the app** lists every
   screen, sheet, dialog and component the AI found, and stages the ones
   you pick.
2. **Brief**: name, style pack, frame, what it should get across, sound,
   and who writes the story: the AI, you then the AI, or you.
3. **Ground**: the reel's ground and any beat's own; render them on the
   reel's own frames to compare. A ground can be a look, or move: one of
   ten patterns (drift, aurora, breathe, orbit, light sweep, bokeh, grid
   flow, liquid mesh, ribbons, light rays) in a palette, at a pace, with
   film grain or a pulse on the beat. The editor's Ground panel sets all of
   it and generates new grounds from the brand's colours. It comes before the parts, so they are
   animated on it; the editor also has a Ground picker.
4. **Parts**, in two modes per beat. **Pick parts**: the screen with its
   cards, rows and photos numbered; click what it features, in order.
   **Animate**, the timeline editor: the beat plays live in the real frame
   (9:16, 4:5, 1:1 or 16:9, with the platform's safe zone), with a track per
   part and one for the words, and an inspector for whichever is selected.
   Start from a move (Lift, Lift + scan, Spread, Fan, Zoom in, Tap, Pop,
   Orbit), then drag each part to where it lands and give it its own height,
   size, tilt, turn, roll, start and scan line; drag a bar to retime it. The
   words have a colour, an accent, a size, a weight, a reveal and timing,
   set for the whole reel or one beat, and a place per frame: drag them
   (they snap to the safe zone and the centre), anchor them, give them a
   width to wrap at, a plate, or put them behind the phone. The editor
   warns when they cover a part, and **Move clear** finds them a spot. It
   runs the renderer's own camera, timing and word layout in the page, so
   what you set is what renders. The timeline sets durations too: drag the
   beat's own bar to set its length, a part's bar end for how long it rises,
   the words' ends for when they come and go. Numbers scrub like a design
   tool's (drag the label, or ↑/↓; Shift ×10, Alt ×0.1). `[` and `]` step
   through the beats, Space plays and pauses, and the chips at the top of
   the inspector switch between the words and each part.
   The editor sketches each beat from a flat shot of its screen, which is
   quick but cannot show what the app itself does (typed text formatting,
   a tap); **Render beat** renders just that beat with the real screens in
   about half a minute and plays it over the frame.
5. **Story**: the words per beat, the end card, and for a Story Ad the hook,
   problem and proof. **Draft with the AI** asks Claude Code (`claude -p`)
   using the brief, the parts and the app's own copy (`app_reels/copy.md`).
   **Let the AI build it** does the screens, parts and words from the brief alone.
6. **Preview**: a theatre. The reel plays centred at its own shape, with
   a card over it while it renders (the frames drawn, the time left, then
   the sound); any render in the Library shows the same card over the
   player. Under it, a scrub bar marked at each beat and a chip per beat:
   click to jump there, double-click to edit that beat. Beside it,
   **Export**: tick the formats, choose Full or Quick, and **Render N
   finals**; they land in the Library under Rendered videos.

The studio keeps a render worker running: the app is compiled once, when
the studio starts and again when its code changes, and every render after
that skips it. A beat renders in about five seconds.

Whenever the studio asks Claude Code for something (drafting, the
inventory, staging screens) it runs a headless session (`claude -p`) in the
app's folder, on the person's own Claude Code. A **Claude Code** panel shows
it live: each step (reading, searching, editing, running `dart analyze`),
the files it changed, its outcome, and the session id with the command that
reopens it in a terminal (`claude --resume <id>`).

Every change is saved to `app_reels/specs/<name>.json`, which renders like
any reel. The app offers its screens to the builder with a `ReelKit`
passed to `blaqReelMain` (see Khumio's `app_reels/kit.dart`): screens as
`ReelScreen(widget, label:)`, and components as
`ReelScreen.component(widget, label:, size:, taps:)`, which a Glass Layers
or Story Ad beat shows large on the ground, doing what it does (a `Tap` with
`press: true` puts a button into its loading state). Kinetic Launch keeps a
component's line only; Dark Glow leaves components out.

## A guided reel, in five steps

1. **Brief**: where it goes, what it says, which pack, what sound.
2. **What to feature**: `dart run blaq_reel map <reel>` shows every screen
   with each card, row, field and photo numbered and named the way the app
   names it. Click the ones to feature; copy the note back.
3. **The ground**: `dart run blaq_reel looks <reel> --at 4.2` shows that
   moment on every Glass Layers ground. Choose one for the reel, or one per
   beat (`GlassBeat(look: …)`), or your own colours (`ground: Backdrop(...)`).
4. **Storyboard**: `dart run blaq_reel storyboard <reel>` shows a frame per
   scene with its timing, words and sounds, and a notes box under each.
5. **Render and review**: `dart run blaq_reel render`, then the studio.

The `blaq-reel` Claude skill runs these steps with you, stopping at each
page for your choice.

## Making a video

```bash
dart run blaq_reel list                              # reels, scenes, lengths
dart run blaq_reel stills promo --at 2,4.8,10 --open # look before rendering
dart run blaq_reel studio promo                      # scrubber, re-renders on save
dart run blaq_reel render promo --format all         # vertical, wide, square, portrait
dart run blaq_reel sfx --pad 30                      # built-in sounds and a placeholder pad
dart run blaq_reel voice --script app_reels/voice/script.yaml   # placeholder voice-over
```

Output goes to `app_reels/out/`: `<reel>.mp4` in reel.yaml's format and
`<reel>-<format>.mp4` in the others, `stills/`, `studio/`, and the last run's
log in `last.log`.

### The studio

`blaq_reel studio [<reel>]` serves a page on localhost:4455 with the whole
app's reels in one place:

- **Rendered videos**: every finished MP4 in `out/`, newest first, with a
  thumbnail, length and size. Click one to watch it with its timeline.
  `?video=<file>` opens the page on one.
- **Reels**: every reel, with a chip per format. Pick one to work on it
  live: a quick preview renders, and saving any file under `app_reels/` or
  `lib/` renders it again; the page reloads it where it was.
- **Render final** renders the finished video of the reel being worked on;
  it appears under Rendered videos.
- The timeline shows scenes, transitions, words, cues and voice-over. Step
  frames (← →), seconds (⇧ ← →), scenes ([ ]), play at ¼× or ½×, loop a
  scene, take a full-size still at the playhead (S), copy the time for
  notes (C).

## Style packs

`import 'package:blaq_reel/packs.dart';` Each is a cut with slots: give it a
`Brand.from(config)`, screens and words; it supplies camera, timing,
transitions and layout for whichever format it is built for.

| Pack | From | Shape |
| --- | --- | --- |
| `GlassLayers` | the Sber "glass layers" Short | open mark → beats: one word, the screen's cards lift off as glass layers, focus follows them, the screen falls back → end card over the screens fanned out |
| `KineticLaunch` | LangEase | lines arrive word by word with the key part marked in the accent; devices sweep in beside them; light by default |
| `DarkGlow` | Gemini Canvas | one unbroken camera past glowing screens on a dark ground, a title and line at each |
| `StoryAd` | Meetris, Hector | hook → problem → meet → Glass beats → proof → call to action, voice-over per part, music ducked under it |

## The blocks

`import 'package:blaq_reel/blaq_reel.dart';`

| Block | What it is |
| --- | --- |
| `Reel`, `Scene`, `Transition` | A run of scenes, each on its own clock, overlapping through cut, fade, swing, zoom-through, wipe or rise. A layer marked `carry` stays on its course through the transition out. |
| `Layer`, `Layer.screen`, `Layer.component`, `Layer.timed`, `Motion`, `Glass` | Any widget in 3D; an app screen through the host, on a `Device`; a piece of the app through the host with no phone around it (`Device.bare`), which can be tapped and typed into like a screen; a widget rebuilt from the clock each frame. Each moves on its own tracks; `Glass` gives it a slab edge. |
| `Lift` | Part of a screen that comes off toward the camera: the real widget, found as drawn, cloned over where it was, leaving a hole and a shadow that spreads as it rises. |
| `Pick` | Finds widgets in a screen: by type, by type name (private ones too), by text, the nth, the innermost one containing another. |
| `Tap`, `Scroll`, `TypeText` | A fingertip with a ripple (and, with `press`, a real tap); the real scrollable scrolled; text typed into the real field, key by key through its formatters and `onChanged`, so the app formats and reacts as it would for a person. |
| `Camera`, `Shot`, `CameraPose` | Tilt, turn, roll, zoom, pan, focus, aperture, blur: shots that ease together, or a track per property. |
| `Words`, `Reveal` | Letters or words rising into place, typed, or faded; `{accent}` markup, a marker sweep, wrapping, exits. |
| `Backdrop`, `Glow`, `blobs` | Gradient, drifting glows, vignette. |
| `Track`, `Keyframe`, `Ease`, `TimeWarp`, `ReelClock` | Time: values over time, eases, slow motion and speed ramps, frame `n` at `n / fps`. |
| `Format`, `ReelConfig` | Frame sizes and safe areas; reel.yaml. |
| `Soundtrack`, `Music`, `VoiceLine`, `Cue`, `Sfx` | Music (or the synthesized `Music.pad`), voice-over lines that duck it, cues from taps, typing, words and transitions, built-in sounds made by FFmpeg. Mixed to −16 LUFS. |
| `ReelHost`, `ReelRenderer`, `blaqReelMain` | The adapter; stills, video (motion blur by frame blending) and studio previews; the app's test entry the CLI drives. |

## Things to know

- **Real I/O never finishes in a widget test's fake-async zone.** Anything
  touching disk or a process is synchronous or inside `tester.runAsync`, or
  the test hangs without an error.
- **A test's pump draws only when a frame is scheduled.** The stage asks for
  frames while it waits for lifts.
- **flutter_test draws shadows solid** (`debugDisableShadows`). The renderer
  turns them on only while a frame paints.
- **A lifted widget is cloned outside its screen**, through the host's wrap:
  inherited widgets between the screen and it (a currency scope, say) are
  not there, and a row with an InkWell needs the wrap to supply Material.
- **Lifts are found once**, after each scene's opening scroll and typing are
  applied; a lift on a screen that scrolls later stays where it was found.
- **Native views don't draw in tests** (camera previews, maps, web views,
  video players): a scene shows a still in their place.

## Development

```bash
flutter pub get && dart analyze && flutter test && dart format lib test bin
```

The Claude skill is in `../skill/blaq-reel/` (symlinked into
`~/.claude/skills/`).
