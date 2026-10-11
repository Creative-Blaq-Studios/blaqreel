---
name: blaq-reel
description: Use when someone wants a promo video, reel, Short, launch film, ad or product walkthrough made from a Flutter app's real screens (social, YouTube, website — not App Store previews). Guides the person step by step — brief, which parts of which screens to feature, which background, the storyboard, the render — showing a page to decide from at each step, then writes BlaqReel scenes in the app's app_reels/ and renders MP4s in every format with sound. Also for editing an existing reel, changing its backgrounds per scene, adding voice-over or music, or setting BlaqReel up in a new Flutter app.
---

# BlaqReel: promo videos from a Flutter app's real screens

BlaqReel (`/Volumes/BlaqSSD/work/code/BlaqReel/blaq_reel`) draws an app's
real widgets in 3D inside `flutter test`, one frame at a time on a fixed
clock, and pipes them to FFmpeg. A reel is Dart in the app's `app_reels/`.
Nothing ships in the app; `lib/` is never changed.

Read `reference.md` beside this file for the API before writing scenes.

## Two ways in

- **The studio's builder** (`dart run blaq_reel studio`, then Build): the
  person makes the reel themselves, step by step, with the AI drafting as
  much or as little as they want. It saves `app_reels/specs/<name>.json`.
  Offer this first to anyone who wants control. The app needs a `ReelKit`
  of its staged screens (see Khumio's `app_reels/kit.dart`) and, for AI
  drafts, an `app_reels/copy.md` of what the app really does.
- **This conversation**: the five steps below, with a page at each.

## Guide the person through five steps

The person decides what the video shows and how it looks; you do the rest.
Every step ends at a page they can look at and a note they can copy back.
**Stop at the end of each step and wait for their answer.** Don't stack two
decisions into one message, and don't pick for them unless they say "you
choose". Say which step you are on ("Step 2 of 5: what to feature").

If `app_reels/` is missing, set it up first: `dart run blaq_reel init` from
the app root, then write `host.dart` from the app's widget-test setup
(fakes, theme, fonts). It must load the app's fonts or every glyph is a box.

### 1. The brief

Ask, in one short message, only what you can't infer:
- Where it will be posted (decides formats and length: Shorts/Reels/TikTok
  9:16 10–30 s; YouTube or the website 16:9 20–60 s; a feed 4:5 or 1:1).
- What it should say: the features, in their words. Offer the app's store
  listing copy if it has one.
- Which style pack, or "you pick" (table below).
- Sound: music they have, the placeholder pad, voice-over or none.

Then write a first cut with your best guess at screens and words, so step 2
has screens to show.

### 2. What to feature

`dart run blaq_reel map <reel>` renders every screen flat with a numbered
outline on each card, row, field and photo that can lift, be tapped or be
zoomed into, named the way the app's code names it, and opens a page.
Tell them to click the parts they want, in order, and paste the note back.
Translate their picks into `lift:` / `Tap(where:)` / `Scroll` using the
`Pick` the page gives for each number.

Push back when a pick won't read: a feature should show the thing it is
about (a scan beat shows the receipt being read, not a totals table), and a
tall part lifted low on the screen runs into the word.

If a feature lives on a screen the reel doesn't have yet, stage that screen
the way the app's store screenshots or widget tests do, and map again.

A beat can also be about one piece of the app on its own (a button and its
loading spinner, a loading placeholder, a progress ring): register it with
`ReelScreen.component` and it shows large on the ground with no phone,
pressed for real by its `taps`. Glass Layers and Story Ad show components.

### 3. The ground

`dart run blaq_reel looks <reel> --at <a telling second>` renders that
moment on every Glass Layers ground (ink, mesh, butter, studio, grid, echo)
side by side and opens a page. They choose one for the reel, and can give
any beat its own (`GlassBeat(look: …)`) or their own colours
(`ground: Backdrop(...)`). Recommend one, with a reason, but let them pick.

### 4. The storyboard

`dart run blaq_reel storyboard <reel>` renders a frame from each scene with
its timing, words and sounds, and a notes box under each. They write what
should change; the note collects it. Make the changes, run it again, until
they say it reads right. Look at the frames yourself too, and fix what reads
badly before showing them: words over light screens, lifted cards out of
focus, crowded end cards, something cut off.

### 5. Render and review

`dart run blaq_reel render <reel> [--format all]`. Check with `ffprobe`
(size, fps, frame count, duration, an audio stream) and `ffmpeg -af ebur128`
(about −16 LUFS), and look at one frame a second as a grid
(`fps=1,scale=240:-1,tile=10x3`). Then point them at the studio
(`dart run blaq_reel studio`), where every rendered video plays with its
timeline, and send the MP4s. Say plainly what is a placeholder (pad music,
`say` voice-over).

## Packs

| Pack | Shape | Use |
| --- | --- | --- |
| `GlassLayers` | 9:16, 10–30 s | open mark → beats (one word, cards lift off the screen) → end card |
| `KineticLaunch` | 16:9, 15–30 s | line arrives word by word, key part marked, device sweeps in |
| `DarkGlow` | 16:9, 20–40 s | one camera past glowing screens, title and line beside each |
| `StoryAd` | 9:16, 30–60 s | hook → problem → meet → Glass beats → proof → CTA, with voice-over |

All take a `Brand.from(config)` and a `Format`, and lay out for every format.

## What goes wrong (learned the hard way)

- **The lift matched nothing.** The error names scene/layer/lift. Use the
  map's `Pick` for that part; check the screen's demo data draws it.
- **"No Material widget found"** from a lifted row: the host's `wrap` must
  put screens on `Material(type: MaterialType.transparency)`.
- **A lifted card is blurred.** Every lifted card must sit in the camera's
  sharp band (`focus` ± `depth`); the packs do this, hand-written scenes
  must too. Lifted means in focus; only the screen behind softens.
- **A tall lift runs into the word.** Give that beat `zoom: 0.86` and
  `framing: Offset(0, -34)`, or lift a smaller part.
- **Words over a light screen.** Words belong on the ground; move the word,
  not the contrast.
- **A set piece vanishes when focus moves** (a floor, a frame): give its
  layer `ignoreFocus: true`.
- **Real I/O hangs the test silently.** Inside `flutter test`, anything that
  touches disk or a process runs synchronously or in `tester.runAsync`.
- **Shadows draw as solid slabs.** flutter_test sets `debugDisableShadows`;
  the renderer lifts it only while a frame paints.
- **Nothing happens after a post-frame callback in a test.** A test pump
  draws only when a frame is scheduled; call `scheduleFrame()`.
- **Navigation.** A `Tap(press: true)` really taps the app; anything routed
  through a router the host doesn't have will throw. Show navigation with
  separate scenes.

## Claims

Words on screen are marketing copy: use the app's store listing and what the
app really does. Never invent numbers, testimonials or awards.
