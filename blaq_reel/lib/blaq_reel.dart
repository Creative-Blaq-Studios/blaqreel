/// Promo videos made from a Flutter app's real screens.
///
/// A [Reel] is a [Backdrop], a [Camera] moving through [Shot]s, [Layer]s in
/// 3D — any widget, or one of the app's screens with parts that [Lift] off
/// it — and [Words] over the top. A [ReelHost] draws the app's screens; a
/// [ReelRenderer] draws the reel frame by frame inside `flutter test` and
/// pipes it to FFmpeg.
library;

export 'src/backdrop.dart';
export 'src/camera.dart';
export 'src/format.dart';
export 'src/layer.dart';
export 'src/reel.dart';
export 'src/render.dart';
export 'src/stage.dart';
export 'src/time.dart';
export 'src/words_painter.dart';
