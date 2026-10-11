# Changelog

## 0.5.0 — 2026-10-11

### Added

- Moves: `GlassMove` on every Glass Layers (and Story Ad) beat. `lift`,
  `scan`, and six new ones: `spread` (pulled apart round the phone, an
  exploded view), `fan` (gathered and fanned like cards), `zoom` (the first
  part comes forward large), `tap` (a finger picks it first), `pop` (one by
  one with a spring, `Ease.pop`) and `orbit` (the camera circles the
  phone). `Lift.to` and `travel` send a part to a place on its screen,
  wherever it was found. Specs take `"move"`; the builder shows each move
  as a small animation to choose from, and the AI picks moves when it
  drafts.
- Each part its own move: `PartMove` (where it lands, height, size, tilt,
  turn, roll, when it starts, whether a scan line reads it), over the
  beat's `GlassMove`, which is now where every part starts from. Specs set
  them on each part (`"to": [x, y]`, `"z"`, `"scale"`, `"tilt"`, `"turn"`,
  `"roll"`, `"delay"`, `"scan"`). Up to six parts lift.
- Words you can set: `GlassWords` (colour, accent, size, weight, reveal,
  timing, anchor, offset, width, plate, behind) for the whole reel on
  `GlassLayers.words` and per beat on `GlassBeat.words`, the beat's over the
  reel's. Specs carry a reel `"words"` style and each beat's `"words"` with
  its timing and a placement per frame (`"places": {"vertical": {"pos",
  "dx", "dy", "width"}}`), so each format keeps its own. `Words` gained
  `offset`, `plate`, `plateBlur` and `behind`; a set width wraps the words,
  and a word longer than a line shrinks the type instead of breaking.
- Moving grounds: `GroundMotion` on a `Backdrop` draws one of ten
  patterns (`GroundPattern`: drift, aurora, breathe, orbit, sweep, bokeh,
  grid, mesh, ribbons, rays) in a palette of its own, at a pace, with an
  optional pulse on the beat and film grain; a ground says whether it is
  light, and the words follow. Specs carry `"ground"` for the reel and any
  beat. The editor draws the same patterns live, picks them from the Ground
  list, and has a Ground panel: pattern, palette (brand presets or any
  colour), light, speed, grain, beat, and Generate (six grounds from the
  brand's colours, or more like the chosen one).
- The Ground step comes before Parts, and the editor has a Ground picker
  that draws each look as the renderer builds it.
- Renders show how far they are: a card over the Library's player and in
  the Preview step (frames drawn, time left, then the sound), a bar under
  the header, and the figure in the status. Preview renders in place and
  plays when done.
- Typing into lifted parts: a part holding a text field takes
  `PartMove.typing` (`PartTyping`: the keys, when, how fast, a tick per
  key), typed once it lands. Specs set `"typing": {"text", "at", "every",
  "sound"}` on the part. The editor's part panel has a Typing section for
  any part with a field, the timeline a bar for it you can drag, and the
  preview shows the keys as they go in. Screen maps mark parts that hold a
  field (`"field": true`).
- Typing goes in as a keyboard's would: each key through the field's input
  formatters, then its `onChanged`, so a money field reads R186.00 and a
  search filters as it goes. Going back in time types it again.
- Lifted parts are live: a copy is rebuilt from the screen's widget as it
  is now, so what changes after the lift (typed text, a figure) shows on
  the part in the air.
- Render beat: the editor renders the beat it shows on its own, with the
  real screens (about half a minute), and plays it over the frame; the
  playhead follows it, and it says when the beat has changed since.
  `POST /api/beat` takes the spec as it stands, the beat and the frame.
- The safe zone is off by default, a small tick in the editor's toolbar,
  and shows by itself while the words are dragged.
- The editor's toolbar labels the Ground and Move pickers, and says which
  beats a ground is for with Every beat | This beat (was a "Beat" tick).
- The Preview step is a theatre: the reel centred at its own shape, a
  scrub bar marked at each beat, a chip per beat (click to jump,
  double-click to edit it), and an Export panel that renders finals in any
  set of formats, full or quick. `/api/final` takes `reel`, `formats` and
  `quality`.
- Number fields scrub like a design tool's; `[` and `]` step through
  beats and Space plays or pauses in the builder (the Library's keys no
  longer act while building); chips at the top of the inspector switch
  between the words and each part.

### Fixed (builder)

- Renaming a reel left its old file behind, so it showed twice. A rename
  now moves the file, and refuses a name another reel already has.
- The inspector shrank instead of scrolling, hiding its lower settings.

- Durations on the timeline: the beat's own bar, whose end sets its
  length; each part's bar, whose end sets how long it takes to rise
  (`PartMove.rise`, a part's `"rise"` in ms); and the words' bar, whose ends
  set when they come in and go. The part inspector has a Rise slider.
- The Parts step's timeline editor (Pick parts, then Animate): the real
  frame with its safe zone, a track per part and for the words, an
  inspector for each, dragging and snapping on the stage, and a warning
  with Move clear when the words cover a part. The studio serves the
  brand (`/api/brand`) so the editor sets words in the brand's own face.
- The builder's animator: the beat plays live in the Parts step with the
  renderer's own camera, tracks and eases ported to the page, so what is
  set is what renders. Drag a part to where it lands; set the rest per
  part with sliders, and see it as you go.
- The map lists each part's full size beside what shows of it.
- The builder's Parts step lists every beat along the top.
- "The AI, all of it" keeps the screens the person chose, in order, and
  fills in only the parts, moves and words they left; it chooses screens
  only when none are chosen. It used to replace them.
- The builder reopens the reel worked on last.

### Fixed

- A lifted part that ran on under something (a list under the tab bar)
  lifted whole from the start, hidden rows and all, over the tab bar. It
  now starts as what the screen shows of it (cut by every clip above it,
  the cut edge faded) and opens out to all of it as it rises or travels.
  The map outlines only what shows.
- Lifting part of a text field (or anything holding a GlobalKey) failed
  the render with a duplicate key. A lift now copies the nearest widget
  around it whose keys its copy makes afresh.

- Components: one piece of the app shown on its own, large on the ground
  with no phone around it. `Layer.component` and `Device.bare` draw it
  through the host like a screen, so a `Tap` with `press` really presses it
  (a button goes into its loading state) and anything that animates by
  itself plays on the reel's clock. `GlassBeat(piece: size)` makes a Glass
  Layers or Story Ad beat about one, with its own silhouette as a soft
  shadow; `ReelScreen.component(widget, label:, size:, taps:)` offers one to
  the builder and to specs.
- The builder lists components under the screens, shows them whole (no
  parts to pick), and says which styles show them. The AI's inventory lists
  components too, from the app's shared UI and its showcase, and staging
  registers them with `ReelScreen.component`.
- `ReelRenderer.close`: every task takes the stage down and lets the app's
  pending timers run out, so a pressed button's work never fails a render.
- Slim scroll bars on every page; the Claude Code panel as one chat thread
  behind a floating button that glows while Claude works.

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
