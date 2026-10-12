# Installing BlaqReel: instructions for an AI agent

You are an AI coding agent (Claude Code, Codex, Cursor or another) and the
person has asked you to install BlaqReel in a Flutter app, or to make a
promo video with it. Follow these steps in order. Each ends with a check;
don't go on until it passes. Tell the person briefly what you did at each
step, and ask before anything that needs their decision.

BlaqReel lives at `https://github.com/Creative-Blaq-Studios/blaqreel`:
`blaq_reel/` is the Dart package, `skill/blaq-reel/` is the skill that
tells you how to make a reel. Nothing goes into the app's `lib/`;
everything BlaqReel adds is in `app_reels/` and `pubspec.yaml`.

## 1. Check the machine

```bash
flutter --version          # Flutter 3.44 or newer
ffmpeg -hide_banner -encoders 2>/dev/null | grep libx264   # FFmpeg with libx264
git --version
```

- No FFmpeg: on macOS `brew install ffmpeg`; on Linux the package manager;
  on Windows `winget install ffmpeg`. Ask the person before installing.
- The repository may be private. If cloning fails with a 404 or an
  authentication error, the person needs access to it and to be signed in
  (`gh auth login`). Tell them; don't work around it.

## 2. Get BlaqReel's skill

The skill is two Markdown files you will follow to make reels. Keep one
copy per machine:

```bash
git clone https://github.com/Creative-Blaq-Studios/blaqreel.git ~/.blaqreel \
  || git -C ~/.blaqreel pull
```

Then make the skill available to yourself, the way your agent loads
instructions:

| Agent | Do |
| --- | --- |
| Claude Code | `mkdir -p ~/.claude/skills && ln -sfn ~/.blaqreel/skill/blaq-reel ~/.claude/skills/blaq-reel` |
| Codex | add a line to `~/.codex/AGENTS.md` (create it if needed): `For promo videos of a Flutter app, follow ~/.blaqreel/skill/blaq-reel/SKILL.md and its reference.md.` |
| Cursor | add `.cursor/rules/blaq-reel.mdc` in the app saying the same, with `alwaysApply: false` and a description mentioning promo videos |
| Other | read `~/.blaqreel/skill/blaq-reel/SKILL.md` and `reference.md` now |

**Check:** you can read `~/.blaqreel/skill/blaq-reel/SKILL.md`.

## 3. Find the app

Work in the Flutter app's folder: the one with a `pubspec.yaml` that
depends on `flutter` and has a `lib/main.dart`. In a monorepo, ask which
app if there is more than one.

## 4. Add the dependency

In the app's `pubspec.yaml`, under `dev_dependencies`:

```yaml
  blaq_reel:
    git:
      url: https://github.com/Creative-Blaq-Studios/blaqreel.git
      path: blaq_reel
      ref: main
```

Then `flutter pub get` (from the workspace root if the app is in a pub
workspace).

**Check:** `dart run blaq_reel --help` lists the commands.

## 5. Create `app_reels/`

```bash
dart run blaq_reel init
dart run blaq_reel doctor
```

**Check:** `doctor` passes. Fix what it reports (usually FFmpeg's path in
`app_reels/reel.yaml`).

## 6. Write the host

`app_reels/host.dart` wraps a screen the way the app draws it. Base it on
the app's own widget tests, golden tests or store-screenshot set-up if it
has them: the same theme, the same fake data, no network. It must:

- load the app's **fonts** (or every letter draws as a box);
- give screens the providers, localisations and demo data they need;
- put screens on `Material(type: MaterialType.transparency)`.

Set `brand` in `app_reels/reel.yaml` from the app's theme: its ink
(text), paper (background) and accent colours, and its display and text
font families.

## 7. Write the kit

`app_reels/kit.dart` lists the screens a reel can use, the app's logos and
its web address (`ReelKit`; see `reference.md` → Setting up). Start with
the screens that show the app's main features, each in a good moment with
real-looking demo data. Pass it to `blaqReelMain(kit: kit, …)` in
`app_reels/render_test.dart`.

If the app has a logo widget, offer it as `mark` (and a wordmark as
`wordmark`), built from the clock so it animates. If it has none, leave
`logos` empty; reels then open and close without one.

## 8. Say what the app does

Write `app_reels/copy.md`: what the app really does, in its own words,
from its store listing, README or screens. Words in reels come only from
here.

## 9. Prove it

`init` made a first reel, `first`, in `app_reels/cuts/first.dart`; point
it at one of the app's screens, then:

```bash
dart run blaq_reel stills first --at 1
```

Look at the still yourself. Fix what's wrong (boxes for letters: fonts; a
red error screen: a missing provider or demo data, see
`app_reels/out/last.log`).

**Check:** a still of a real screen that looks like the app.

## 10. Hand over

Tell the person BlaqReel is ready, and offer the two ways to make a reel:
with you, by conversation (follow `SKILL.md`), or themselves in the studio
(`dart run blaq_reel studio`, then **Build**). Mention that `app_reels/out/`
holds the videos and `dart run blaq_reel clean` clears it out.

If they asked for a video, go straight on with `SKILL.md`, from step 1.

## Updating

```bash
git -C ~/.blaqreel pull           # the skill
flutter pub upgrade blaq_reel     # the package, in the app
```
