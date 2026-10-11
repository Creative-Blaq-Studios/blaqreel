/// The builder's animator: one Glass Layers beat played in the page, live,
/// with the same camera, tracks, eases and per-part moves the renderer
/// uses (`packs/glass_layers.dart`, `stage.dart`), so what is set here is
/// what renders. Each part can be dragged to where it lands and given its
/// own height, size, turn, timing and scan line.
///
/// It draws from the catalogue's flat shot of the screen, so a part that
/// runs on past what the screen shows previews as what shows; the render
/// opens it out to all of it.
library;

/// The animator's styles.
const animatorCss = r'''
.anim { display: grid; grid-template-columns: minmax(0, 300px) minmax(0, 1fr); gap: 22px; align-items: start; margin-top: 26px; }
.anim .an-wrap { position: relative; overflow: hidden; border: 1px solid var(--line2); touch-action: none; user-select: none; }
.anim .an-wrap.an-dragging { cursor: grabbing; }
.anim .an-stage { position: absolute; left: 0; top: 0; transform-origin: 0 0; overflow: hidden; }
.anim .an-stage > * { position: absolute; left: 0; top: 0; transform-origin: 0 0; }
.anim .an-scr { background-size: 100% 100%; border-radius: 55px; box-shadow: 0 36px 70px rgba(0,0,0,.45); overflow: hidden; }
.anim .an-scr .an-hole { position: absolute; border-radius: 22px; opacity: 0; }
.anim .an-part { background-repeat: no-repeat; border-radius: 22px; box-shadow: 0 18px 40px rgba(0,0,0,.28); cursor: grab; overflow: hidden; }
.anim .an-part.an-sel { outline: 3px solid var(--accent); outline-offset: 3px; }
.anim .an-part .an-sweep { position: absolute; left: 0; right: 0; height: 3px; background: var(--accent); box-shadow: 0 0 14px 4px rgba(255,107,0,.5); opacity: 0; }
.anim .an-part .an-tag { position: absolute; left: 6px; top: 6px; background: var(--accent); color: #0A0A0A; font: 700 14px var(--mono); padding: 1px 6px; }
.anim .an-word { font-weight: 900; letter-spacing: -0.035em; line-height: .95; white-space: pre-wrap; transform: none !important; }
.anim .an-ctl { display: grid; gap: 12px; min-width: 0; }
.anim .an-bar { display: flex; gap: 8px; align-items: center; }
.anim .an-bar input[type=range] { flex: 1; min-width: 0; accent-color: var(--accent); }
.anim .an-bar .an-time { font: 400 12px var(--mono); color: var(--text2); width: 58px; text-align: right; }
.anim .an-chips { display: flex; flex-wrap: wrap; gap: 6px; }
.anim .an-chips button { padding: 6px 10px; font-size: 11px; }
.anim .an-chips button.on { border-color: var(--accent); color: var(--accent); }
.anim .an-chips button .an-own { color: var(--accent); margin-left: 4px; }
.anim .an-knobs { display: grid; grid-template-columns: 74px minmax(0, 1fr) 54px; gap: 8px 10px; align-items: center; border: 1px solid var(--line2); background: var(--surface); padding: 12px; }
.anim .an-knobs label { font: 600 11px var(--mono); text-transform: uppercase; letter-spacing: .06em; color: var(--text2); }
.anim .an-knobs input[type=range] { width: 100%; accent-color: var(--accent); }
.anim .an-knobs output { font: 400 12px var(--mono); color: var(--text); text-align: right; }
.anim .an-knobs .an-wide { grid-column: 2 / 4; display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.anim .an-knobs .an-head { grid-column: 1 / 4; display: flex; justify-content: space-between; gap: 8px; align-items: center; }
.anim .an-knobs .an-head b { font-weight: 600; overflow-wrap: anywhere; min-width: 0; flex: 1; }
.anim .an-knobs .an-set { color: var(--accent); }
@media (max-width: 1000px) { .anim { grid-template-columns: 1fr; } }
''';

/// The animator's script: `animator(beat, screen, index)` returns its
/// element; `stopAnimator()` stops the one on the page. Uses the builder's
/// `B`, `escB`, `spec`, `save`, `change` and `draw`.
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
  const end = start + RISE, pop = move === 'pop';
  const arrive = pop ? start + 650 : end, e = pop ? EASE.pop : EASE.inOutCubic;
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
    defaults: { to, scale, turn, roll, height: (HEIGHTS[move] || HEIGHTS._)[k], delay: (pop ? 320 : 250) * k, scan: move === 'scan' && k === 0 },
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

