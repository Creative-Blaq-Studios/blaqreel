# Changelog

## 0.1.0 — 2026-10-11

### Added

- The proof engine: `ReelClock`, `Track` and `Keyframe`; `Format` with
  vertical, wide and square; `Camera` and `Shot` (tilt, turn, roll, zoom,
  pan, focus, aperture, blur) with perspective; `Layer` and `Layer.screen`
  on a `Device`; `Lift`, which clones a real widget out of a screen as drawn;
  `Words` with letter-by-letter rise and an accent; `Backdrop` and `Glow`.
- `ReelStage`, which draws a reel at a moment without rebuilding the app's
  screens.
- `ReelRenderer`: frames on a fixed clock inside `flutter test`, stills as
  PNG, and video piped as raw RGBA to FFmpeg (H.264, bt709, light grain
  against banding).
- `ReelHost` and `ReelConfig` (`app_reels/reel.yaml`).
- First use: Khumio's five-second proof.
