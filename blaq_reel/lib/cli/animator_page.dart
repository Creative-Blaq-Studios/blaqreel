/// The builder's Timeline editor: one beat in the real frame (9:16, 4:5,
/// 1:1, 16:9) with the platform's safe zone, a track per lifted part and
/// one for the words, and an inspector in the side column for whichever is
/// selected. It plays live with the renderer's own camera, tracks, eases
/// and per-part moves ported to the page (`packs/glass_layers.dart`,
/// `stage.dart`), and lays the words out as `WordsPainter` does, so what is
/// set here is what renders.
///
/// It draws from the catalogue's flat shot of the screen, so a part that
/// runs on past what the screen shows previews as what shows; the render
/// opens it out to all of it.
library;

/// The editor's styles.
const animatorCss = r'''
.tled { display: grid; grid-template-rows: auto minmax(0, 1fr) auto; height: min(78vh, 900px); min-height: 520px; border: 1px solid var(--line2); background: var(--deep); }
.tl-bar { display: flex; gap: 6px; align-items: center; padding: 6px 8px; border-bottom: 1px solid var(--line2); flex-wrap: wrap; }
.tl-bar > button { padding: 6px 10px; font-size: 11px; }
.tl-bar > button.on, .tl-bar .seg button.on { background: var(--accent); color: #0A0A0A; }
.tl-movel { font: 600 10px var(--mono); text-transform: uppercase; letter-spacing: .08em; color: var(--muted); margin-left: 6px; }
.tl-bar > * { flex: none; }
.tl-bar .tl-move { width: 140px; padding: 5px 8px; }
.tl-bar .tl-frame-pick { width: 84px; padding: 5px 8px; }
.tl-bar .bnav { padding: 5px 8px !important; font-size: 10.5px !important; }
.tl-own { display: flex; gap: 4px; align-items: center; font: 600 10px var(--mono); text-transform: uppercase; letter-spacing: .06em; color: var(--text2); white-space: nowrap; }
.tl-own input { accent-color: var(--accent); margin: 0; }
.tl-bar .bnav { padding: 5px 10px; font-size: 14px; line-height: 1; }
.tl-bar .beatSel { width: 136px !important; padding: 5px 8px; }
.tl-bar .seg button { padding: 6px 9px; font-size: 10.5px; }
.tl-stagebox { position: relative; min-height: 0; overflow: hidden; background: #050505; display: grid; place-items: center; }
.tl-frame { position: relative; overflow: hidden; outline: 1px solid rgba(255,107,0,.5); box-shadow: 0 0 0 1px #000, 0 20px 60px rgba(0,0,0,.6); }
.tl-stage { position: absolute; left: 0; top: 0; transform-origin: 0 0; overflow: hidden; user-select: none; touch-action: none; }
.tl-stage > * { position: absolute; left: 0; top: 0; transform-origin: 0 0; }
.tl-scr { background-size: 100% 100%; border-radius: 55px; box-shadow: 0 36px 70px rgba(0,0,0,.45); overflow: hidden; }
.tl-scr .tl-hole { position: absolute; border-radius: 22px; opacity: 0; background: #F3F3F1; outline: 1px solid #E4E4E0; }
.tl-part { background-repeat: no-repeat; border-radius: 22px; box-shadow: 0 18px 40px rgba(0,0,0,.28); cursor: grab; overflow: hidden; }
.tl-part.sel { outline: 3px solid var(--accent); outline-offset: 3px; }
.tl-part .tl-sweep { position: absolute; left: 0; right: 0; height: 3px; background: var(--accent); box-shadow: 0 0 14px 4px rgba(255,107,0,.5); opacity: 0; }
.tl-part .tl-tag { position: absolute; left: 6px; top: 6px; background: var(--accent); color: #0A0A0A; font: 700 14px var(--mono); padding: 1px 6px; }
.tl-word { cursor: grab; outline-offset: 4px; }
.tl-word.sel { outline: 2px solid var(--accent); }
.tl-safe { border: 1px dashed rgba(120,120,120,.55); pointer-events: none; z-index: 300; }
.tl-safe span { position: absolute; right: 4px; bottom: 2px; font: 600 8px var(--mono); text-transform: uppercase; letter-spacing: .08em; color: rgba(120,120,120,.8); }
.tl-gv, .tl-gh { background: #FF2D9A; display: none; z-index: 310; pointer-events: none; }
.tl-gv { width: 1px; height: 100%; } .tl-gh { height: 1px; width: 100%; }
.tl-warn { left: 8px !important; top: 8px !important; z-index: 320; display: none; background: var(--warn); color: #141414; font: 700 10px var(--mono); text-transform: uppercase; letter-spacing: .05em; padding: 4px 7px; }
.tl-time { display: grid; grid-template-columns: 210px minmax(0, 1fr); border-top: 1px solid var(--line2); max-height: 230px; overflow: auto; }
.tl-names { display: grid; grid-auto-rows: 30px; border-right: 1px solid var(--line2); min-width: 0; }
.tl-head { display: flex; gap: 8px; align-items: center; padding: 0 8px; border-bottom: 1px solid var(--line2); height: 24px; }
.tl-head .tl-play { padding: 1px 8px; font-size: 11px; }
.tl-tm { font: 600 11px var(--mono); color: var(--text2); font-variant-numeric: tabular-nums; }
.tl-name { display: flex; gap: 8px; align-items: center; padding: 0 10px; border-bottom: 1px solid var(--line); font: 400 11px var(--mono); color: var(--text2); cursor: pointer; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tl-name b { color: var(--text); flex: none; }
.tl-name.on { color: var(--accent); background: #140C05; }
.tl-tracks { position: relative; min-width: 0; }
.tl-ruler { position: relative; height: 24px; border-bottom: 1px solid var(--line2); font: 400 10px var(--mono); color: var(--muted); cursor: pointer; }
.tl-ruler span { position: absolute; top: 5px; transform: translateX(-50%); pointer-events: none; }
.tl-ruler span:first-child { transform: none; padding-left: 3px; }
.tl-rows { display: grid; grid-auto-rows: 30px; }
.tl-row { position: relative; border-bottom: 1px solid var(--line); }
.tl-row.on { background: #140C05; }
.tl-bar2 { position: absolute; top: 6px; height: 18px; background: #3A2410; border: 1px solid #E06000; cursor: ew-resize; display: flex; align-items: center; padding: 0 6px; font: 600 9.5px var(--mono); color: #FFB37A; white-space: nowrap; overflow: hidden; }
.tl-row.on .tl-bar2 { background: var(--accent); color: #0A0A0A; }
.tl-bar2.words { background: #14243A; border-color: #4A7BD0; color: #9DC0FF; }
.tl-row.on .tl-bar2.words { background: #4A7BD0; color: #0A0A0A; }
.tl-ph { position: absolute; top: 0; bottom: 0; width: 2px; background: var(--text); pointer-events: none; }
.tl-insp { display: grid; gap: 0; border: 1px solid var(--line2); background: var(--surface); }
.tl-ih { display: grid; gap: 2px; padding: 12px; }
.tl-ih b { font-size: 15px; overflow-wrap: anywhere; }
.tl-sec { display: grid; gap: 8px; padding: 12px; border-top: 1px solid var(--line2); }
.lbl2 { font: 600 10px var(--mono); text-transform: uppercase; letter-spacing: .08em; color: var(--muted); display: flex; justify-content: space-between; gap: 8px; }
.lbl2 .set, .tl-knob output.set { color: var(--accent); }
.mono2 { font: 400 11px var(--mono); color: var(--text2); overflow-wrap: anywhere; }
.tl-knob { display: grid; grid-template-columns: 54px minmax(0, 1fr) 50px; gap: 8px; align-items: center; }
.tl-knob label { font: 600 10px var(--mono); text-transform: uppercase; letter-spacing: .06em; color: var(--text2); }
.tl-knob input { width: 100%; accent-color: var(--accent); }
.tl-knob output { font: 400 11px var(--mono); text-align: right; font-variant-numeric: tabular-nums; }
.tl-row2 { display: flex; gap: 6px; align-items: center; }
.tl-row2 button { padding: 5px 8px; font-size: 10.5px; }
.tl-num { width: 64px; padding: 5px 6px; font: 400 12px var(--mono); text-align: right; }
.tl-chk { display: flex; gap: 8px; align-items: center; font-size: 13px; }
.tl-chk input { accent-color: var(--accent); }
.tl-sws { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
.tl-sw { width: 22px; height: 22px; padding: 0; border: 1px solid #333; cursor: pointer; }
.tl-sw.on { outline: 2px solid var(--accent); outline-offset: 2px; }
.tl-cc { width: 28px; height: 24px; padding: 0; border: 0; background: none; }
.tl-place { display: flex; gap: 12px; align-items: flex-start; }
.tl-grid { display: grid; grid-template-columns: repeat(3, 24px); gap: 3px; }
.tl-grid button { width: 24px; height: 17px; padding: 0; background: #111; border: 1px solid #333; }
.tl-grid button.on { background: var(--accent); border-color: var(--accent); }
.tl-col { display: grid; gap: 6px; }
.tl-overlap { display: flex; gap: 8px; align-items: center; border: 1px solid var(--warn); color: var(--warn); padding: 8px; font-size: 12px; }
.tl-overlap[hidden] { display: none; }
.tl-overlap span { flex: 1; }
.pmode { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin: 0 0 14px; }
.pmode h1 { margin: 0; }

/* The inspector fits its column: nothing in it may push it wider. */
.tl-insp, .tl-insp * { min-width: 0; }
.tl-insp { width: 100%; overflow: hidden; }
.tl-insp .tl-sec > *, .tl-insp .tl-ih > * { max-width: 100%; }
.tl-insp .seg { display: flex; width: 100%; }
.tl-insp .seg button { flex: 1 1 0; padding: 6px 4px; font-size: 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tl-insp .input { width: 100%; }
.tl-insp .tl-row2 { flex-wrap: wrap; }
.tl-insp .tl-row2 .tl-num { flex: 1 1 52px; width: auto; }
.tl-insp .tl-row2 button { flex: none; }
.tl-insp .tl-knob { grid-template-columns: 48px minmax(0, 1fr) 44px; }
.tl-insp .lbl2 > span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tl-insp .tl-place { flex-wrap: wrap; }
.tl-insp .tl-col { flex: 1 1 120px; }
.tl-insp .tl-col .tl-row2 { flex-wrap: nowrap; }
.tl-insp .tl-col .tl-num { flex: 1 1 auto; width: 0; }

/* Durations on the timeline: the beat's own bar, and grab ends on bars. */
.tl-after { position: absolute; top: 0; bottom: -2000px; right: 0; background: rgba(0,0,0,.45); pointer-events: none; border-left: 1px dashed var(--line2); z-index: 1; }
.tl-tracks { overflow: hidden; }
.tl-bar2.beat { background: #1C1C1C; border-color: #3A3A3A; color: var(--text2); cursor: default; }
.tl-bar2 .tl-r, .tl-bar2 .tl-l { position: absolute; top: -1px; bottom: -1px; width: 7px; cursor: col-resize; background: rgba(255,255,255,.18); }
.tl-bar2 .tl-r { right: -1px; } .tl-bar2 .tl-l { left: -1px; }
.tl-bar2:hover .tl-r, .tl-bar2:hover .tl-l { background: rgba(255,255,255,.45); }
.tl-bar2.beat .tl-r { background: var(--accent); width: 6px; }
.tl-bar2 { position: absolute; }
.tl-beatname { gap: 6px !important; color: var(--text) !important; cursor: default !important; }
.tl-len { width: 52px !important; padding: 2px 5px !important; font: 400 11px var(--mono) !important; text-align: right; }

/* What the inspector edits: the words or a part, a tap away. */
.tl-choose { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 10px; }
.tl-choose button { padding: 5px 8px; font-size: 10.5px; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tl-choose button b { color: var(--accent); }
.tl-choose button.on { border-color: var(--accent); color: var(--accent); }
.tl-choose .tl-addparts { margin-left: auto; color: var(--text2); }

/* Scrubbable numbers: drag the label, or the field before typing in it. */
.tl-scrub { cursor: ew-resize; user-select: none; }
input.tl-scrub:focus { cursor: text; user-select: text; }
span.tl-scrub:hover, b.tl-scrub:hover { color: var(--accent); }
''';

