# blaq_reel

Promo videos made from a Flutter app's real screens. Working name.

A reel is written in Dart, in the app's own `app_reels/` folder, and drawn
frame by frame inside `flutter test` on a fixed clock. Each frame is captured
from the stage and piped to FFmpeg as raw RGBA, which encodes H.264.

**v0.1** is only the engine one shot needs. See *What v0.1 does not do*.

## The blocks

| Block | What it is |
| --- | --- |
| `Layer` | Any widget at a depth. `Layer.screen(HomeScreen())` is one of the app's screens, drawn by the host on a device, clipped to its corners. |
| `Lift` | Part of a screen that comes off it toward the camera. The real widget is found in the screen as drawn, cloned, and placed exactly over where it was. It leaves a hole and casts a shadow that spreads as it rises. |
| `Camera`, `Shot` | Keyframes for tilt, turn, roll, zoom, pan, focus and aperture, each eased from the shot before. Layers away from the focus depth blur. |
| `Words` | Letters rising into place, one after another, with an accent part. |
| `Backdrop`, `Glow` | A gradient, slow glows and a vignette. |
| `Track`, `Keyframe`, `ReelClock` | Time: a number that changes over time; frame `n` at `n / fps`. |
| `Format` | Frame size, pixel ratio and safe area. `Format.vertical` is a 360×640 stage drawn at 3× into 1080×1920. |
| `ReelHost` | The one adapter an app writes: how to draw a screen with its theme, fonts and demo data. |
| `ReelRenderer` | `mount()`, `still(t, path)`, `video(path)`. |
| `ReelConfig` | Reads `app_reels/reel.yaml`: brand colours and fonts, fps, format, FFmpeg path. |

## In an app

```yaml
# pubspec.yaml
dev_dependencies:
  blaq_reel:
    path: ../../BlaqReel/blaq_reel
```

```dart
// app_reels/render_test.dart
testWidgets('proof video', (tester) async {
  final r = ReelRenderer(tester, proof(config), host: host);
  await r.mount();
  await r.video('app_reels/out/proof.mp4', ffmpeg: config.ffmpeg);
});
```

Keep `app_reels/` outside `test/`, so the app's normal `flutter test` never
runs it, and run each reel by name:
`flutter test app_reels/render_test.dart --plain-name 'proof video'`.

## Things to know

- **Real I/O never finishes in a widget test's fake-async zone.** Anything
  touching the disk or a process is synchronous or inside `tester.runAsync`.
- **flutter_test draws shadows solid** (`debugDisableShadows`). The renderer
  turns them on only while a frame paints.
- **Nested `MaterialApp`s take their `MediaQuery` size from the view**, not
  the box they sit in. A screen layer is given its device's `MediaQuery`
  above the host, which covers padding; the size an app reads from
  `MediaQuery` is still the stage's.
- A lifted widget is cloned outside its screen, so inherited widgets that
  are not part of the host's wrap (a currency scope, say) are not there.

## What v0.1 does not do

Taps (`Finger`), transitions, music, voice-over and cues, style packs, the
CLI and studio, more than one beat, motion blur, speed ramps.
