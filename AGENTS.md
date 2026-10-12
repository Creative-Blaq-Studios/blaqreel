# AGENTS.md

Instructions for any AI coding agent working in this repository: Claude
Code, Codex, Cursor, Copilot or another. Read all of it before changing
anything. `CLAUDE.md` points here.

## What this repository is

**BlaqReel** turns a Flutter app's real screens into promo videos. It has
two parts:

| Path | What it is |
| --- | --- |
| `blaq_reel/` | A Dart package: the engine (`lib/src/`), the style packs (`lib/src/packs/`), and the command-line tool with its browser studio (`lib/cli/`, `bin/`). |
| `skill/blaq-reel/` | An agent skill: `SKILL.md` (how to make a reel with a person, step by step) and `reference.md` (the spec format, the Dart API, every command). Agents in *other* repositories read it to use BlaqReel. |

Apps use BlaqReel as a dev dependency; their reels live in their own
`app_reels/` folder. The first app is Khumio (`../Khumio/khumio/app_reels/`),
a full working example of a host, a kit, Dart reels and specs.

`README.md` is the guide for people. `blaq_reel/CHANGELOG.md` records what
changed.

## The rule: documentation changes with the code

**Every change to what BlaqReel can do ships with its documentation, in the
same commit.** The skill is how other agents learn BlaqReel; if it falls
behind, they write reels that don't work or miss what the tool can do.

When you change any of the following, update the files listed against it:

| You changed | Update |
| --- | --- |
| A command or option in `lib/cli/cli.dart` | `reference.md` → The command line; `README.md` → The command line; `SKILL.md` if the workflow uses it |
| A spec key (anything `lib/src/spec.dart` reads) | `reference.md` → The spec; `README.md` → Reels as data |
| The engine's public API (`lib/src/`, `lib/src/packs/`) | `reference.md` → Reels in Dart; `README.md` → The building blocks |
| The studio or its builder (`lib/cli/studio*.dart`, `builder_page.dart`, `animator_page.dart`) | `README.md` → The studio / The builder; `SKILL.md` if it changes how a person and an agent work together |
| Where files go (`app_reels/out/`, `app_reels/media/`) | `reference.md` → Output; `README.md` → Output |
| Setting up in an app (`init`, the host, the kit) | `INSTALL.md`; `SKILL.md` → Step 0; `reference.md` → Setting up; `README.md` → Set it up in an app |
| Anything a user would notice | `blaq_reel/CHANGELOG.md`, under the version being worked on |

Before you finish, check:

1. Every option in `cli.dart` (`addOption`, `addFlag`) appears in
   `reference.md`'s command table.
2. Every key `spec.dart` reads (`json['…']`, `b['…']`, `end['…']`) appears
   in `reference.md`'s spec tables.
3. Examples in `SKILL.md` and `reference.md` still match the code: names,
   defaults, file paths.

## Writing the skill

`skill/blaq-reel/` is read by agents of every kind, in other people's
repositories. So:

- **No machine-specific paths.** Paths are relative to the app's folder or
  to the skill's own folder. Never `/Volumes/...` or `/Users/...`.
- **No tool-specific names.** Say "render a still and look at it", not the
  name of one agent's tool. Commands are shell commands any agent can run.
- **Plain, exact language.** Short sentences, concrete values, real
  defaults. Say what the person decides and what the agent does.
- **Generated media is optional.** Only an agent that can generate images or
  video offers it, and only after the person says yes.
- `SKILL.md` keeps its front matter (`name`, `description`); the
  description says when to use the skill. Keep `SKILL.md` about the
  workflow and `reference.md` about the facts.

## Commands

From `blaq_reel/`:

```bash
flutter pub get
dart analyze            # must report no issues
flutter test            # must pass
dart format lib test bin
```

From an app that uses BlaqReel: `dart run blaq_reel <command>`; see
`reference.md`.

## How the code is laid out

- `lib/src/`: the engine.
  - `time.dart`: Track, Ease, TimeWarp, the clock.
  - `camera.dart`, `motion.dart`.
  - `layer.dart`: Device, Layer, Lift, Pick, Tap, Scroll, TypeText, Glass.
  - `media.dart`: ReelImage, Media, TapHand.
  - `words.dart`, `backdrop.dart`, `ground.dart`.
  - `scene.dart`: Scene, Transition, Reel, SceneSpan, pace.
  - `audio.dart` + `sfx.dart`: the soundtrack and built-in sounds.
  - `stage.dart`: ReelStage draws a reel at a moment.
  - `render.dart`: ReelRenderer: stills, video, previews.
  - `spec.dart`: ReelSpec reads a reel as data; ReelKit.
  - `runner.dart`: `blaqReelMain`, the tasks the CLI drives, the render worker's `serve` loop.
- `lib/src/packs/`: GlassLayers, KineticLaunch, DarkGlow, StoryAd, Brand.
- `lib/cli/`: the command line. **It must not import Flutter**: a plain
  `dart run` has no `dart:ui`. That is why `sfx.dart` is apart from
  `audio.dart`, and why the CLI reaches the engine only by running
  `flutter test` on the app's `render_test.dart`.
  - `studio.dart`: the studio's server, its render worker and endpoints.
  - `studio_page.dart`: the Library page.
  - `builder_page.dart`: the builder's steps.
  - `animator_page.dart`: the timeline editor, and the intro and outro editors.
  - `worker.dart`: the kept-running renderer.
  - `files.dart`: reveal, open, clean.
  - `ai.dart` + `claude_run.dart`: drafting with Claude Code.

## Constraints that bite

- **Everything on the stage is a function of the reel's time.** Screens are
  built once and kept; the clock never rebuilds them.
- **Real I/O inside a widget test only finishes in `tester.runAsync`** or
  done synchronously. An awaited disk, network or process call outside it
  hangs with no error. Pictures are decoded this way
  (`ReelImage.decodePending`).
- **A test pump draws only scheduled frames.** Anything waiting on a
  post-frame callback must `scheduleFrame()`.
- **`debugDisableShadows`** must be true again before a test ends; the
  renderer turns it off only around each frame.
- **Throttled `debugPrint` waits on a timer the test clock never runs.**
  In the render worker, use `debugPrintSynchronously`.
- **The editor in the studio mirrors the renderer** (camera, timing, word
  layout, pace): change one, change the other, and check them side by side
  with a still and a screenshot.
- **Look at stills before calling a reel done.**

## Conventions

- `///` doc comments on everything public, saying what it is and why.
- Tests are Given-When-Then, in `blaq_reel/test/`.
- Words on screen in examples come from what the app really does; never
  invented claims.
- Commits: plain, imperative subject; a body that says why. **No AI
  attribution or co-author trailers.**
- The repository is private: `Creative-Blaq-Studios/blaqreel`. Ordinary
  pushes to `main` are fine; ask before anything that changes its
  visibility, creates releases, or publishes the package.
