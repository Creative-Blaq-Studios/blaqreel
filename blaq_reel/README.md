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

`blaq_reel studio <reel>` serves a page on localhost:4455: the preview with
a scrubber over the timeline of scenes, transitions, words and cues; frame
stepping (← →), seconds (⇧ ← →), scenes ([ ]), ¼× and ½× speed, scene loop,
full-size stills at the playhead (S), and the time copied for notes (C).
Saving any file under `app_reels/` or `lib/` re-renders the preview, and the
page reloads it where it was.

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
| `Layer`, `Layer.screen`, `Layer.timed`, `Motion`, `Glass` | Any widget in 3D; an app screen through the host, on a `Device`; a widget rebuilt from the clock each frame. Each moves on its own tracks; `Glass` gives it a slab edge. |
| `Lift` | Part of a screen that comes off toward the camera: the real widget, found as drawn, cloned over where it was, leaving a hole and a shadow that spreads as it rises. |
| `Pick` | Finds widgets in a screen: by type, by type name (private ones too), by text, the nth, the innermost one containing another. |
| `Tap`, `Scroll`, `TypeText` | A fingertip with a ripple (and, with `press`, a real tap); the real scrollable scrolled; text typed into the real field. |
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
