---
name: blaq-reel
description: Use when someone wants a promo video, reel, Short, launch film, ad or product walkthrough made from a Flutter app's real screens (social, YouTube, website — not App Store previews). Sets BlaqReel up in the app if needed, then guides the person step by step — the brief, which screens and parts to feature, the ground, the intro and end card, the length and sound, optional AI-generated media — writing the reel as a spec the BlaqReel studio can open, checking it with stills, and rendering MP4s in every format. Also for editing an existing reel, cleaning up renders, or answering how BlaqReel works.
---

# BlaqReel: promo videos from a Flutter app's real screens

BlaqReel draws an app's real widgets in 3D inside `flutter test`, one frame
at a time on a fixed clock, and encodes them with FFmpeg. A reel lives in
the app's `app_reels/` folder; nothing ships in the app and the app's own
code (`lib/`) is never changed.

This file is for any AI agent (Claude Code, Codex, Cursor, or another) that
can read files, write files and run shell commands in the app's folder.
`reference.md`, beside this file, has the spec format, the Dart API and
every command. Read it before writing a reel.

## How you work

- **The person decides; you do the work.** Ask about what only they can
  know (what the video is for, what it should say, how it should feel).
  Infer the rest from the app and say what you assumed.
- **One decision at a time.** End each step with a clear question and stop.
  Don't stack decisions, and don't choose for them unless they say "you
  pick". Say which step you are on ("Step 3 of 6: the ground").
- **Look before you show.** Render stills and look at them yourself before
  asking the person to look. Fix what reads badly first.
- **Write the reel as a spec,** `app_reels/specs/<name>.json`. A spec is the
  same file the studio's builder writes, so the person can open your reel
  in the studio later and fine-tune it by hand (`dart run blaq_reel studio`,
  then Build). Write Dart (`app_reels/cuts/`) only for what specs can't do
  yet, and say so.
- **Never touch `lib/`.** Everything goes in `app_reels/`.
- **Only true claims.** Words on screen come from what the app really does:
  `app_reels/copy.md`, its store listing, its screens. No invented numbers,
  testimonials or awards.

Commands run from the app's folder as `dart run blaq_reel <command>`.

## Step 0: is BlaqReel set up?

Check, in order, and fix what's missing (see `reference.md` → Setting up):

1. `pubspec.yaml` has `blaq_reel` under `dev_dependencies` (from git or a
   local path), and `flutter pub get` has run.
2. `app_reels/` exists (`dart run blaq_reel init`), and
   `dart run blaq_reel doctor` passes (FFmpeg with libx264, Flutter).
3. `app_reels/host.dart` wraps a screen the way the app draws it: theme,
   **fonts** (or every letter draws as a box), providers, demo data, no
   network. Model it on the app's widget tests or store-screenshot set-up.
4. `app_reels/kit.dart` lists the screens a reel can use (`ReelKit`), with
   the app's logos and web address, and `render_test.dart` passes it to
   `blaqReelMain(kit: kit, ...)`. `init` does not write this file: write it.
5. `app_reels/copy.md` says what the app does, in its own words.

Prove it works with one still of one screen before going on.

## Step 1: the brief

Ask, in one short message, only what you can't find out yourself:

- **Where it will be posted.** This decides the frame and a sensible length:
  Shorts, Reels, TikTok → `vertical`, 15–30 s; YouTube or a website →
  `wide`, 20–60 s; a feed → `portrait` or `square`.
- **What it should say:** the features to show, in their words.
- **How long:** a length in seconds. Every beat stays and the reel plays
  faster or slower to fit; the intro and end card keep their own seconds.
- **The style:** Glass Layers (the default: screens whose cards lift off as
  glass layers, one word per beat), Kinetic Launch, Dark Glow or Story Ad;
  or "you pick".
- **Sound:** music and effects, effects only, or silent (no audio at all).
- **Generated media,** only if you can generate images or video (see
  below). Ask whether they'd like any; otherwise ask whether they have
  pictures or clips of their own to use.

## Step 2: the screens and what each beat features

Draft the spec: one beat per feature, each on a screen from the kit (its id
in `kit.dart`). Then run `dart run blaq_reel map <reel>`: it draws every
screen in the reel flat with each card, row, field and photo numbered and
named, and opens a page. Ask the person which parts each beat should lift,
in order ("Home: 2 and 5"). Write them into the beat's `parts` using the
type and text the map shows.

For each beat choose a move: `lift`, `scan` (reading a receipt or document),
`spread` (several things at once), `fan` (a set of similar things), `zoom`
(one figure or answer), `tap` (something pressed), `pop` (quick wins),
`orbit` (a big moment). Vary them. Push back on picks that won't read: a
beat should show the thing it is about, and a tall part lifted low on the
screen runs into the words.

