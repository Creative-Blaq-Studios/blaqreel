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