/// The editor's script: `timelineEditor(beat, screen, index, side)` returns
/// its element and fills the side column with the inspector;
/// `stopAnimator()` stops the one on the page. Uses the builder's `B`,
/// `escB`, `spec`, `save`, `draw` and `MOVES`.
const animatorJs = r'''
// ── The animator ────────────────────────────────────────────────────
// A port of what the renderer does for one Glass Layers beat. Keep it in
// step with packs/glass_layers.dart (beatScene, _lift) and stage.dart
// (_liftEntry), or the preview stops being the render.
function cubic(x1, y1, x2, y2) {
  const bx = (u) => 3 * x1 * u * (1 - u) ** 2 + 3 * x2 * u * u * (1 - u) + u ** 3;
  const by = (u) => 3 * y1 * u * (1 - u) ** 2 + 3 * y2 * u * u * (1 - u) + u ** 3;
  return (t) => {
    if (t <= 0) return 0; if (t >= 1) return 1;
    let lo = 0, hi = 1, u = t;
    for (let i = 0; i < 28; i++) { u = (lo + hi) / 2; if (bx(u) < t) lo = u; else hi = u; }
    return by(u);
  };
}
const EASE = {
  linear: (t) => t,
  inOutCubic: cubic(0.645, 0.045, 0.355, 1),   // Curves.easeInOutCubic, Ease.inOut
  easeInOut: cubic(0.42, 0, 0.58, 1),          // Curves.easeInOut
  arrive: cubic(0.3, 0.1, 0.1, 1),
  out: cubic(0.16, 1, 0.3, 1),
  pop: cubic(0.34, 1.56, 0.64, 1),
};
// Track.from(v).to(at, v, ease).hold(until), as in time.dart.
class Trk {
  constructor(v) { this.keys = [{ at: 0, v, e: EASE.inOutCubic }]; }
  to(at, v, e = EASE.inOutCubic) { this.keys.push({ at, v, e }); return this; }
  hold(at) { this.keys.push({ at, v: this.keys[this.keys.length - 1].v, e: EASE.linear }); return this; }
  at(t) {
    const k = this.keys;
    if (t <= k[0].at) return k[0].v;
    for (let i = 1; i < k.length; i++) {
      if (t <= k[i].at) { const a = k[i - 1], b = k[i], span = b.at - a.at; if (span <= 0) return b.v; return a.v + (b.v - a.v) * b.e((t - a.at) / span); }
    }
    return k[k.length - 1].v;
  }
}
const trk = (v) => new Trk(v);

// 4×4 matrices, row-major, as Matrix4 builds them.
const M = {
  id: () => [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]],
  mul(a, b) { const r = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]; for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) { let s = 0; for (let k = 0; k < 4; k++) s += a[i][k] * b[k][j]; r[i][j] = s; } return r; },
  T: (x, y, z) => [[1,0,0,x],[0,1,0,y],[0,0,1,z],[0,0,0,1]],
  S: (x, y, z) => [[x,0,0,0],[0,y,0,0],[0,0,z,0],[0,0,0,1]],
  RX(d) { const a = d * Math.PI / 180, c = Math.cos(a), s = Math.sin(a); return [[1,0,0,0],[0,c,-s,0],[0,s,c,0],[0,0,0,1]]; },
  RY(d) { const a = d * Math.PI / 180, c = Math.cos(a), s = Math.sin(a); return [[c,0,s,0],[0,1,0,0],[-s,0,c,0],[0,0,0,1]]; },
  RZ(d) { const a = d * Math.PI / 180, c = Math.cos(a), s = Math.sin(a); return [[c,-s,0,0],[s,c,0,0],[0,0,1,0],[0,0,0,1]]; },
  P(dist) { const m = M.id(); m[3][2] = 1 / dist; return m; },
  chain(...ms) { return ms.reduce((a, b) => M.mul(a, b)); },
  css(m) { const v = []; for (let j = 0; j < 4; j++) for (let i = 0; i < 4; i++) v.push(m[i][j]); return `matrix3d(${v.join(',')})`; },
};

// Stages and frames, as format.dart and _Frame.of lay them out.
const STAGES = { vertical: [360, 640], wide: [640, 360], square: [360, 360], portrait: [360, 450] };
const SAFE = { vertical: [0.06, 0.08, 0.12, 0.2], portrait: [0.06, 0.06, 0.06, 0.08] };
function layoutOf(format) {
  const [w, h] = STAGES[format] || STAGES.vertical, a = h / w;
  if (a > 1.5) return { w, h, zoom: 0.5, pan: [8, -70], align: [-1, 1], size: 80, width: 1 };
  if (a > 1.1) return { w, h, zoom: 0.4, pan: [40, -30], align: [-1, 1], size: 64, width: 1 };
  if (a > 0.8) return { w, h, zoom: 0.36, pan: [w * 0.2, 0], align: [-1, 0], size: 54, width: 0.5 };
  return { w, h, zoom: 0.36, pan: [w * 0.2, 6], align: [-0.85, 0.1], size: 66, width: 0.45 };
}
const SCREEN = [393, 852], DIST = 1100, SETTLE = 1500, RISE = 1500;
const HEIGHTS = { spread: [190, 170, 150, 160, 180, 140], fan: [150, 170, 190, 210, 230, 250], zoom: [240, 150, 130, 120, 110, 100], _: [220, 180, 145, 125, 110, 100] };
const SPREAD_AT = [[-118, -230], [128, 20], [-104, 260], [120, -210], [-125, 40], [110, 250]];
const moveOf = (beat) => (beat.move === 'sweep' || beat.move === 'scan' ? 'scan' : beat.move || 'lift');

// Part [k] of [count]: the move's plan, the part's own settings over it.
function partPlan(beat, k, count, dir) {
  const move = moveOf(beat), own = beat.parts[k] || {};
  const height = own.z ?? (HEIGHTS[move] || HEIGHTS._)[k];
  const start = SETTLE + (own.delay ?? (move === 'pop' ? 320 : 250) * k) + (move === 'tap' ? 450 : 0);
  const pop = move === 'pop', end = start + (own.rise ?? RISE);
  const arrive = pop ? start + (own.rise ?? 650) : end, e = pop ? EASE.pop : EASE.inOutCubic;
  const side = k - (count - 1) / 2;
  const scanned = own.scan ?? (move === 'scan' && k === 0);
  let to = null, scale, turn = 0, roll = 0;
  if (move === 'spread') { to = [SPREAD_AT[k][0] * dir, SPREAD_AT[k][1]]; scale = 1.02; turn = (k % 2 === 0 ? 14 : -14) * dir; }
  else if (move === 'fan') { to = [78 * side * dir, 40 + 30 * Math.abs(side)]; scale = 1.04; roll = 8 * side * dir; }
  else if (move === 'zoom' && k === 0) { to = [0, -30]; scale = 1.38; }
  else if (pop) scale = k === 0 ? 1.08 : 1.04;
  else scale = scanned ? 1.45 : (k === 0 ? 1.06 : 1.03);
  const lands = Array.isArray(own.to) ? own.to : to;
  const up = (v) => trk(0).hold(start).to(arrive, v, e);
  return {
    start, end, height, scanned, lands,
    z: up(height),
    x: lands == null && !pop && k > 0 ? up(10 * dir * k) : trk(0),
    scale: trk(1).hold(start).to(arrive, own.scale ?? scale, e),
    tilt: up(own.tilt ?? 0), turn: up(own.turn ?? turn), roll: up(own.roll ?? roll),
    travel: lands == null ? trk(0) : trk(0).hold(start).to(end, 1, EASE.inOutCubic),
    defaults: { to, scale, turn, roll, height: (HEIGHTS[move] || HEIGHTS._)[k], delay: (pop ? 320 : 250) * k, rise: pop ? 650 : RISE, scan: move === 'scan' && k === 0 },
  };
}

// The beat's camera, as beatScene sets it.
function cameraOf(beat, f, dir, l) {
  const move = moveOf(beat), zoom = f.zoom * (beat.zoom || 1) * (move === 'spread' ? 0.86 : 1);
  const fr = Array.isArray(beat.framing) ? beat.framing : [0, 0];
  const pan = [f.pan[0] + fr[0], f.pan[1] + fr[1]];
  return {
    tilt: trk(15).to(SETTLE, 6, EASE.arrive).to(l, 9, EASE.linear),
    turn: move === 'orbit' ? trk(-34 * dir).to(l, 26 * dir, EASE.inOutCubic) : trk(-19 * dir).to(SETTLE, -7 * dir, EASE.arrive).to(l, -13 * dir, EASE.linear),
    roll: trk(-4 * dir).to(SETTLE, -2 * dir, EASE.arrive).to(l, -3 * dir, EASE.linear),
    zoom: trk(zoom * 0.9).to(SETTLE, zoom, EASE.arrive).to(l, zoom * 1.05, EASE.linear),
    panX: trk(pan[0]).hold(SETTLE).to(l, pan[0] + 6 * dir, EASE.linear),
    panY: trk(pan[1] + 24).to(SETTLE, pan[1], EASE.arrive).to(l, pan[1] - 6, EASE.linear),
  };
}

// ── The Timeline editor ─────────────────────────────────────────────
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
// One beat: the stage in the real frame, a track per part and one for the
// words, and an inspector in the side column for what is selected.
let BRAND = { ink: '#17181A', accent: '#FFD97A', paper: '#F1F1F3', fonts: {} };
fetch('/api/brand').then((r) => r.json()).then((b) => {
  BRAND = { ...BRAND, ...b, fonts: b.fonts || {} };
  const fam = BRAND.fonts.display;
  // The display face from Google Fonts by its family, when it is one there.
  if (fam && !document.getElementById('brandFont')) {
    const l = document.createElement('link'); l.id = 'brandFont'; l.rel = 'stylesheet';
    l.href = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(fam)}:wght@400..900&display=swap`;
    document.head.appendChild(l);
  }
}).catch(() => {});

const FRAMES = { vertical: ['9:16', 'Shorts · Reels · TikTok'], portrait: ['4:5', 'Feed'], square: ['1:1', 'Square'], wide: ['16:9', 'YouTube · site'] };
const STYLE_KEYS = ['color', 'accent', 'size', 'weight', 'reveal', 'plate', 'layer'];
const ed = { frame: null, safe: true, sel: 0, t: SETTLE + RISE + 600, playing: true, beat: -1 };
let animStop = null;
function stopAnimator() { if (animStop) animStop(); animStop = null; }

const hexMix = (a, b, t) => '#' + [1, 3, 5].map((i) => Math.round(parseInt(a.slice(i, i + 2), 16) * (1 - t) + parseInt(b.slice(i, i + 2), 16) * t).toString(16).padStart(2, '0')).join('');
const isDark = (hex) => { const v = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4)); return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2] < 0.4; };
const LIGHT_LOOKS = ['mesh', 'butter', 'studio'];
const POS_ALIGN = (pos) => [{ l: -1, c: 0, r: 1 }[pos[1]], { t: -1, m: 0, b: 1 }[pos[0]]];

// The words as they will render: the pack's own look, under the reel's,
// under the beat's; placed for [frame]. Keep in step with _beatWords in
// glass_layers.dart and _words in spec.dart.
function wordsOf(beat, frame) {
  const look = beat.look || spec.look, light = LIGHT_LOOKS.includes(look);
  const reel = spec.words || {}, own = beat.words || {};
  const pick = (k) => (own[k] ?? reel[k]);
  const accentDefault = look === 'butter' ? BRAND.paper : look === 'mesh' || look === 'studio' ? hexMix(BRAND.accent, BRAND.ink, 0.35) : BRAND.accent;
  const hasLift = beat.parts.length > 0, l = (beat.length || 5.6) * 1000;
  const place = (own.places || {})[frame] || null;
  return {
    color: pick('color') || (light ? BRAND.ink : BRAND.paper), accent: pick('accent') || accentDefault,
    size: pick('size') ?? null, weight: pick('weight') ?? null, reveal: pick('reveal') || 'letters',
    plate: pick('plate') || 'none', layer: pick('layer') || 'above',
    at: own.at ?? (hasLift ? 2 : 1.2), until: own.until ?? (l / 1000 - 1.1),
    place, light, scope: own.own ? 'beat' : 'reel',
  };
}
// Where a style edit goes: the beat's own, or the reel's.
function setStyle(beat, key, v) {
  const w = wordsOf(beat, ed.frame);
  if (w.scope === 'beat') { beat.words = beat.words || {}; beat.words[key] = v; }
  else { spec.words = spec.words || {}; spec.words[key] = v; }
  save();
}

// A number field that scrubs like a design tool's: drag its label (or the
// field, when it is not being typed in) sideways or up and down, or press
// the up and down arrows; Shift moves ten times as far, Alt a tenth.
// Each change fires `input`; letting go (or each arrow press) fires
// `change`.
function scrubbable(input, step = 1, label = null) {
  if (!input) return;
  const places = String(step).includes('.') ? String(step).split('.')[1].length : 0;
  const fire = (type) => input.dispatchEvent(new Event(type, { bubbles: true }));
  const set = (v) => { input.value = (Math.round(v / step) * step).toFixed(places); fire('input'); };
  input.addEventListener('keydown', (e) => {
    if (e.key !== 'ArrowUp' && e.key !== 'ArrowDown') return;
    e.preventDefault();
    const by = (e.shiftKey ? 10 : e.altKey ? 0.1 : 1) * step * (e.key === 'ArrowUp' ? 1 : -1);
    set((parseFloat(input.value) || 0) + by); fire('change');
  });
  for (const handle of [label, input]) {
    if (!handle) continue;
    handle.classList.add('tl-scrub');
    handle.addEventListener('pointerdown', (e) => {
      if (handle === input && document.activeElement === input) return;
      e.preventDefault();
      const x0 = e.clientX, y0 = e.clientY, v0 = parseFloat(input.value) || 0;
      let moved = false;
      const mv = (ev) => {
        const d = (ev.clientX - x0) - (ev.clientY - y0);
        if (Math.abs(d) > 2) moved = true;
        if (moved) set(v0 + Math.round(d / 2) * step * (ev.shiftKey ? 10 : ev.altKey ? 0.1 : 1));
      };
      const up = () => {
        removeEventListener('pointermove', mv); removeEventListener('pointerup', up);
        if (moved) fire('change'); else if (handle === input) { input.focus(); input.select(); }
      };
      addEventListener('pointermove', mv); addEventListener('pointerup', up);
    });
  }
}

// A look's ground as the renderer builds it (backdropOf in
// glass_layers.dart), in the brand's colours: its gradient, its glows
// (still, where the renderer lets them drift) and its vignette.
function groundCss(look, w, h) {
  const { ink, accent, paper } = BRAND, W = '#FFFFFF', K = '#000000';
  const rgba = (hex, a) => `rgba(${parseInt(hex.slice(1, 3), 16)},${parseInt(hex.slice(3, 5), 16)},${parseInt(hex.slice(5, 7), 16)},${a})`;
  const glow = (c, a, x, y, r) => `radial-gradient(circle ${Math.round(r * Math.max(w, h))}px at ${(x + 1) * 50}% ${(y + 1) * 50}%, ${rgba(c, a)}, ${rgba(c, 0)})`;
  const vig = (v) => `radial-gradient(ellipse at center, rgba(0,0,0,0) 50%, rgba(0,0,0,${(v * 0.75).toFixed(2)}))`;
  const lin = (t, b) => `linear-gradient(180deg, ${t}, ${b})`;
  switch (look) {
    case 'mesh': return [vig(0.06), glow(W, 0.7, 0.2, 0.1, 0.35), glow('#C9BCFF', 0.55, -0.35, 0.85, 0.55), glow(hexMix(accent, '#FF8A65', 0.55), 0.55, 0.85, 0.05, 0.5), glow(accent, 0.9, -0.75, -0.55, 0.62), lin(hexMix(paper, W, 0.5), hexMix(paper, accent, 0.18))].join(',');
    case 'butter': return [vig(0.1), glow(W, 0.45, 0, -0.75, 0.55), lin(hexMix(accent, W, 0.12), hexMix(accent, '#E0A800', 0.35))].join(',');
    case 'studio': return [vig(0.14), glow(accent, 0.18, 0.6, 0.6, 0.45), glow(W, 0.9, 0, -0.7, 0.55), `linear-gradient(180deg, rgba(0,0,0,0) 62%, ${hexMix(paper, K, 0.09)} 62%)`, lin(hexMix(paper, W, 0.6), hexMix(paper, K, 0.04))].join(',');
    case 'grid': return [vig(0.5), glow(accent, 0.16, 0, 0.35, 0.55), lin(hexMix(ink, K, 0.45), hexMix(ink, K, 0.2))].join(',');
    case 'echo': return [vig(0.55), lin(hexMix(ink, W, 0.03), hexMix(ink, K, 0.55))].join(',');
    default: return [vig(0.4), glow(accent, 0.1, -0.7, 0.75, 0.45), glow(accent, 0.28, 0.4, -0.35, 0.55), lin(hexMix(ink, W, 0.03), hexMix(ink, K, 0.55))].join(',');
  }
}

function timelineEditor(beat, s, index, side, lead) {
  stopAnimator();
  if (ed.beat !== index) { ed.beat = index; ed.sel = beat.parts.length ? 0 : 'words'; ed.t = SETTLE + RISE + 600; ed.playing = true; }
  if (!ed.frame) ed.frame = spec.format || 'vertical';
  const dir = index % 2 === 0 ? 1 : -1, l = (beat.length || 5.6) * 1000;
  // The timeline runs a little past the beat, so its end can be dragged out.
  const TL = Math.ceil((Math.max(l, 4000) + 2000) / 1000) * 1000;
  const f = layoutOf(ed.frame);
  const look = beat.look || spec.look;
  const partOf = (p) => s.parts.find((x) => x.name === p.type && (x.text || null) === (p.text || null));
  const parts = beat.parts.slice(0, 6);
  if (typeof ed.sel === 'number' && ed.sel >= parts.length) ed.sel = parts.length ? 0 : 'words';
  const [sl, st, sr, sb] = SAFE[ed.frame] || [0.06, 0.06, 0.06, 0.06];
  const safe = { x: f.w * sl, y: f.h * st, w: f.w * (1 - sl - sr), h: f.h * (1 - st - sb) };

  const root = B(`<div class="tled">
    <div class="tl-bar">
      <select class="input tl-move" id="tlGround" aria-label="Ground" title="What the screens sit on">${LOOKS.map((g) => `<option value="${g.id}" ${look === g.id ? 'selected' : ''}>Ground · ${escB(g.name)}</option>`).join('')}</select>
      <label class="tl-own" title="Give this beat its own ground; the others keep the reel's"><input type="checkbox" id="tlGroundOwn" ${beat.look ? 'checked' : ''}> Beat</label><select class="input tl-move" id="tlMove" aria-label="Move" title="Where every part starts from; choosing one resets each part's own settings">${MOVES.map(([id, name]) => `<option value="${id}" ${(beat.move || 'lift') === id ? 'selected' : ''}>Move · ${name}</option>`).join('')}</select>
      <span style="flex:1"></span>
      <select class="input tl-frame-pick" id="tlFrame" aria-label="Frame" title="The frame to preview in; each keeps its own placement of the words">${Object.entries(FRAMES).map(([id, [r, where]]) => `<option value="${id}" ${ed.frame === id ? 'selected' : ''} title="${where}">${r}${id === spec.format ? ' ★' : ''}</option>`).join('')}</select>
      <button data-safe class="${ed.safe ? 'on' : ''}" title="Show the safe zone: what the platform's buttons and captions cover">Safe</button>
    </div>
    <div class="tl-stagebox"><div class="tl-frame"><div class="tl-stage"></div></div></div>
    <div class="tl-time">
      <div class="tl-names"><div class="tl-head"><button class="tl-play" aria-label="Play or pause">❚❚</button><b class="tl-tm">0.00s</b></div></div>
      <div class="tl-tracks"><div class="tl-ruler">${Array.from({ length: TL / 1000 }, (_, i) => `<span style="left:${(i * 1000 / TL) * 100}%">${i}s</span>`).join('')}<div class="tl-after" style="left:${(l / TL) * 100}%"></div></div><div class="tl-rows"></div><div class="tl-ph"></div></div>
    </div>
  </div>`);
  const stage = root.querySelector('.tl-stage'), frameEl = root.querySelector('.tl-frame'), box = root.querySelector('.tl-stagebox');
  stage.style.width = f.w + 'px'; stage.style.height = f.h + 'px'; stage.style.background = groundCss(look, f.w, f.h);

  // The screen, the holes its parts leave, the parts, the words, guides.
  const img = `/catalogue/${s.image}`;
  const scr = B(`<div class="tl-scr" style="width:${SCREEN[0]}px;height:${SCREEN[1]}px;background-image:url('${img}')"></div>`);
  stage.appendChild(scr);
  const els = parts.map((p, k) => {
    const sp = partOf(p), r = sp ? sp.rect : [0, 0, 0, 0];
    const hole = B(`<div class="tl-hole" style="left:${r[0]}px;top:${r[1]}px;width:${r[2]}px;height:${r[3]}px"></div>`);
    scr.appendChild(hole);
    const el = B(`<div class="tl-part" style="width:${r[2]}px;height:${r[3]}px;background-image:url('${img}');background-size:${SCREEN[0]}px ${SCREEN[1]}px;background-position:${-r[0]}px ${-r[1]}px"><div class="tl-sweep"></div><span class="tl-tag">${k + 1}</span></div>`);
    el.onpointerdown = (e) => dragPart(e, k);
    stage.appendChild(el);
    return { el, hole, rect: r, sweep: el.querySelector('.tl-sweep') };
  });
  const word = B('<div class="tl-word" tabindex="0" aria-label="The words: drag to place"></div>');
  word.onpointerdown = (e) => dragWords(e);
  stage.appendChild(word);
  stage.appendChild(B(`<div class="tl-safe" style="left:${safe.x}px;top:${safe.y}px;width:${safe.w}px;height:${safe.h}px"><span>safe zone</span></div>`));
  const gv = B('<div class="tl-gv"></div>'), gh = B('<div class="tl-gh"></div>'), warn = B('<div class="tl-warn"></div>');
  stage.append(gv, gh, warn);
  let k = 1, snap = { x: null, y: null }, wbox = { x: 0, y: 0, w: 0, h: 0 };

  function fit() {
    // As large as the space allows, with a hair of room round it.
    const W = box.clientWidth - 12, H = box.clientHeight - 12;
    k = Math.max(0.1, Math.min(W / f.w, H / f.h));
    stage.style.transform = `scale(${k})`;
    frameEl.style.width = f.w * k + 'px'; frameEl.style.height = f.h * k + 'px';
  }

  // The words, laid out as WordsPainter lays them out in the safe area.
  function layoutWords(w) {
    const fontBase = w.size == null ? f.size : (w.size * f.size) / 80;
    const width = w.place && w.place.width != null ? w.place.width / 100 : null;
    const maxW = safe.w * (width ?? f.width);
    const align = w.place ? POS_ALIGN(w.place.pos || 'bl') : f.align;
    const fam = BRAND.fonts.display ? `'${BRAND.fonts.display}', ` : '';
    Object.assign(word.style, {
      fontFamily: `${fam}var(--display), sans-serif`, fontWeight: w.weight ?? 800, color: w.color,
      letterSpacing: '-0.035em', lineHeight: 1.02, textAlign: align[0] < -0.3 ? 'left' : align[0] > 0.3 ? 'right' : 'center',
      textShadow: `0 0 24px ${w.light ? 'rgba(241,241,243,.35)' : 'rgba(23,24,26,.6)'}`,
      zIndex: w.layer === 'behind' ? 1 : 200,
    });
    // Plate behind: light behind dark words, dark behind light ones.
    const dark = isDark(w.color);
    word.style.background = w.plate === 'none' ? 'transparent' : w.plate === 'solid' ? (dark ? '#FFF8EC' : '#141414') : (dark ? 'rgba(255,248,236,.62)' : 'rgba(14,14,14,.55)');
    word.style.backdropFilter = w.plate === 'soft' ? 'blur(8px)' : 'none';
    // Sized as Words.fitted sizes them: on one line, shrunk to fit; or,
    // with a width, shrunk only if a single word is longer than a line.
    let size = fontBase;
    word.style.fontSize = size + 'px'; word.style.whiteSpace = 'nowrap'; word.style.width = 'auto'; word.style.padding = '0';
    const text = beat.word || '';
    word.innerHTML = width == null ? escB(text) : text.split(/\s+/).map((x) => `<span>${escB(x)}</span>`).join(' ');
    const widest = width == null ? word.scrollWidth : Math.max(0, ...[...word.querySelectorAll('span')].map((x) => x.offsetWidth));
    if (widest > maxW) { size = (size * maxW) / widest * 0.98; word.style.fontSize = size + 'px'; }
    word.innerHTML = escB(text);
    const plateOn = w.plate !== 'none', padX = plateOn ? size * 0.28 : 0;
    word.style.padding = plateOn ? `${size * 0.12}px ${padX}px ${size * 0.18}px` : '0';
    if (width != null && word.scrollWidth - 2 * padX > maxW + 0.5) {
      // Wrapped: as wide as its longest line, as TextPainter measures it.
      word.style.whiteSpace = 'normal'; word.style.width = maxW + 2 * padX + 'px';
      const range = document.createRange(); range.selectNodeContents(word);
      const lines = {};
      for (const r of range.getClientRects()) { const key = Math.round(r.top); lines[key] = [Math.min(lines[key]?.[0] ?? r.left, r.left), Math.max(lines[key]?.[1] ?? r.right, r.right)]; }
      const longest = Math.max(...Object.values(lines).map(([a2, b2]) => b2 - a2)) / k;
      if (isFinite(longest) && longest > 0) word.style.width = Math.ceil(longest) + 2 * padX + 1 + 'px';
    }
    const bw = word.offsetWidth, bh = word.offsetHeight;
    const off = w.place ? [(w.place.dx || 0) / 100 * f.w, (w.place.dy || 0) / 100 * f.h] : [0, 0];
    wbox = { x: safe.x + ((align[0] + 1) / 2) * (safe.w - bw) + off[0], y: safe.y + ((align[1] + 1) / 2) * (safe.h - bh) + off[1], w: bw, h: bh };
    word.style.left = wbox.x + 'px'; word.style.top = wbox.y + 'px';
    return size;
  }
  // The words revealed at the beat's time, as letters, words, typed or faded.
  function revealWords(w, t) {
    const at = w.at * 1000, until = w.until * 1000, text = beat.word || '';
    const n = text.length, p = clamp((t - at) / 900, 0, 1), leave = clamp((t - until) / 450, 0, 1);
    const accentAt = text.endsWith('.') ? n - 1 : n;
    let shown = text, op = t >= at && leave < 1 ? 1 - leave : 0, lift = 0;
    if (w.reveal === 'letters' || w.reveal === 'type') shown = text.slice(0, Math.ceil(n * (w.reveal === 'type' ? p : EASE.out(p))));
    if (w.reveal === 'words') { const ws = text.split(' '); shown = ws.slice(0, Math.ceil(ws.length * EASE.out(p))).join(' '); }
    if (w.reveal === 'fade') { op *= EASE.out(p); lift = (1 - EASE.out(p)) * 12; }
    if (w.reveal === 'letters' || w.reveal === 'words') lift = (1 - EASE.out(p)) * 18;
    word.innerHTML = escB(shown.slice(0, accentAt)) + (shown.length > accentAt ? `<i style="font-style:normal;color:${w.accent}">${escB(shown.slice(accentAt))}</i>` : '') + `<span style="visibility:hidden">${escB(text.slice(shown.length))}</span>`;
    const selected = ed.sel === 'words';
    word.style.opacity = selected && op === 0 ? 0.35 : op;
    word.style.translate = `0 ${lift}px`;
    word.classList.toggle('sel', selected);
  }

  const area = (a, b) => Math.max(0, Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x)) * Math.max(0, Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y));
  function partBoxes() {
    const fr = stage.getBoundingClientRect();
    return els.map((e) => { const r = e.el.getBoundingClientRect(); return { x: (r.left - fr.left) / k, y: (r.top - fr.top) / k, w: r.width / k, h: r.height / k }; });
  }

  function render() {
    const t = ed.t, cam = cameraOf(beat, f, dir, l);
    const pose = { tilt: cam.tilt.at(t), turn: cam.turn.at(t), roll: cam.roll.at(t), zoom: cam.zoom.at(t), panX: cam.panX.at(t), panY: cam.panY.at(t) };
    const has = parts.length > 0;
    const sz = has ? trk(0).hold(SETTLE).to(SETTLE + RISE, -80).at(t) : 0;
    const sop = has ? trk(1).hold(SETTLE).to(SETTLE + RISE, moveOf(beat) === 'zoom' ? 0.5 : 0.76).at(t) : 1;
    const base = M.chain(M.T(f.w / 2 + pose.panX, f.h / 2 + pose.panY, 0), M.P(DIST), M.RX(-pose.tilt), M.RY(pose.turn), M.RZ(pose.roll), M.S(pose.zoom, pose.zoom, pose.zoom), M.T(0, 0, -sz));
    const screenM = M.mul(base, M.T(-SCREEN[0] / 2, -SCREEN[1] / 2, 0));
    scr.style.transform = M.css(screenM); scr.style.opacity = sop;
    const order = [];
    els.forEach((x, i) => {
      const plan = partPlan(beat, i, parts.length, dir);
      const z = plan.z.at(t), trv = plan.travel.at(t), [rx, ry, rw, rh] = x.rect;
      const cx = rx + rw / 2, cy = ry + rh / 2;
      const shift = plan.lands ? [(SCREEN[0] / 2 + plan.lands[0] - cx) * trv, (SCREEN[1] / 2 + plan.lands[1] - cy) * trv] : [0, 0];
      const sc = plan.scale.at(t);
      x.el.style.transform = M.css(M.chain(screenM, M.T(cx + plan.x.at(t) + shift[0], cy + shift[1], -z), M.RX(-plan.tilt.at(t)), M.RY(plan.turn.at(t)), M.RZ(plan.roll.at(t)), M.S(sc, sc, 1), M.T(-rw / 2, -rh / 2, 0)));
      x.el.classList.toggle('sel', i === ed.sel);
      x.hole.style.opacity = z > 2 ? 1 : 0;
      const sw = plan.scanned ? clamp((t - plan.start - 600) / 1100, 0, 1) : 0;
      x.sweep.style.opacity = sw > 0 && sw < 1 ? 1 : 0; x.sweep.style.top = EASE.inOutCubic(sw) * 100 + '%';
      order.push([sz + z, i]);
    });
    order.sort((a, b) => a[0] - b[0]).forEach(([, i], j) => (els[i].el.style.zIndex = 3 + j));
    scr.style.zIndex = 2;
    const w = wordsOf(beat, ed.frame);
    layoutWords(w); revealWords(w, t);
    gv.style.display = snap.x == null ? 'none' : 'block'; if (snap.x != null) gv.style.left = snap.x + 'px';
    gh.style.display = snap.y == null ? 'none' : 'block'; if (snap.y != null) gh.style.top = snap.y + 'px';
    root.querySelector('.tl-safe').style.display = ed.safe ? 'block' : 'none';
    // Words over a landed part: say so, and leave the call to the person.
    const hits = t > SETTLE + RISE && w.layer !== 'behind' && w.plate === 'none' && t >= w.at * 1000 && t <= w.until * 1000 ? partBoxes().map((pb, i) => (area(wbox, pb) > 150 ? i + 1 : 0)).filter(Boolean) : [];
    ed.overlap = hits;
    warn.style.display = hits.length ? 'block' : 'none'; warn.textContent = hits.length ? `⚠ The words cover part ${hits.join(', ')}` : '';
    const ow = side.querySelector('.tl-overlap');
    if (ow) { ow.hidden = !hits.length; ow.querySelector('span').textContent = hits.length ? `The words cover part ${hits.join(', ')}. Move them, give them a plate, or put them behind.` : ''; }
    // The timeline.
    root.querySelector('.tl-ph').style.left = (t / TL) * 100 + '%';
    root.querySelector('.tl-tm').textContent = (t / 1000).toFixed(2) + 's';
    root.querySelector('.tl-play').textContent = ed.playing ? '❚❚' : '▶';
    root.querySelectorAll('.tl-bar2[data-k]').forEach((b) => {
      if (b.dataset.k === 'beat') { b.style.left = '0%'; b.style.width = ((beat.length || 5.6) * 1000 / TL) * 100 + '%'; b.firstChild.textContent = `${(beat.length || 5.6).toFixed(1)}s`; }
      else if (b.dataset.k === 'words') { b.style.left = (w.at * 1000 / TL) * 100 + '%'; b.style.width = (((w.until - w.at) * 1000) / TL) * 100 + '%'; }
      else { const plan = partPlan(beat, +b.dataset.k, parts.length, dir); b.style.left = (plan.start / TL) * 100 + '%'; b.style.width = ((plan.end - plan.start) / TL) * 100 + '%'; }
    });
  }

  function rows() {
    const w = wordsOf(beat, ed.frame);
    root.querySelector('.tl-names').innerHTML = `<div class="tl-head"><button class="tl-play" aria-label="Play or pause">❚❚</button><b class="tl-tm">0.00s</b></div>`
      + `<div class="tl-name tl-beatname"><b>⏱</b>Beat<input class="input tl-len" id="tlLen" value="${(beat.length || 5.6).toFixed(1)}" aria-label="Beat length in seconds">s</div>`
      + `<div class="tl-name ${ed.sel === 'words' ? 'on' : ''}" data-sel="words"><b>T</b>Words · ${escB(beat.word || '—')}</div>`
      + parts.map((p, i) => `<div class="tl-name ${ed.sel === i ? 'on' : ''}" data-sel="${i}"><b>${i + 1}</b>${escB(p.type)}${p.text ? ' “' + escB(p.text) + '”' : ''}</div>`).join('');
    root.querySelector('.tl-rows').innerHTML = `<div class="tl-row tl-beatrow"><div class="tl-bar2 beat" data-k="beat" title="Drag the end to make the beat longer or shorter"><span></span><i class="tl-r"></i></div></div>`
      + `<div class="tl-row ${ed.sel === 'words' ? 'on' : ''}"><div class="tl-bar2 words" data-k="words" title="Drag to move; drag an end to change when they come in or go"><i class="tl-l"></i>${escB(w.reveal)} in<i class="tl-r"></i></div></div>`
      + parts.map((p, i) => { const plan = partPlan(beat, i, parts.length, dir); return `<div class="tl-row ${ed.sel === i ? 'on' : ''}"><div class="tl-bar2" data-k="${i}" title="Drag to move when it starts; drag its end to change how long it takes">rise${plan.scanned ? ' · scan' : ''}<i class="tl-r"></i></div></div>`; }).join('');
    root.querySelector('.tl-play').onclick = () => (ed.playing = !ed.playing);
    root.querySelectorAll('[data-sel]').forEach((d) => (d.onclick = () => select(d.dataset.sel === 'words' ? 'words' : +d.dataset.sel)));
    root.querySelectorAll('.tl-bar2').forEach((b) => (b.onpointerdown = (e) => dragBar(e, b.dataset.k, e.target.classList.contains('tl-r') ? 'end' : e.target.classList.contains('tl-l') ? 'start' : 'move')));
    const len = root.querySelector('#tlLen');
    len.onchange = () => { const v = parseFloat(len.value); if (!isNaN(v)) { beat.length = clamp(Math.round(v * 10) / 10, 2, 20); save(); draw(); } };
    // While scrubbing, the beat's bar follows; the editor redraws on release.
    len.oninput = () => { const v = parseFloat(len.value); if (!isNaN(v)) beat.length = clamp(Math.round(v * 10) / 10, 2, TL / 1000); };
    scrubbable(len, 0.1, len.previousSibling && len.parentElement.querySelector('b'));
  }
  function select(sel) { ed.sel = sel; rows(); inspector(); }

  // Dragging a part sets where it lands; the beat holds at that moment.
  function dragPart(e, i) {
    e.preventDefault(); select(i); ed.playing = false;
    const plan = partPlan(beat, i, parts.length, dir);
    ed.t = Math.max(ed.t, plan.end + 50);
    const [rx, ry, rw, rh] = els[i].rect;
    const from = plan.lands ? [...plan.lands] : [rx + rw / 2 - SCREEN[0] / 2, ry + rh / 2 - SCREEN[1] / 2];
    const x0 = e.clientX, y0 = e.clientY;
    const zoom = cameraOf(beat, f, dir, l).zoom.at(ed.t), depth = -80 + plan.height;
    const eff = k * zoom / Math.max(0.2, 1 - zoom * depth / DIST);
    const mv = (ev) => { beat.parts[i].to = [Math.round(from[0] + (ev.clientX - x0) / eff), Math.round(from[1] + (ev.clientY - y0) / eff)]; };
    const up = () => { removeEventListener('pointermove', mv); removeEventListener('pointerup', up); save(); inspector(); rows(); };
    addEventListener('pointermove', mv); addEventListener('pointerup', up);
  }
  // Dragging the words: offsets from their anchor, snapping to the safe
  // zone's edges and the frame's centre lines.
  function dragWords(e) {
    e.preventDefault(); select('words'); ed.playing = false;
    const w = wordsOf(beat, ed.frame);
    if (ed.t < w.at * 1000 + 900 || ed.t > w.until * 1000) ed.t = w.at * 1000 + 1000;
    const pl = placeFor(w), x0 = e.clientX, y0 = e.clientY, d0 = [pl.dx, pl.dy], b0 = { ...wbox };
    const mv = (ev) => {
      let nx = b0.x + (ev.clientX - x0) / k, ny = b0.y + (ev.clientY - y0) / k;
      const xs = [[safe.x, 0], [f.w / 2, 0.5], [safe.x + safe.w, 1]], ys = [[safe.y, 0], [f.h / 2, 0.5], [safe.y + safe.h, 1]];
      snap = { x: null, y: null };
      for (const [lx, a] of xs) if (Math.abs(nx + a * wbox.w - lx) < 7 / k + 3) { nx = lx - a * wbox.w; snap.x = lx; break; }
      for (const [ly, a] of ys) if (Math.abs(ny + a * wbox.h - ly) < 7 / k + 3) { ny = ly - a * wbox.h; snap.y = ly; break; }
      pl.dx = Math.round((d0[0] + ((nx - b0.x) / f.w) * 100) * 10) / 10; pl.dy = Math.round((d0[1] + ((ny - b0.y) / f.h) * 100) * 10) / 10;
    };
    const up = () => { removeEventListener('pointermove', mv); removeEventListener('pointerup', up); snap = { x: null, y: null }; save(); inspector(); };
    addEventListener('pointermove', mv); addEventListener('pointerup', up);
  }
  // This frame's placement, made from the pack's own if there is none yet.
  function placeFor(w) {
    beat.words = beat.words || {}; beat.words.places = beat.words.places || {};
    if (!beat.words.places[ed.frame]) {
      const [ax, ay] = f.align;
      const pos = (ay < -0.5 ? 't' : ay > 0.5 ? 'b' : 'm') + (ax < -0.5 ? 'l' : ax > 0.5 ? 'r' : 'c');
      beat.words.places[ed.frame] = { pos, dx: 0, dy: 0 };
    }
    return beat.words.places[ed.frame];
  }
  // Dragging a bar on the timeline: the middle moves it, an end resizes
  // it. The beat's own bar sets its length; a part's end, how long it
  // takes to rise; the words' ends, when they come in and go.
  function dragBar(e, key, how) {
    e.preventDefault();
    if (key !== 'beat') select(key === 'words' ? 'words' : +key);
    ed.playing = false;
    const x0 = e.clientX, w = root.querySelector('.tl-rows').getBoundingClientRect().width;
    const ms = (ev) => ((ev.clientX - x0) / w) * TL;
    let mv;
    if (key === 'beat') {
      const l0 = beat.length || 5.6;
      mv = (ev) => { beat.length = clamp(Math.round((l0 + ms(ev) / 1000) * 10) / 10, 2, TL / 1000); ed.t = Math.min(ed.t, beat.length * 1000); };
    } else if (key === 'words') {
      const cur = wordsOf(beat, ed.frame), a0 = cur.at, u0 = cur.until, end = (beat.length || 5.6);
      beat.words = beat.words || {};
      mv = (ev) => {
        const d = Math.round((ms(ev) / 1000) * 20) / 20;
        if (how === 'start') beat.words.at = clamp(a0 + d, 0, u0 - 0.3);
        else if (how === 'end') beat.words.until = clamp(u0 + d, a0 + 0.3, end);
        else { beat.words.at = clamp(a0 + d, 0, end - (u0 - a0)); beat.words.until = beat.words.at + (u0 - a0); }
        ed.t = how === 'end' ? beat.words.until * 1000 - 100 : beat.words.at * 1000 + 700;
      };
    } else {
      const i = +key, plan = partPlan(beat, i, parts.length, dir), d0 = plan.start - SETTLE - (moveOf(beat) === 'tap' ? 450 : 0), r0 = plan.end - plan.start;
      mv = how === 'end'
        ? (ev) => { beat.parts[i].rise = clamp(Math.round((r0 + ms(ev)) / 50) * 50, 300, 4000); ed.t = partPlan(beat, i, parts.length, dir).end; }
        : (ev) => { beat.parts[i].delay = clamp(Math.round((d0 + ms(ev)) / 50) * 50, 0, 2500); ed.t = partPlan(beat, i, parts.length, dir).start + 900; };
    }
    const up = () => { removeEventListener('pointermove', mv); removeEventListener('pointerup', up); save(); if (key === 'beat') draw(); else { inspector(); rows(); } };
    addEventListener('pointermove', mv); addEventListener('pointerup', up);
  }

  // ── The inspector, in the side column ──
  const PART_KEYS = ['to', 'z', 'scale', 'tilt', 'turn', 'roll', 'delay', 'rise', 'scan'];
  const knob = (id, label, min, max, step, value, fmt, set) => `<div class="tl-knob"><label for="${id}">${label}</label><input type="range" id="${id}" min="${min}" max="${max}" step="${step}" value="${value}" data-fmt="${fmt}"><output class="${set ? 'set' : ''}">${fmtv(fmt, value)}</output></div>`;
  const fmtv = (fmt, v) => ({ n: Math.round(v), x: (+v).toFixed(2) + '×', deg: Math.round(v) + '°', s: (v / 1000).toFixed(2) + 's', pc: Math.round(v) + '%' }[fmt]);
  // What the inspector can show: the words, and each part; with none
  // picked yet, the way to pick some.
  function chooser() {
    const bar = B(`<div class="tl-choose" role="tablist" aria-label="Edit"><button data-pick="words" class="${ed.sel === 'words' ? 'on' : ''}"><b>T</b> Words</button>${parts.map((p, i) => `<button data-pick="${i}" class="${ed.sel === i ? 'on' : ''}" title="${escB(p.type)}${p.text ? ' “' + escB(p.text) + '”' : ''}"><b>${i + 1}</b> ${escB(p.type.replace(/^_/, ''))}</button>`).join('')}<button class="tl-addparts" data-pickparts>${parts.length ? 'Pick parts' : '+ Pick parts'}</button></div>`);
    bar.querySelectorAll('[data-pick]').forEach((b) => (b.onclick = () => select(b.dataset.pick === 'words' ? 'words' : +b.dataset.pick)));
    bar.querySelector('[data-pickparts]').onclick = () => { partsMode[index] = 'pick'; draw(); };
    side.appendChild(bar);
  }
  function inspector() {
    side.innerHTML = '';
    chooser();
    if (ed.sel === 'words') return wordsInspector();
    if (!parts.length) { side.appendChild(B('<div class="ai"><b>No parts yet</b><span>Pick parts of the screen to lift, or style the words.</span></div>')); return; }
    const i = ed.sel, p = beat.parts[i], plan = partPlan(beat, i, parts.length, dir), d = plan.defaults;
    const own = (key) => p[key] !== undefined && p[key] !== null;
    const el = B(`<div class="tl-insp">
      <div class="tl-ih"><span class="lbl2">Part ${i + 1} of ${parts.length}</span><b>${escB(p.type)}</b>${p.text ? `<span class="mono2">“${escB(p.text)}”</span>` : ''}</div>
      <div class="tl-sec"><div class="lbl2"><span>Lands</span><span class="${own('to') ? 'set' : ''}">${plan.lands ? 'moved' : 'in place'}</span></div>
        <div class="tl-row2"><span class="lbl2">X</span><input class="input tl-num" id="pX" value="${plan.lands ? Math.round(plan.lands[0]) : 0}"><span class="lbl2">Y</span><input class="input tl-num" id="pY" value="${plan.lands ? Math.round(plan.lands[1]) : 0}"><button id="pIn">In place</button></div>
        <span class="hint" style="margin:0">From the screen's centre. Or drag the part on the preview.</span></div>
      <div class="tl-sec"><div class="lbl2">Depth</div>${knob('pz', 'Height', 0, 360, 5, p.z ?? plan.height, 'n', own('z'))}${knob('pscale', 'Size', 0.5, 2, 0.01, p.scale ?? d.scale, 'x', own('scale'))}</div>
      <div class="tl-sec"><div class="lbl2">Rotation</div>${knob('ptilt', 'Tilt', -45, 45, 1, p.tilt ?? 0, 'deg', own('tilt'))}${knob('pturn', 'Turn', -45, 45, 1, p.turn ?? d.turn, 'deg', own('turn'))}${knob('proll', 'Roll', -45, 45, 1, p.roll ?? d.roll, 'deg', own('roll'))}</div>
      <div class="tl-sec"><div class="lbl2">Timing</div>${knob('pdelay', 'Starts', 0, 2500, 50, p.delay ?? d.delay, 's', own('delay'))}${knob('prise', 'Rise', 300, 4000, 50, p.rise ?? d.rise, 's', own('rise'))}<span class="hint" style="margin:0">Starts after the screen settles; Rise is how long it takes. Or drag its bar, or the bar's end, on the timeline.</span></div>
      <div class="tl-sec"><div class="lbl2">Effects</div><label class="tl-chk"><input type="checkbox" id="pscan" ${plan.scanned ? 'checked' : ''}> A scan line reads it as it rises</label></div>
      <div class="tl-sec"><button id="pReset">Reset to ${escB((MOVES.find((m) => m[0] === (beat.move || 'lift')) || MOVES[0])[1])}</button></div>
    </div>`);
    side.appendChild(el);
    const map = { pz: 'z', pscale: 'scale', ptilt: 'tilt', pturn: 'turn', proll: 'roll', pdelay: 'delay', prise: 'rise' };
    Object.entries(map).forEach(([id, key]) => { const inp = el.querySelector('#' + id); inp.oninput = () => { p[key] = +inp.value; inp.nextElementSibling.textContent = fmtv(inp.dataset.fmt, +inp.value); inp.nextElementSibling.classList.add('set'); ed.playing = false; ed.t = Math.max(ed.t, partPlan(beat, i, parts.length, dir).end + 50); save(); }; inp.onchange = rows; });
    const xy = () => { const x = parseFloat(el.querySelector('#pX').value), y = parseFloat(el.querySelector('#pY').value); if (!isNaN(x) && !isNaN(y)) { p.to = [x, y]; save(); } };
    el.querySelector('#pX').oninput = xy; el.querySelector('#pY').oninput = xy;
    scrubbable(el.querySelector('#pX'), 1, el.querySelector('#pX').previousElementSibling);
    scrubbable(el.querySelector('#pY'), 1, el.querySelector('#pY').previousElementSibling);
    el.querySelector('#pIn').onclick = () => { delete p.to; save(); inspector(); };
    el.querySelector('#pscan').onchange = (e) => { p.scan = e.target.checked; save(); ed.t = SETTLE; ed.playing = true; rows(); };
    el.querySelector('#pReset').onclick = () => { PART_KEYS.forEach((key) => delete p[key]); save(); inspector(); rows(); };
  }
  function wordsInspector() {
    const w = wordsOf(beat, ed.frame), pl = w.place;
    const swatches = (key) => [BRAND.ink, BRAND.paper, BRAND.accent, '#FFFFFF', '#000000', '#FF6B00'].filter((c, j, a) => a.indexOf(c) === j)
      .map((c) => `<button class="tl-sw ${w[key].toLowerCase() === c.toLowerCase() ? 'on' : ''}" data-sw="${key}" data-v="${c}" style="background:${c}" aria-label="${key} ${c}" title="${c}"></button>`).join('')
      + `<input type="color" class="tl-cc" data-cc="${key}" value="${w[key]}" aria-label="Any ${key}">`;
    const align = pl ? POS_ALIGN(pl.pos || 'bl') : f.align;
    const curPos = (align[1] < -0.5 ? 't' : align[1] > 0.5 ? 'b' : 'm') + (align[0] < -0.5 ? 'l' : align[0] > 0.5 ? 'r' : 'c');
    const el = B(`<div class="tl-insp">
      <div class="tl-ih"><span class="lbl2">The words</span><b>${escB(beat.word || 'No words yet')}</b></div>
      <div class="tl-sec"><div class="lbl2">Applies to</div><div class="seg"><button data-scope="beat" class="${w.scope === 'beat' ? 'on' : ''}">This beat</button><button data-scope="reel" class="${w.scope === 'reel' ? 'on' : ''}">Every beat</button></div>
        <span class="hint" style="margin:0">${w.scope === 'reel' ? 'The look is set once for the reel. Placement and timing are always this beat’s own.' : 'This beat has its own look; the others keep the reel’s.'}</span></div>
      <div class="tl-sec"><div class="lbl2">Text</div><input class="input" id="wText" value="${escB(beat.word || '')}" placeholder="e.g. Share."></div>
      <div class="tl-sec"><div class="lbl2">Colour</div><div class="tl-sws">${swatches('color')}</div><div class="lbl2">Accent · the full stop</div><div class="tl-sws">${swatches('accent')}</div></div>
      <div class="tl-sec"><div class="lbl2">Type</div>${knob('wSize', 'Size', 30, 160, 1, w.size ?? 80, 'n', w.size != null)}
        <div class="seg">${[[500, 'Medium'], [700, 'Bold'], [800, 'Extra'], [900, 'Black']].map(([v, n]) => `<button data-wt="${v}" class="${(w.weight ?? 800) === v ? 'on' : ''}">${n}</button>`).join('')}</div></div>
      <div class="tl-sec"><div class="lbl2"><span>Place · ${FRAMES[ed.frame][0]}</span><span>${pl ? 'set by you' : 'the style’s own'}</span></div>
        <div class="tl-place"><div class="tl-grid">${['tl', 'tc', 'tr', 'ml', 'mc', 'mr', 'bl', 'bc', 'br'].map((q) => `<button data-pos="${q}" class="${curPos === q ? 'on' : ''}" aria-label="Anchor ${q}"></button>`).join('')}</div>
          <div class="tl-col"><div class="tl-row2"><span class="lbl2">X</span><input class="input tl-num" id="wDx" value="${pl ? pl.dx || 0 : 0}"><span class="lbl2">%</span></div><div class="tl-row2"><span class="lbl2">Y</span><input class="input tl-num" id="wDy" value="${pl ? pl.dy || 0 : 0}"><span class="lbl2">%</span></div></div></div>
        ${knob('wWidth', 'Width', 20, 100, 1, pl && pl.width != null ? pl.width : Math.round(f.width * 100), 'pc', pl && pl.width != null)}
        <span class="hint" style="margin:0">Or drag the words on the preview; they snap to the safe zone’s edges and the centre. With a width set they wrap at it; without, they shrink to one line.</span>${pl ? '<button id="wPlaceReset">Back to the style’s own place</button>' : ''}</div>
      <div class="tl-sec"><div class="lbl2">Layer</div><div class="tl-row2" style="flex-wrap:wrap"><div class="seg">${[['above', 'In front'], ['behind', 'Behind phone']].map(([v, n]) => `<button data-layer="${v}" class="${w.layer === v ? 'on' : ''}">${n}</button>`).join('')}</div>
        <div class="seg">${[['none', 'No plate'], ['soft', 'Soft'], ['solid', 'Solid']].map(([v, n]) => `<button data-plate="${v}" class="${w.plate === v ? 'on' : ''}">${n}</button>`).join('')}</div></div>
        <div class="tl-overlap" hidden><span></span><button id="wClear">Move clear</button></div></div>
      <div class="tl-sec"><div class="lbl2">Reveal</div><div class="seg">${[['letters', 'Letters'], ['words', 'Words'], ['type', 'Typed'], ['fade', 'Fade']].map(([v, n]) => `<button data-rev="${v}" class="${w.reveal === v ? 'on' : ''}">${n}</button>`).join('')}</div>
        <div class="tl-row2"><span class="lbl2">In</span><input class="input tl-num" id="wAt" value="${(+w.at).toFixed(2)}"><span class="lbl2">Out</span><input class="input tl-num" id="wUntil" value="${(+w.until).toFixed(2)}"><span class="lbl2">s</span></div></div>
    </div>`);
    side.appendChild(el);
    const redo = () => { inspector(); rows(); };
    el.querySelectorAll('[data-scope]').forEach((b) => (b.onclick = () => {
      beat.words = beat.words || {};
      if (b.dataset.scope === 'beat') { const cur = wordsOf(beat, ed.frame); STYLE_KEYS.forEach((key) => { if (cur[key] != null && (spec.words || {})[key] != null) beat.words[key] = cur[key]; }); beat.words.own = true; }
      else { STYLE_KEYS.forEach((key) => delete beat.words[key]); delete beat.words.own; }
      save(); redo();
    }));
    el.querySelector('#wText').oninput = (e) => { beat.word = e.target.value; save(); };
    el.querySelector('#wText').onchange = rows;
    el.querySelectorAll('[data-sw]').forEach((b) => (b.onclick = () => { setStyle(beat, b.dataset.sw, b.dataset.v); redo(); }));
    el.querySelectorAll('[data-cc]').forEach((i) => (i.oninput = () => setStyle(beat, i.dataset.cc, i.value)));
    const sz = el.querySelector('#wSize'); sz.oninput = () => { setStyle(beat, 'size', +sz.value); sz.nextElementSibling.textContent = sz.value; sz.nextElementSibling.classList.add('set'); };
    el.querySelectorAll('[data-wt]').forEach((b) => (b.onclick = () => { setStyle(beat, 'weight', +b.dataset.wt); redo(); }));
    el.querySelectorAll('[data-pos]').forEach((b) => (b.onclick = () => { const p2 = placeFor(w); Object.assign(p2, { pos: b.dataset.pos, dx: 0, dy: 0 }); save(); redo(); }));
    const dxy = () => { const p2 = placeFor(w), x = parseFloat(el.querySelector('#wDx').value), y = parseFloat(el.querySelector('#wDy').value); if (!isNaN(x)) p2.dx = x; if (!isNaN(y)) p2.dy = y; save(); };
    el.querySelector('#wDx').oninput = dxy; el.querySelector('#wDy').oninput = dxy;
    scrubbable(el.querySelector('#wDx'), 0.1, el.querySelector('#wDx').previousElementSibling);
    scrubbable(el.querySelector('#wDy'), 0.1, el.querySelector('#wDy').previousElementSibling);
    const wd = el.querySelector('#wWidth'); wd.oninput = () => { placeFor(w).width = +wd.value; wd.nextElementSibling.textContent = wd.value + '%'; wd.nextElementSibling.classList.add('set'); save(); };
    const pr = el.querySelector('#wPlaceReset'); if (pr) pr.onclick = () => { delete beat.words.places[ed.frame]; save(); redo(); };
    el.querySelectorAll('[data-layer]').forEach((b) => (b.onclick = () => { setStyle(beat, 'layer', b.dataset.layer); redo(); }));
    el.querySelectorAll('[data-plate]').forEach((b) => (b.onclick = () => { setStyle(beat, 'plate', b.dataset.plate); redo(); }));
    el.querySelectorAll('[data-rev]').forEach((b) => (b.onclick = () => { setStyle(beat, 'reveal', b.dataset.rev); ed.t = w.at * 1000 - 200; ed.playing = true; redo(); }));
    const times = () => { const a = parseFloat(el.querySelector('#wAt').value), u = parseFloat(el.querySelector('#wUntil').value); beat.words = beat.words || {}; if (!isNaN(a)) beat.words.at = a; if (!isNaN(u)) beat.words.until = u; save(); };
    el.querySelector('#wAt').oninput = times; el.querySelector('#wUntil').oninput = times;
    scrubbable(el.querySelector('#wAt'), 0.05, el.querySelector('#wAt').previousElementSibling);
    scrubbable(el.querySelector('#wUntil'), 0.05, el.querySelector('#wUntil').previousElementSibling);
    // "Move clear": the anchor where the words cover the least of the parts.
    el.querySelector('#wClear').onclick = () => {
      const pbs = partBoxes(), p2 = placeFor(w);
      let best = null;
      for (const q of ['bl', 'bc', 'br', 'tl', 'tc', 'tr', 'ml', 'mr', 'mc']) {
        const [ax, ay] = POS_ALIGN(q), b2 = { x: safe.x + ((ax + 1) / 2) * (safe.w - wbox.w), y: safe.y + ((ay + 1) / 2) * (safe.h - wbox.h), w: wbox.w, h: wbox.h };
        const cover = pbs.reduce((sum, pb) => sum + area(b2, pb), 0);
        if (!best || cover < best.cover - 1) best = { q, cover };
      }
      Object.assign(p2, { pos: best.q, dx: 0, dy: 0 }); save(); redo();
    };
  }

  // Wiring.
  // The ground: the reel's, or with "this beat" ticked, this beat's own.
  const groundPick = root.querySelector('#tlGround'), groundOwn = root.querySelector('#tlGroundOwn');
  groundPick.onchange = () => { if (groundOwn.checked) beat.look = groundPick.value; else { spec.look = groundPick.value; delete beat.look; } save(); draw(); };
  groundOwn.onchange = () => { if (groundOwn.checked) beat.look = groundPick.value; else delete beat.look; save(); draw(); };
  root.querySelector('#tlMove').onchange = (e) => { beat.move = e.target.value; beat.parts.forEach((p) => PART_KEYS.forEach((key) => delete p[key])); save(); ed.t = 0; ed.playing = true; rows(); inspector(); };
  // The beat picker and Pick/Animate lead the toolbar, so they take no row.
  if (lead) root.querySelector('.tl-bar').prepend(...lead);
  root.querySelector('#tlFrame').onchange = (e) => { ed.frame = e.target.value; draw(); };
  root.querySelector('[data-safe]').onclick = (e) => { ed.safe = !ed.safe; e.target.classList.toggle('on', ed.safe); };
  root.querySelector('.tl-ruler').onpointerdown = (e) => { const r = e.currentTarget.getBoundingClientRect(); ed.playing = false; ed.t = clamp(((e.clientX - r.left) / r.width) * TL, 0, l); };

  let raf = 0, alive = true, last = performance.now();
  function tick(now) {
    if (!alive) return;
    if (!root.isConnected) { alive = false; return; }
    if (ed.playing) { ed.t += now - last; if (ed.t > l) ed.t = 0; }
    last = now; render();
    raf = requestAnimationFrame(tick);
  }
  animStop = () => { alive = false; cancelAnimationFrame(raf); };
  rows(); inspector();
  requestAnimationFrame(() => { fit(); render(); raf = requestAnimationFrame(tick); });
  new ResizeObserver(() => fit()).observe(box);
  return root;
}
''';
