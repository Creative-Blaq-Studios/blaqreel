# Changelog

## 0.4.0 — 2026-10-11

The whole plan: engine, tools, packs and skill. Not yet tried on a second
app.

### Added

- Scenes on their own clocks, joined by transitions: cut, fade, swing,
  zoom-through, wipe, rise; `carry` keeps a layer on course through one.
- `Camera.tracks` for a track per property; `Camera.still`; `Track.from`,
  `to`, `hold` and `shift`; `Ease`; `TimeWarp` for slow motion and speed
  ramps; motion blur by frame blending.
- `Motion` on every layer and lift (position, depth, tilt, turn, roll,
  scale, opacity, blur); `Glass` slab edges; `Layer.timed`.
- `Pick`: by type, type name, text, key, nth, innermost containing.
- `Tap` (fingertip, ripple, real presses), `Scroll`, `TypeText`.
- `Words`: letters, words, typewriter and fade reveals, `{accent}` markup,
  marker sweep, wrapping, exits.
- `Soundtrack`: music, voice-over with ducking, cues from taps, typing,
  words and transitions, built-in sounds and a placeholder pad synthesized
  by FFmpeg, loudness normalized to −16 LUFS.
- Formats: portrait 4:5; every pack lays out for all four.
- Style packs: `GlassLayers`, `KineticLaunch`, `DarkGlow`, `StoryAd`.
- `blaqReelMain`, the app's test entry; `describeReel` for timelines.
- The CLI: `init` (surveys the app: fonts, colours, screens, state
  management), `doctor`, `list`, `stills`, `render`, `studio` (browser
  scrubber with live re-render and stills), `sfx`, `voice`.
- The `blaq-reel` Claude skill.
- The studio's library: every reel in every format and every rendered
  video, side by side; watch any finished video with its timeline, switch
  which reel is previewed live, render finals from the page.

- A guided flow: `map` (every screen with each featurable part numbered,
  named as the app names it, with its `Pick`), `looks` (one moment on every
  ground), `storyboard` (a frame per scene with notes); each page ends in a
  note to copy back. The skill walks through the five steps.
- Grounds per beat: `GlassBeat(look:, ground:)`, crossfading between beats;
  `GlassLayers(ground:)` for colours of your own; six looks (ink, mesh,
  butter, studio, grid, echo); `Backdrop(floor:)`; `Layer(ignoreFocus:)`.
- Claude Code runs stream: every AI task the studio starts shows live in a
  panel, with its steps, the files it changed, and its resumable session.
- The studio's builder: Brief, Screens, Parts, Story, Ground, Preview,
  saving each change to `app_reels/specs/<name>.json`; `ReelSpec` builds
  any pack from that data, finding parts by the names the map gives them;
  `ReelKit` and `ReelScreen` are how an app offers its screens and logos;
  the `catalogue` task draws every kit screen with its parts; AI drafts of
  the words, or of the whole reel, through Claude Code.
- `Sweep`: a scan line over a lifted widget (`GlassBeat(sweep:)`), which
  rises larger so the reading shows; `Words(fit:)` keeps a beat's word on
  one line.
- A depth band on the camera (`depth`): every lifted card stays sharp.

### Fixed

- A test pump draws only scheduled frames, so lifts could go unfound when
  nothing else on screen was animating; the stage now asks for frames.

## 0.1.0 — 2026-10-11

### Added

- The proof engine: `ReelClock`, `Track` and `Keyframe`; `Format`;
  `Camera` and `Shot` with perspective; `Layer` and `Layer.screen` on a
  `Device`; `Lift`; `Words`; `Backdrop` and `Glow`; `ReelStage`;
  `ReelRenderer` (stills, H.264 through FFmpeg); `ReelHost`, `ReelConfig`.
- First use: Khumio's five-second proof.
