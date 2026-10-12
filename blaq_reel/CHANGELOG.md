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
- Length: say how long the reel should run (`"length"` in seconds, in
  Brief & style and Preview) and every beat stays while everything plays
  faster or slower to fit; the renderer works out the pace from the reel
  itself, so housemates at 30 renders at 30.0 s. The builder shows the
  beats and about how long each runs, and As made goes back.
- The skill works for any AI agent (Claude Code, Codex, Cursor…): no
  machine paths or tool names, reels written as specs the studio opens,
  everything BlaqReel does now, and an offer of generated media (a
  background, a hand, stickers, a clip) when the agent can make images or
  video. `reference.md` rewritten as a clean reference of the spec, media,
  commands and Dart API. `AGENTS.md` (with `CLAUDE.md` pointing to it) tells
  agents working on BlaqReel to update the skill, README and changelog with
  every change.
- Media: pictures and clips in a reel. `Backdrop.image` (spec `"ground":
  {"image", "dim", "light"}`) puts a picture behind everything, breathing
  slowly; `Media` (spec `"media"` on a reel, beat, intro or end card) sets
  a picture or a folder of frames in the frame, timed, in front of or behind
  the screens, with a move (float, rise, drift, zoom, spin, pop);
  `TapHand` (spec `"hand"`) does the taps with a hand picture, its fingertip
  on the point. `ReelImage` reads and decodes pictures so they draw inside
  the test's clock. `blaq_reel media frames <video>` turns a clip into
  frames. For pictures an AI generates, or any the person has.
- `blaq_reel clean`: clears out `app_reels/out/` (scratch previews, stills,
  pages, thumbnails, stray files); `--finals` also removes older finished
  videos, keeping the newest (`--keep`); `--dry-run` lists what would go.
  The studio's Library has the same as **Clean up…**.
- Where a render went: `render` prints each video's path and a link, and
  `--reveal` shows it in Finder; the studio has **Reveal in Finder** and
  **Open** on a rendered video, and the Preview step lists the reel's
  finals with both.
- Sound: `"sound": "all" | "effects" | "silent"` in a spec, chosen in
  Brief & style and in Preview's Export panel (Music & effects, Effects
  only, Silent). Silent renders with no audio track at all; "No music" had
  left the effects (taps, ticks, whooshes) in. `Reel.withSoundtrack`.
- Fixed: a beat rendered on its own took the reel's length as its own,
  so with a reel set to 60 s one 5.6 s beat played over a minute, in slow
  motion. It now plays at the speed the reel's beats play at; the editor's
  playhead stays within the beat, and its pace reads to two places.
- The intro and the end card keep the seconds they are given: a reel's
  length (or pace) speeds the beats between them up or down to fit what is
  left (`Reel.steady`, `Reel.paceFor`). Housemates at 30 s with its 1.6 s
  intro and 4.7 s end card renders at 30.0 s with both whole. The Length
  control shows the intro, the beats (about how long each) and the outro.
- Logo frames are captured on a canvas twice the logo's box, so an
  animation that reaches past it (the mark's cards before they join) is
  shown whole in the editor rather than cut at the box.
- Logos play their own animation: the kit's logo is built from a clock
  that now starts when it appears (after the intro's lines, half a second
  into the end card), so the mark's cards join on screen rather than before
  it shows. It comes in with a short fade; the studio's zoom, roll and blur
  are an option (`"entrance": "zoom"`). The catalogue captures each logo's
  animation as frames, and the editor plays them. An intro's lines each
  leave before the next comes, and the logo keeps 2 s for itself.
- An intro that says something: `GlassLayers.openLines` (spec `"open":
  {"lines": [...], "reveal"}`) shows up to a few hook lines, one after
  another, large, before the logo (or instead of it). In the editor the
  AI writes them: describe the intro you want, and Claude Code answers with
  lines, a logo, a length and a reveal from the brief, the beats and the
  app's own copy (`POST /api/ai/intro`).
- The intro's and outro's pieces are styled and placed as the beats'
  words are: click the intro's words, the end card's line or address, or
  either logo, and set colour, accent, size, weight, anchor, offset, width
  and plate, or drag them on the preview, per frame. Logos take a size and
  a place; the end card's screens a background blur (0 to 4). Specs:
  `"open": {"words", "logoScale", "logoPlaces"}`, `"end": {"lineWords",
  "urlWords", "logoScale", "logoPlaces", "blur"}`; `"logo": null` is none.
- The intro and the outro are in the editor, either side of the beats:
  on or off, the logo, the length, and for the outro its line, its address
  (the app's, its own, or none) and the screens fanned behind it. Sketched
  from the logos as the catalogue draws them (it now captures every logo,
  in ink and paper, and the app's address); Render renders just that one.
- Specs: `"open": {"logo", "length", "off"}` (or the logo's name, or
  `false`); `"end"` takes `"fan"`, `"off"` and `"url": false`; a beat's
  `"skip": true` leaves it out of the video (the editor's Skip). `GlassLayers.openLength`. `ReelRenderer.preview(scene:)`
  renders one scene of a reel, silent.
- Pace: `Reel.pace` (spec `"pace"`) plays the whole reel faster or
  slower. Every timing scales with it, beat lengths, moves, typing, words,
  transitions and the moving ground, so the beats keep their shape and the
  video gets shorter: housemates at 1.25× runs 54.1 s instead of 67.6 s.
  Cues and voice lines move with their moments; music and voice keep their
  speed. Stills and the studio's timeline read the video's clock. The
  builder sets it in Brief & style and in Preview (0.8× to 1.5×, or any
  value from 0.5× to 2×), and the editor plays at it. Superseded in the
  builder by Length, below.
- Faster renders in the studio: a render worker (`render_test.dart` run
  once with the task `serve`) keeps the app compiled and renders job after
  job from `<out>/studio/jobs/`, restarting when the app's code changes;
  a render it cannot take runs on its own as before. Renders skip
  `pub get` while the packages are up to date. A beat renders in about
  5 s (was 25 s); the 72 s housemates preview in 50 s (was 90–107 s).
- Fixed: live lifted copies wrapped themselves in the host again every
  frame (the app's scopes, its MaterialApp), which slowed long renders to
  a crawl; the wrap is built once and only the copy inside follows the
  screen.
- Layers: `Lift.layer` and `PartMove.layer` (spec `"layer"` on a part)
  stack a beat's lifted parts in an order of their own, whatever their
  heights, so a lower part can sit in front. They swap only among the
  places their heights gave them, so the phone and other screens keep
  theirs. The part panel has a Layer row: where it is in the stack, ↓ and
  ↑ to move it one place, and Auto to stack by height again.
- `GlassLayers.flip` (spec `"flip": true`) swings the beats the other way,
  first one to the left. Fixed with it: a beat rendered on its own from
  the editor swung the way the reel's first beat does, so every
  even-numbered beat came out facing the other way from the editor.
- The editor warns about a part that will spoil the beat (one its screen
  no longer has, or one inside another lifted part, which then shows
  twice) and removes it in one click; and about typing that starts while
  its part is still rising, out of focus.
- The editor's frame picker and safe-zone tick sit beside the frame (or
  above it when the frame fills the width), so the toolbar keeps to one
  row.
- Fixed: anything hidden with `hidden` but given a display of its own
  stayed on screen; the Render overlay darkened the editor's frame.
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
