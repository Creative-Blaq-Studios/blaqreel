---
name: blaq-reel
description: Use when someone wants a promo video, reel, Short, launch film, ad or product walkthrough made from a Flutter app's real screens (social, YouTube, website — not App Store previews). Turns a brief into BlaqReel scenes in the app's app_reels/, looks at stills, fixes what reads badly, and renders MP4s in every format with sound. Also for editing an existing reel, adding voice-over or music, or setting BlaqReel up in a new Flutter app.
---

# BlaqReel: promo videos from a Flutter app's real screens

BlaqReel (`/Volumes/BlaqSSD/work/code/BlaqReel/blaq_reel`) draws an app's
real widgets in 3D inside `flutter test`, one frame at a time on a fixed
clock, and pipes them to FFmpeg. A reel is Dart in the app's `app_reels/`.
Nothing ships in the app; `lib/` is never changed.

Read `reference.md` beside this file for the API before writing scenes.

## The loop

1. **Brief.** Get: which pack (or "you pick"), screens, length, formats,
   words, sound. Pick defaults from the packs below rather than asking
   about everything.
2. **Storyboard.** A plain HTML page of beats with timings, words and what
   lifts, published as an artifact for approval (the user is visual). Skip
   only when the user says to just make it.
3. **Set up** if `app_reels/` is missing: `dart run blaq_reel init` from the
   app root, then write `host.dart` from the app's widget-test setup (fakes,
   theme, fonts). It must load the app's fonts or every glyph is a box.
4. **Scenes.** A cut in `app_reels/cuts/<name>.dart`, registered in
   `render_test.dart`'s `reels:` map as `(format) => cut(config, format)`.
5. **Stills.** `dart run blaq_reel stills <reel> --at …` at every moment that
   matters: each beat's settle, each lift at its height, each word landed,
   mid-transition, the end card. Read the PNGs (contact-sheet them with
   ffmpeg `hstack`/`tile`). Fix, render again, look again. Never skip this.
6. **Render.** `dart run blaq_reel render <reel> [--format all]`. Check with
   `ffprobe` (size, fps, frame count, duration, an audio stream) and
   `ffmpeg -af ebur128` (about −16 LUFS). Look at one frame a second as a
   grid (`fps=1,scale=240:-1,tile=10x3`).
7. **Hand over.** Send the MP4s and a contact sheet; say what works and what
   is placeholder (pad music, `say` voice-over).

`dart run blaq_reel studio <reel>` serves a scrubber on localhost:4455 that
re-renders when files change; offer it when the user wants to iterate.

## Packs

| Pack | Shape | Use |
| --- | --- | --- |
| `GlassLayers` | 9:16, 10–30 s | open mark → beats (one word, cards lift off the screen) → end card |
| `KineticLaunch` | 16:9, 15–30 s | line arrives word by word, key part marked, device sweeps in |
| `DarkGlow` | 16:9, 20–40 s | one camera past glowing screens, title and line beside each |
| `StoryAd` | 9:16, 30–60 s | hook → problem → meet → Glass beats → proof → CTA, with voice-over |

All take a `Brand.from(config)` and a `Format`, and lay out for every format.

## What goes wrong (learned the hard way)

- **The lift matched nothing.** The error names scene/layer/lift. Private
  widgets: `Pick.typeName('_Answer')`. A card around a label:
  `Pick.type<AppCard>().containing(Pick.text('Total'))`. Check the
  screen's demo data actually draws it.
- **"No Material widget found"** from a lifted row: the host's `wrap` must
  put screens on `Material(type: MaterialType.transparency)`.
- **A tall lift runs into the word.** Give that beat `zoom: 0.86` and
  `framing: Offset(0, -34)`, or lift a smaller part.
- **Words over a light screen.** Words belong on the dark ground; the screen
  dims and falls back when it lifts. Move the word, not the contrast.
- **Something stays sharp that should blur, or the reverse.** Focus follows
  the hero lift's height; keep the lift and the camera's focus on the same
  times and ease.
- **Real I/O hangs the test silently.** Inside `flutter test`, anything that
  touches disk or a process runs synchronously or in `tester.runAsync`.
- **Shadows draw as solid slabs.** flutter_test sets `debugDisableShadows`;
  the renderer lifts it only while a frame paints. Don't fight it elsewhere.
- **Nothing happens after a post-frame callback in a test.** A test pump
  draws only when a frame is scheduled; call `scheduleFrame()`.
- **Navigation.** A `Tap(press: true)` really taps the app; anything routed
  through a router the host doesn't have will throw. Keep presses for
  switches and local state; show navigation with separate scenes.

## Claims

Words on screen are marketing copy: use the app's store listing and what the
app really does. Never invent numbers, testimonials or awards. Music from
`music: pad` and voice from `dart run blaq_reel voice` are placeholders;
say so when handing over.