let animStop = null;
const animSel = {};   // the part chosen on each beat, by beat index
function stopAnimator() { if (animStop) animStop(); animStop = null; }

function animator(beat, s, index) {
  stopAnimator();
  const dir = index % 2 === 0 ? 1 : -1;
  const f = layoutOf(spec.format), l = (beat.length || 5.6) * 1000;
  const light = ['mesh', 'butter', 'studio'].includes(beat.look || spec.look);
  const ground = { mesh: 'linear-gradient(160deg,#FFF4D6,#FFD9A8 45%,#E9DDF5)', butter: 'linear-gradient(180deg,#FFE29A,#F2C34E)', studio: 'linear-gradient(180deg,#FAF8F3,#E9E6DF)', grid: 'linear-gradient(180deg,#0B0B0B,#151515)', ink: 'radial-gradient(circle at 70% 30%,#3A2E14,#0E0E0E 60%)', echo: 'linear-gradient(180deg,#111,#050505)' }[beat.look || spec.look] || '#111';
  const partOf = (p) => s.parts.find((x) => x.name === p.type && (x.text || null) === (p.text || null));
  const parts = beat.parts.slice(0, 6);
  let selected = Math.min(animSel[index] ?? 0, Math.max(parts.length - 1, 0));
  let t = SETTLE + RISE + 400, playing = parts.length > 0, last = performance.now();

  const root = B(`<div class="anim">
    <div><div class="an-wrap"><div class="an-stage"></div></div>
      <div class="an-bar" style="margin-top:8px"><button class="an-play">Pause</button><input type="range" class="an-scrub" min="0" max="${l}" step="10"><span class="an-time"></span></div>
      <p class="hint" style="margin:6px 0 0">Drag a part to where it should land. ${spec.pack === 'glass' || spec.pack === 'story' ? '' : 'Previewed as Glass Layers.'}</p></div>
    <div class="an-ctl"><div class="field" style="margin:0"><span>Each part</span><div class="an-chips"></div></div><div class="an-knobs"></div></div>
  </div>`);
  const wrap = root.querySelector('.an-wrap'), stage = root.querySelector('.an-stage');
  stage.style.width = f.w + 'px'; stage.style.height = f.h + 'px';
  stage.style.background = ground;
  const fit = () => { const k = wrap.clientWidth / f.w; stage.style.transform = `scale(${k})`; wrap.style.height = f.h * k + 'px'; return k; };

  if (!parts.length) {
    root.querySelector('.an-ctl').innerHTML = '<p class="hint">Pick parts above to animate them.</p>';
  }
  // The screen, its holes, and each part cut from the screen's own shot.
  const img = `/catalogue/${s.image}`;
  const scr = B(`<div class="an-scr" style="width:${SCREEN[0]}px;height:${SCREEN[1]}px;background-image:url('${img}')"></div>`);
  stage.appendChild(scr);
  const pageColor = '#F4F3EF';
  const els = parts.map((p, k) => {
    const sp = partOf(p);
    const r = sp ? sp.rect : [0, 0, 0, 0];
    const hole = B(`<div class="an-hole" style="left:${r[0]}px;top:${r[1]}px;width:${r[2]}px;height:${r[3]}px;background:${pageColor}"></div>`);
    scr.appendChild(hole);
    const el = B(`<div class="an-part" style="width:${r[2]}px;height:${r[3]}px;background-image:url('${img}');background-size:${SCREEN[0]}px ${SCREEN[1]}px;background-position:${-r[0]}px ${-r[1]}px"><div class="an-sweep"></div><span class="an-tag">${k + 1}</span></div>`);
    el.onpointerdown = (e) => startDrag(e, k);
    stage.appendChild(el);
    return { el, hole, rect: r, sweep: el.querySelector('.an-sweep') };
  });
  const [sl, st, sr, sb] = SAFE[spec.format] || [0.06, 0.06, 0.06, 0.06];
  const word = B(`<div class="an-word"></div>`);
  word.style.cssText += `;left:${f.w * sl}px;top:${f.h * st}px;width:${f.w * (1 - sl - sr)}px;height:${f.h * (1 - st - sb)}px;display:flex;font-size:${f.size}px;color:${light ? '#141414' : '#F5F5F5'};`;
  word.style.justifyContent = f.align[0] < -0.5 ? 'flex-start' : 'center';
  word.style.alignItems = f.align[1] > 0.5 ? 'flex-end' : f.align[1] < -0.5 ? 'flex-start' : 'center';
  word.textContent = beat.word || '';
  stage.appendChild(word);

  function render() {
    const cam = cameraOf(beat, f, dir, l);
    const pose = { tilt: cam.tilt.at(t), turn: cam.turn.at(t), roll: cam.roll.at(t), zoom: cam.zoom.at(t), panX: cam.panX.at(t), panY: cam.panY.at(t) };
    const has = parts.length > 0;
    const sz = has ? trk(0).hold(SETTLE).to(SETTLE + RISE, -80).at(t) : 0;
    const sop = has ? trk(1).hold(SETTLE).to(SETTLE + RISE, moveOf(beat) === 'zoom' ? 0.5 : 0.76).at(t) : 1;
    const base = M.chain(M.T(f.w / 2 + pose.panX, f.h / 2 + pose.panY, 0), M.P(DIST), M.RX(-pose.tilt), M.RY(pose.turn), M.RZ(pose.roll), M.S(pose.zoom, pose.zoom, pose.zoom), M.T(0, 0, -sz));
    const screenM = M.mul(base, M.T(-SCREEN[0] / 2, -SCREEN[1] / 2, 0));
    scr.style.transform = M.css(screenM); scr.style.opacity = sop; scr.style.zIndex = 1;
    const order = [];
    els.forEach((x, k) => {
      const plan = partPlan(beat, k, parts.length, dir);
      const z = plan.z.at(t), trv = plan.travel.at(t), [rx, ry, rw, rh] = x.rect;
      const cx = rx + rw / 2, cy = ry + rh / 2;
      const shift = plan.lands ? [(SCREEN[0] / 2 + plan.lands[0] - cx) * trv, (SCREEN[1] / 2 + plan.lands[1] - cy) * trv] : [0, 0];
      const sc = plan.scale.at(t);
      const m = M.chain(screenM, M.T(cx + plan.x.at(t) + shift[0], cy + shift[1], -z), M.RX(-plan.tilt.at(t)), M.RY(plan.turn.at(t)), M.RZ(plan.roll.at(t)), M.S(sc, sc, 1), M.T(-rw / 2, -rh / 2, 0));
      x.el.style.transform = M.css(m);
      x.el.classList.toggle('an-sel', k === selected);
      x.hole.style.opacity = z > 2 ? 1 : 0;
      const sw = plan.scanned ? Math.max(0, Math.min(1, (t - plan.start - 600) / 1100)) : 0;
      x.sweep.style.opacity = sw > 0 && sw < 1 ? 1 : 0;
      x.sweep.style.top = EASE.inOutCubic(sw) * 100 + '%';
      order.push([sz + z, k]);
    });
    order.sort((a, b) => a[0] - b[0]).forEach(([, k], i) => (els[k].el.style.zIndex = 2 + i));
    word.style.zIndex = 20;
    const wordAt = has ? 2000 : 1200;
    word.style.opacity = t >= wordAt && t <= l - 1100 ? Math.min(1, (t - wordAt) / 300) : 0;
    root.querySelector('.an-scrub').value = t;
    root.querySelector('.an-time').textContent = (t / 1000).toFixed(2) + 's';
  }

  let raf = 0, alive = true;
  function tick(now) {
    if (!alive) return;
    if (!root.isConnected) { alive = false; return; }
    if (playing) { t += now - last; if (t > l) t = 0; }
    last = now; render();
    raf = requestAnimationFrame(tick);
  }
  animStop = () => { alive = false; cancelAnimationFrame(raf); };
  const pl = root.querySelector('.an-play');
  const setPlaying = (v) => { playing = v; pl.textContent = v ? 'Pause' : 'Play'; };
  setPlaying(playing);
  pl.onclick = () => setPlaying(!playing);
  root.querySelector('.an-scrub').oninput = (e) => { setPlaying(false); t = +e.target.value; };

  // Dragging a part sets where it lands; the beat holds at that moment.
  let dispK = 1;
  function startDrag(e, k) {
    e.preventDefault(); select(k); setPlaying(false);
    const plan = partPlan(beat, k, parts.length, dir);
    t = Math.max(t, plan.end + 50);
    const [rx, ry, rw, rh] = els[k].rect;
    const from = plan.lands ? [...plan.lands] : [rx + rw / 2 - SCREEN[0] / 2, ry + rh / 2 - SCREEN[1] / 2];
    const x0 = e.clientX, y0 = e.clientY;
    const zoom = cameraOf(beat, f, dir, l).zoom.at(t), depth = -80 + plan.height;
    const eff = dispK * zoom / Math.max(0.2, 1 - zoom * depth / DIST);
    wrap.classList.add('an-dragging');
    const move = (ev) => {
      const p = beat.parts[k];
      p.to = [Math.round(from[0] + (ev.clientX - x0) / eff), Math.round(from[1] + (ev.clientY - y0) / eff)];
      knobs();
    };
    const up = () => { wrap.classList.remove('an-dragging'); window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); save(); chips(); };
    window.addEventListener('pointermove', move); window.addEventListener('pointerup', up);
  }
  function select(k) { selected = k; animSel[index] = k; chips(); knobs(); }

  const ownKeys = ['to', 'z', 'scale', 'tilt', 'turn', 'roll', 'delay', 'scan'];
  const hasOwn = (p) => ownKeys.some((key) => p[key] !== undefined && p[key] !== null);
  function chips() {
    const c = root.querySelector('.an-chips'); c.innerHTML = '';
    parts.forEach((p, k) => {
      const b = B(`<button class="${k === selected ? 'on' : ''}">${k + 1} · ${escB(p.type)}${hasOwn(p) ? '<span class="an-own" title="Has its own settings">●</span>' : ''}</button>`);
      b.onclick = () => select(k); c.appendChild(b);
    });
  }
  function knobs() {
    const box = root.querySelector('.an-knobs'); if (!parts.length) { box.remove(); return; }
    const p = beat.parts[selected], plan = partPlan(beat, selected, parts.length, dir), d = plan.defaults;
    const val = (k, fallback) => (p[k] ?? fallback);
    const row = (key, label, min, max, step, fallback, fmt) => `<label for="k-${key}">${label}</label><input type="range" id="k-${key}" data-k="${key}" min="${min}" max="${max}" step="${step}" value="${val(key, fallback)}"><output class="${p[key] !== undefined && p[key] !== null ? 'an-set' : ''}">${fmt(val(key, fallback))}</output>`;
    const lands = plan.lands;
    box.innerHTML = `<div class="an-head"><b>Part ${selected + 1} · ${escB(p.type)}${p.text ? ' “' + escB(p.text) + '”' : ''}</b><button class="an-reset" title="Back to the move's own settings">Reset</button></div>
      <label>Lands</label><div class="an-wide"><span class="hint" style="margin:0">${lands ? `x ${Math.round(lands[0])}, y ${Math.round(lands[1])} from the screen's centre` : 'where it sat'}</span>${Array.isArray(p.to) ? '<button class="an-inplace">Rise in place</button>' : ''}</div>
      ${row('z', 'Height', 0, 360, 5, plan.height, (v) => Math.round(v))}
      ${row('scale', 'Size', 0.5, 2, 0.01, d.scale, (v) => (+v).toFixed(2) + '×')}
      ${row('tilt', 'Tilt', -45, 45, 1, 0, (v) => v + '°')}
      ${row('turn', 'Turn', -45, 45, 1, d.turn, (v) => Math.round(v) + '°')}
      ${row('roll', 'Roll', -45, 45, 1, d.roll, (v) => Math.round(v) + '°')}
      ${row('delay', 'Starts', 0, 2500, 50, d.delay, (v) => (v / 1000).toFixed(2) + 's')}
      <label for="k-scan">Scan</label><div class="an-wide"><label style="display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;font:400 13px var(--display);color:var(--text)"><input type="checkbox" id="k-scan" ${val('scan', d.scan) ? 'checked' : ''}> A scan line reads it as it rises</label></div>`;
    box.querySelectorAll('input[type=range]').forEach((el) => {
      el.oninput = () => { p[el.dataset.k] = +el.value; el.nextElementSibling.textContent = { z: (v) => Math.round(v), scale: (v) => (+v).toFixed(2) + '×', tilt: (v) => v + '°', turn: (v) => v + '°', roll: (v) => v + '°', delay: (v) => (v / 1000).toFixed(2) + 's' }[el.dataset.k](+el.value); el.nextElementSibling.classList.add('an-set'); if (el.dataset.k === 'delay' || el.dataset.k === 'z') { setPlaying(false); t = Math.max(t, partPlan(beat, selected, parts.length, dir).end + 50); } save(); };
      el.onchange = () => chips();
    });
    box.querySelector('#k-scan').onchange = (e) => { p.scan = e.target.checked; save(); chips(); setPlaying(true); t = 0; };
    const ip = box.querySelector('.an-inplace'); if (ip) ip.onclick = () => { delete p.to; save(); knobs(); chips(); };
    box.querySelector('.an-reset').onclick = () => { ownKeys.forEach((key) => delete p[key]); save(); knobs(); chips(); };
  }
  chips(); knobs();
  requestAnimationFrame(() => { dispK = fit(); render(); raf = requestAnimationFrame(tick); });
  new ResizeObserver(() => { dispK = fit(); }).observe(wrap);
  return root;
}
''';
