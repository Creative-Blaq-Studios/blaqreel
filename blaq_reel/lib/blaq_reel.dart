/// Promo videos made from a Flutter app's real screens.
///
/// A [Reel] is a run of [Scene]s joined by [Transition]s, over a
/// [Backdrop]. Each scene has a [Camera], [Layer]s in 3D — any widget, or one
/// of the app's screens with parts that [Lift] off it, fingers that [Tap]
/// it, [Scroll]s and [TypeText] — and [Words] over the top. A [Soundtrack]
/// carries music, voice-over and cues. A [ReelHost] draws the app's
/// screens; a [ReelRenderer] draws the reel frame by frame inside
/// `flutter test` and pipes it to FFmpeg. Style packs in
/// `package:blaq_reel/packs.dart` build whole reels from a few slots.
library;

export 'src/audio.dart';
export 'src/backdrop.dart';
export 'src/camera.dart';
export 'src/format.dart';
export 'src/ground.dart';
export 'src/layer.dart';
export 'src/media.dart';
export 'src/motion.dart';
export 'src/reel.dart';
export 'src/render.dart';
export 'src/runner.dart';
export 'src/scene.dart';
export 'src/spec.dart';
export 'src/stage.dart';
export 'src/time.dart';
export 'src/words.dart';
