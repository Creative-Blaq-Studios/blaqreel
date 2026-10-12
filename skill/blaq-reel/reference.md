# BlaqReel reference

`import 'package:blaq_reel/blaq_reel.dart';` for the blocks,
`import 'package:blaq_reel/packs.dart';` for the packs.

## Time

```dart
1.5.s, 250.ms                       // Durations
Track.from(0).to(1.s, 100, Ease.out).hold(2.s).to(3.s, 0)
Track([Keyframe(0.s, 0), Keyframe(1.s, 1, ease: Ease.inOut)])
Ease.out / arrive / inOut / leave / linear / drift
progress(t, from, to, curve: Ease.out)  // 0..1
Scene(speed: Track.from(1).hold(1.s).to(1.4.s, 0.4))  // slow motion
Reel(motionBlur: 2)                    // frames blended per output frame
```

## A reel

```dart
Reel(
  name: 'promo', format: Format.vertical, fps: 30,
  backdrop: Backdrop(top:, bottom:, glows: [Glow(color, center:, radius:)]),
  scenes: [Scene(...), ...],
  transitions: [Transition.swing(direction: -1), Transition.zoomThrough(),
                Transition.fade(), Transition.wipe(origin:), Transition.rise(),
                Transition.cut],   // shorter lists repeat their last entry
  soundtrack: Soundtrack(music: Music('pad'), voice: [VoiceLine(at, path, text)]),
)
Reel.single(name:, length:, backdrop:, camera:, layers:, words:)
```

Formats: `vertical` 1080×1920, `wide` 1920×1080, `square`, `portrait` 4:5.
The stage is in logical units: vertical is 360×640 at 3×.

## A scene

```dart
Scene(
  name: 'Share.', length: 5.s,
  camera: Camera([Shot(at: 0.s, tilt: 40, turn: -30, zoom: .4, blur: 4), ...])
       // or Camera.tracks(tilt:, turn:, roll:, zoom:, panX:, panY:,
       //                  focus:, aperture:, blur:)
  layers: [...],
  words: [Words('Share{.}', at: 2.s, until: 4.s, style:, accent:,
                reveal: Reveal.letters|words|typewriter|fade,
                align: Alignment.bottomLeft, maxWidth: 1, marker: true)],
  cues: [Cue(1.5.s, 'rise')],   // tap tick pop rise whoosh chime, or a path
)
```

Camera: `tilt` takes the top away, `turn` the right side away, `zoom` scales
the world, `pan` moves it (stage units), `focus` is the sharp depth, `depth`
how far either side of it stays sharp, `aperture` blur per 100 units beyond
that. Keep every lifted card inside `focus ± depth`.

## Layers

```dart
Layer(widget, size: Size(200, 80), position: Offset(0, -100),
      motion: Motion(x:, y:, z:, tilt:, turn:, roll:, scale:, opacity:, blur:),
      glass: Glass(depth: 8), carry: true, ignoreFocus: true)
Layer.timed((t) => KhumioMark(progress: progress(t, 0.s, 1.s)), size:)
Layer.screen(HomeScreen(),            // drawn through host.wrap, on a Device
  statusBar:, motion:,
  lifts: [Lift(where: Pick..., motion: Motion(z: Track...), hole: Widget,
               radius: 26, glass: Glass(), carry: false)],
  taps: [Tap(where: Pick.text('Done'), at: 3.s, press: false)],
  scrolls: [Scroll(offset: Track.from(0).to(2.s, 600))],
  typing: [TypeText(text: '…', at: 1.s, perCharacter: 45.ms, sound: 'tick')])
  // Keyed as a keyboard would: each character through the field's input
  // formatters, then its onChanged, so the app reacts (a search filters).
Layer.component(AppButton(...), size: Size(320, 80),   // through host.wrap, no phone
  taps: [Tap(where: Pick.type<AppButton>(), at: 2.s, press: true)])
```

`Lift` z is height above its screen. Lifts are found once, at the start, in
the screen as drawn: lifts on a screen that scrolls later stay where they
were found.

## Pick

```dart
Pick((w) => w is WalletCard && w.shared)
Pick.type<SayItRow>().nth(1)
Pick.typeName('_Answer')
Pick.text('Total', contains: true, anyCase: true)
Pick.type<AppCard>().containing(Pick.text('Total'))   // innermost match
Pick.key(ValueKey('x'))
```

## Packs