A part holding a text field can type into it like a keyboard (`typing`):
the app formats it, so "5000" in a money field shows R5,000.00. A beat can
also be one piece of the app on its own (a button and its loading state) if
the kit offers it as a component.

## Step 3: the ground and the media

Run `dart run blaq_reel looks <reel> --at <a telling second>`: the same
moment on every ground, side by side. Recommend one with a reason; let them
pick. A ground can be a look (`ink`, `mesh`, `butter`, `echo`, `studio`,
`grid`), a moving pattern in the brand's colours, or a picture (generated
or theirs). Any beat can have its own.

If they want generated media, make it now (below), put it in
`app_reels/media/`, wire it into the spec, and show stills with it in.

## Step 4: the words, the intro and the end card

Write each beat's words (Glass Layers: one or two words ending in a full
stop, a verb the person does: "Share.", "Add it."). Offer an intro: up to
three short hook lines before the logo, a question or a feeling the viewer
recognises ("Who paid for {groceries}?"; braces take the accent colour), or
just the logo. Write the end card's closing line. The app's logos play their
own animation.

## Step 5: check it

Run `dart run blaq_reel storyboard <reel>`: a frame per scene with its
timing, words and sounds, and a notes box under each. Before showing it,
look at stills yourself (`dart run blaq_reel stills <reel> --at 2,5.5,9`)
and fix: words over busy screens, lifted cards out of place or covered,
something cut off, a part showing twice, text that doesn't fit. Then ask
the person for changes and repeat until they say it reads right.

## Step 6: render and hand over

`dart run blaq_reel render <reel> --format all` (or the formats they need).
It prints where each video went with a link; add `--reveal` to show it in
Finder. Check each file (`ffprobe`: size, duration, an audio stream unless
silent) and look at one frame a second as a grid
(`ffmpeg -i <video> -vf fps=1,scale=240:-1,tile=10x3 grid.png`). Tell the
person exactly where the videos are, what is a placeholder (the
synthesized music pad, macOS voice-over), and that they can open the reel in
the studio to adjust anything by hand.

When renders pile up: `dart run blaq_reel clean` (add `--finals` to remove
older videos too; `--dry-run` first to see what would go).

## Generated media

Do this only if your environment can generate images or video (an image
tool, a video tool, an API you have been given). Ask first; never generate
without a yes. If you can't generate, offer to use pictures or clips the
person provides instead.

**What helps a reel:**

| Media | Make it | Use it |
| --- | --- | --- |
| A background | The frame's shape (1080×1920 for vertical, 1920×1080 wide), calm, no text, soft detail, the brand's colours, a quiet middle where the phone sits | `"ground": {"image": "app_reels/media/bg.png", "dim": 0.2}` on the reel or a beat |
| A hand for taps | A transparent PNG of a hand pointing one finger, about 800 px wide; note where the fingertip is as fractions of the picture | `"hand": {"image": "app_reels/media/hand.png", "tip": [0.32, 0.04], "width": 200}` |
| Stickers, shapes, textures | Transparent PNGs, simple, in the brand's colours | a beat's `"media"`, with a box, timing and a move |
| A short clip (waves, light, particles) | A few seconds, loopable, no text | `dart run blaq_reel media frames clip.mp4 --name waves`, then `"media": [{"frames": "app_reels/media/waves", "fps": 30, "behind": true}]` |

**How to animate it:** pictures in a beat's or the reel's `"media"` take a
`box` (left, top, width, height in percent of the frame), `at` and `until`
(seconds), `behind` (behind the screens), and a `move`: `float`, `rise`,
`drift`, `zoom`, `spin` or `pop`. A ground picture breathes slowly on its
own. Use motion sparingly: one moving thing at a time reads better.

**Rules:** no text inside generated pictures (the reel sets its own words);
no real people's faces or other companies' logos; keep the app's screens
the hero. Save everything in `app_reels/media/` so it is versioned with the
reel. Look at stills with the media in before showing the person.

## What goes wrong

- **A part matched nothing.** Use the type and text the map shows; check the
  screen's demo data draws it.
- **"No Material widget found"** from a lifted row: the host's wrap must put
  screens on `Material(type: MaterialType.transparency)`.
- **Every letter is a box.** The host isn't loading the app's fonts.
- **A part shows twice.** It sits inside another lifted part; lift one.
- **Words over a busy screen.** Move the words onto the ground, give them a
  plate, or put them behind the phone.
- **A render hangs with no error.** Something in a scene waits on real I/O
  inside the test's clock: wrap it in `tester.runAsync`.
- **A screen throws or draws blank.** It needs a provider, theme or demo
  data the host's wrap doesn't give it. The full error is in
  `app_reels/out/last.log`.
- **Taps that navigate.** A real press runs the app's code; anything routed
  through a router the host doesn't have will throw. Show navigation as
  separate beats.