```dart
// GlassBeat(partMoves: [PartMove(to: Offset(-90, -250), z: 200, scale:,
//   tilt:, turn: 12, roll:, delay: 400.ms, rise: 900.ms, scan: true), null, ...]): each
//   part over the move. Specs: on each part, "to": [x, y] (from the screen's
//   centre), "z", "scale", "tilt", "turn", "roll", "delay" (ms), "scan".
// PartMove(typing: PartTyping('186', at: 3700.ms, every: 90.ms)): keys typed
//   into the field in a lifted part once it lands (or at `at`, from the
//   beat's start), through the field's own formatters, so "186" in a money
//   field shows R186.00; the lifted copy shows it.
// Specs: "open": {"logo": "mark", "length": 1.6, "lines": ["Who paid {first}?"],
//   "reveal": "words", "words": {style as a beat's words}, "logoScale",
//   "logoPlaces": {"vertical": {"dx", "dy"}}} (or "mark", or false); "end"
//   also takes "lineWords", "urlWords", "logoScale", "logoPlaces", "blur";
//   "logo": null is none; "entrance": "zoom" brings a logo in by the
//   studio's zoom on top of its own animation (else just its own, faded in).
//   "end": {"logo", "line", "url" (false for none), "length", "fan", "off"};
//   a beat's "skip": true leaves it out; "length": 30 runs the whole reel in
//   30 s, every timing scaled to fit (it sets the pace).
// Reel.pace / reel.withPace(1.25): the whole reel plays faster (or slower,
//   below 1); every timing scales, music and voice keep their speed. Specs:
//   "pace" at the top. reel.played(t) and reel.atVideo(t) convert clocks.
// PartMove(layer: 2) / Lift(layer:): stacking among the beat's lifted
//   parts, lowest drawn first, whatever their heights. Specs: "layer". Specs: on the part,
//   "typing": {"text", "at" (ms), "every" (ms), "sound": false}.
// Backdrop(top:, bottom:, light: false, motion: GroundMotion(pattern:
//   GroundPattern.aurora, colours: [...3], speed: 1, seed: 7, bpm: 120,
//   grain: 0.6)): a moving ground. Specs: "ground": {"pattern", "speed",
//   "seed", "beat", "grain", "palette": {"top", "bottom", "colours", "light"}}
//   on the reel or a beat.
// GlassBeat(words: GlassWords(color:, accent:, size: 96, weight:, reveal:,
//   at:, until:, anchor: Alignment.topCenter, offset: Offset(0, .04),
//   width: .7, plate: Color(...), plateBlur: 8, behind: true)), and
//   GlassLayers(words: GlassWords(...)) for the reel; the beat's win.
// Specs: reel "words": {"color", "accent", "size", "weight", "reveal",
//   "plate": none|soft|solid, "layer": above|behind}; a beat's "words" the
//   same plus "at", "until" (s) and "places": {"vertical": {"pos": "bl",
//   "dx", "dy" (% of the frame), "width" (% of the safe area)}}.
// GlassBeat(move: GlassMove.spread): lift, scan, spread, fan, zoom, tap,
// pop, orbit. Specs: "move": "spread" ("sweep" is scan).
// Lift(to: Offset(-120, -230), travel: Track…) sends a part to a place on
// its screen (from the screen's centre), wherever it was found.
// GlassBeat(piece: Size(320, 80)) makes a beat about one component: `screen`
// is then the component, shown large on the ground, pressed by `taps`.
GlassLayers(brand:, format:, beats: [GlassBeat('Share.', screen:, lift: [Pick…],
    liftRadius:, zoom:, framing:, taps:, scrolls:, typing:, slowLift: .5,
    look: GlassLook.butter, ground: Backdrop(...))],     // per-beat ground
  open: (t) => mark, openSize:, end: GlassEnd(logo: (t) => …, logoSize:, line:, url:),
  hole: (r) => …, statusBar:, look: GlassLook.mesh, ground: Backdrop(...),
  music:, motionBlur:).build('name')
// GlassLook: ink, mesh, butter, studio, grid, echo. A beat's own look
// crossfades with its neighbours'. BLAQ_REEL_LOOK overrides every look
// (the `looks` command uses it).
KineticLaunch(brand:, format: Format.wide, beats: [KineticBeat('Split the {bill}.', screen:, lift:)],
  logo:, line:, url:).build('name')
DarkGlow(brand:, format: Format.wide, stops: [GlowStop(screen:, title: 'Shared {money}', line:, lift:)],
  logo:, url:, motionBlur: 2).build('name')
StoryAd(brand:, hook: [...], problem: [...], meet: (t) => mark, meetLine:, beats: [GlassBeat…],
  proof: [...], end: GlassEnd(...), voice: {'hook': StoryVoice(path, text)}).build('name')
```

## The app's side

```dart
// app_reels/host.dart
final host = ReelHost(
  wrap: (screen) => ProviderScope(overrides: demo, child: MaterialApp(theme:, home: screen)),
  ready: (tester) async { await tester.runAsync(loadFonts); await tester.pumpAndSettle(); },
  settle: (tester) async => …,   // after lifts are cloned: let images decode
);
// app_reels/render_test.dart
void main() {
  final config = ReelConfig.load('app_reels/reel.yaml');
  blaqReelMain(config: config, host: host, reels: {'promo': (f) => promo(config, f)});
}
```

```dart
// app_reels/kit.dart: what the studio's builder and specs can use
final kit = ReelKit(screens: {
  'home': const ReelScreen(HomeScreen(), label: 'Home'),
  // A component: centred, on no background, in a box a little larger than it.
  'button': ReelScreen.component(
    Center(child: AppButton(title: 'Save', onTap: () => Future.delayed(1800.ms))),
    label: 'Button · loading', size: const Size(320, 80),
    taps: [Tap(where: Pick.type<AppButton>(), at: 2.s, press: true)]),
}, logos: {...}, statusBar:, hole:, url:);
```

reel.yaml: `name`, `fps`, `format`, `out`, `ffmpeg`, `music` (`pad` or a
path), `sound`, `brand: {ink, accent, paper, fonts: {display, text}}`.

## CLI (from the app root)

```
dart run blaq_reel init | doctor | list
dart run blaq_reel map <reel>                     # step 2: numbered parts of every screen
dart run blaq_reel looks <reel> --at 4.2          # step 3: every ground side by side
dart run blaq_reel storyboard <reel>              # step 4: a frame per scene, with notes
dart run blaq_reel stills <reel> --at 1,3.5 [--format wide] [--open]
dart run blaq_reel render <reel> [--format vertical,wide|all] [--fps 60] [--no-audio] [--open]
dart run blaq_reel studio <reel> [--format wide] [--port 4455]
dart run blaq_reel sfx [--pad 30]
dart run blaq_reel voice --script app_reels/voice/script.yaml [--voice Tessa]
```

Output: `out/<reel>.mp4` for the default format, `out/<reel>-<format>.mp4`
otherwise; stills in `out/stills/`; pages in `out/map/`, `out/looks/`,
`out/storyboard/`; the studio's previews in `out/studio/`; the last run's
full log in `out/last.log`.
