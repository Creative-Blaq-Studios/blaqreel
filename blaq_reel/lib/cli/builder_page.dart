/// The studio's builder: a reel made step by step — the brief, its screens,
/// the parts of them to feature, its story, its ground — and previewed.
/// Every change is saved to `app_reels/specs/<name>.json` as it is made.
/// Spliced into the studio page.
library;

/// The builder's styles.
const builderCss = r'''
.tabs { display: flex; gap: 0; border: 1px solid var(--line2); }
.tab { border: 0; border-right: 1px solid var(--line2); padding: 7px 14px; background: var(--deep); color: var(--text2); }
.tab:last-child { border-right: 0; }
.tab.on { background: var(--accent); color: #0A0A0A; }
body.building main, body.building footer { display: none; }
#build { display: none; grid-template-columns: 250px minmax(0, 1fr) 300px; min-height: 0; }
body.building #build { display: grid; }
#build nav, #build aside { overflow: auto; padding: 16px 14px; background: var(--deep); }
#build nav { border-right: 1px solid var(--line2); }
#build aside { border-left: 1px solid var(--line2); display: flex; flex-direction: column; gap: 14px; }
.canvas { overflow: auto; padding: 22px 26px 40px; min-width: 0; }
.canvas h1 { font-weight: 900; text-transform: uppercase; letter-spacing: -0.02em; font-size: 30px; margin: 0 0 6px; }
.canvas .why { color: var(--text2); margin: 0 0 20px; max-width: 70ch; }
.steps { display: grid; gap: 4px; margin-top: 12px; }
.step { all: unset; display: grid; grid-template-columns: 26px 1fr; gap: 8px; align-items: center; padding: 9px 10px;
  border: 1px solid var(--line2); background: var(--surface); cursor: pointer; font-weight: 600; }
.step .k { font: 600 11px var(--mono); color: var(--text2); }
.step.on { border-color: var(--accent); }
.step.on .k { color: var(--accent); }
.step.done .k { color: var(--ok); }
.step small { grid-column: 2; font: 400 11px var(--mono); color: var(--text2); font-weight: 400; }
.field { display: grid; gap: 6px; margin-bottom: 18px; }
.field > label, .field > span { font: 600 11px var(--mono); text-transform: uppercase; letter-spacing: .08em; color: var(--text2); }
.input, textarea.input, select.input { font: 400 14px var(--display); background: var(--surface); color: var(--text);
  border: 1px solid var(--line2); padding: 10px 12px; width: 100%; }
.input:focus { outline: none; border-color: var(--accent); }
textarea.input { min-height: 80px; resize: vertical; }
.cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 10px; }
.card { all: unset; display: grid; gap: 4px; align-content: start; padding: 12px; border: 1px solid var(--line2);
  background: var(--surface); cursor: pointer; }
.card:hover { border-color: var(--text2); }
.card.on { border-color: var(--accent); }
.card b { font-weight: 900; text-transform: uppercase; font-size: 15px; letter-spacing: -0.01em; }
.card span { color: var(--text2); font-size: 13px; }
.card .shape { font: 600 10px var(--mono); color: var(--accent); text-transform: uppercase; letter-spacing: .08em; }
.screens { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.scr { all: unset; cursor: pointer; display: grid; gap: 6px; padding: 8px; border: 1px solid var(--line2); background: var(--surface); position: relative; }
.scr:hover { border-color: var(--accent); }
.scr img { width: 100%; display: block; border: 1px solid var(--line2); }
.scr b { font-weight: 600; font-size: 13px; }
.scr .count { position: absolute; top: 12px; right: 12px; background: var(--accent); color: #0A0A0A; font: 600 11px var(--mono); padding: 2px 6px; }
.beats { display: grid; gap: 6px; }
.beat { display: grid; grid-template-columns: 22px 1fr auto; gap: 8px; align-items: center; padding: 8px; border: 1px solid var(--line2); background: var(--surface); }
.beat.on { border-color: var(--accent); }
.beat .n { font: 600 12px var(--mono); color: var(--accent); }
.beat .t { min-width: 0; cursor: pointer; }
.beat .t b { display: block; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.beat .t span { font: 400 11px var(--mono); color: var(--text2); }
.beat .ops { display: flex; gap: 2px; }
.beat .ops button { padding: 3px 7px; font-size: 11px; }
.picker { display: grid; grid-template-columns: minmax(0, 380px) minmax(0, 1fr); gap: 22px; align-items: start; }
.shot2 { position: relative; }
.shot2 img { width: 100%; display: block; border: 1px solid var(--line2); }
.pbox { position: absolute; border: 2px solid rgba(255,107,0,.5); background: rgba(255,107,0,.05); cursor: pointer; }
.pbox b { position: absolute; left: -2px; top: -2px; transform: translateY(-100%); background: var(--accent); color: #0A0A0A; font: 600 11px var(--mono); padding: 1px 5px; }
.pbox.on { border-color: var(--ok); background: rgba(34,197,94,.14); }
.pbox.on b { background: var(--ok); }
.plist { display: grid; gap: 6px; }
.prow { all: unset; display: grid; grid-template-columns: 36px minmax(0,1fr) 22px; gap: 8px; align-items: center; padding: 8px 10px;
  border: 1px solid var(--line2); background: var(--surface); cursor: pointer; }
.prow.on { border-color: var(--ok); }
.prow .n { font: 600 12px var(--mono); color: var(--accent); }
.prow.on .n { color: var(--ok); }
.prow b { font-weight: 600; font-size: 13px; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.prow span { color: var(--text2); font-size: 12px; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.prow .o { font: 600 11px var(--mono); color: var(--ok); }
.seg { display: inline-flex; border: 1px solid var(--line2); }
.seg button { border: 0; border-right: 1px solid var(--line2); }
.seg button:last-child { border-right: 0; }
.seg button.on { background: var(--accent); color: #0A0A0A; }
.story { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 12px; }
.sb { display: grid; gap: 8px; padding: 10px; border: 1px solid var(--line2); background: var(--surface); align-content: start; }
.sb img { width: 100%; display: block; border: 1px solid var(--line2); max-height: 260px; object-fit: cover; object-position: top; }
.sb .h { display: flex; justify-content: space-between; font: 600 11px var(--mono); color: var(--text2); }
.sb .h b { color: var(--accent); }
.styles { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; max-width: 920px; }
@media (max-width: 760px) { .styles { grid-template-columns: 1fr; } }
.card.style { gap: 6px; }
.clip { background: #000; border: 1px solid var(--line2); display: grid; place-items: center; overflow: hidden; }
.clip.tall { aspect-ratio: 9 / 16; max-height: 360px; }
.clip.wide { aspect-ratio: 16 / 9; }
.clip video { width: 100%; height: 100%; object-fit: contain; display: block; }
.clip span { font: 400 12px var(--mono); color: var(--muted); padding: 12px; text-align: center; }
.stylebar { margin-top: 12px; }
.beat { grid-template-columns: 26px minmax(0, 1fr) 26px; touch-action: none; }
.beat .grip { all: unset; cursor: grab; color: var(--text2); font-size: 16px; text-align: center; padding: 4px 0; }
.beat .grip:focus-visible { outline: 2px solid var(--accent); }
.beat .rm { all: unset; cursor: pointer; color: var(--muted); text-align: center; padding: 4px 0; }
.beat .rm:hover { color: var(--bad); }
.beat.dragging { opacity: .9; border-color: var(--accent); position: relative; z-index: 3; box-shadow: 0 10px 30px rgba(0,0,0,.6); cursor: grabbing; }
.beat.gap { margin-top: 46px; transition: margin .12s; }
.beats.gap-end { padding-bottom: 46px; }
.beat .t b .n { color: var(--accent); font: 600 12px var(--mono); margin-right: 4px; }
h2 span { color: var(--muted); }
.overlay { position: fixed; inset: 0; background: rgba(0,0,0,.72); z-index: 20; display: grid; place-items: center; padding: 24px; }
.overlay .panel { background: var(--deep); border: 1px solid var(--line2); width: min(980px, 100%); max-height: 88vh; display: grid; grid-template-rows: auto auto auto 1fr auto; gap: 12px; padding: 18px 20px; }
.ph { display: flex; justify-content: space-between; align-items: center; }
.ph .x { padding: 6px 10px; }
.plist2 { overflow: auto; border: 1px solid var(--line2); min-height: 200px; }
.irow { display: grid; grid-template-columns: 20px 64px minmax(0, 1fr) auto; gap: 12px; align-items: center; padding: 9px 12px; border-bottom: 1px solid var(--line); cursor: pointer; }
.irow:hover { background: var(--surface); }
.irow.staged { opacity: .55; cursor: default; }
.irow input { accent-color: var(--accent); width: 16px; height: 16px; }
.irow .ik { font: 600 10px var(--mono); text-transform: uppercase; letter-spacing: .08em; color: var(--accent); }
.irow .in b { display: block; font-weight: 600; }
.irow .in span { color: var(--text2); font-size: 13px; }
.irow .ir { font: 400 11px var(--mono); color: var(--muted); }
.irow .ir em { color: var(--ok); font-style: normal; }
.pfoot { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.looks2 { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
.lk { all: unset; cursor: pointer; display: grid; gap: 6px; padding: 8px; border: 1px solid var(--line2); background: var(--surface); }
.lk.on { border-color: var(--accent); }
.lk .sw { aspect-ratio: 9 / 14; border: 1px solid var(--line2); background-size: cover; background-position: center 30%; }
.lk b { font-weight: 900; text-transform: uppercase; font-size: 14px; }
.lk span { color: var(--text2); font-size: 12px; }
.sw-ink { background: radial-gradient(60% 45% at 70% 25%, rgba(255,217,122,.3), transparent), linear-gradient(#1d1e21, #0b0c0d); }
.sw-mesh { background: radial-gradient(55% 40% at 15% 20%, #FFD97A, transparent), radial-gradient(45% 40% at 95% 50%, #FFB08A, transparent), radial-gradient(55% 45% at 30% 95%, #CFC3FF, transparent), #F7F6F2; }
.sw-butter { background: radial-gradient(60% 35% at 50% 0%, rgba(255,255,255,.5), transparent), linear-gradient(#FFE08F, #EBB838); }
.sw-studio { background: radial-gradient(60% 35% at 50% 8%, #fff, transparent), linear-gradient(#F8F8F9 0%, #EFEFF1 55%, #E2E2E5 100%); }
.sw-grid { background: radial-gradient(50% 30% at 50% 70%, rgba(255,217,122,.18), transparent),
  repeating-linear-gradient(90deg, rgba(255,217,122,.18) 0 1px, transparent 1px 22px) bottom / 100% 40% no-repeat,
  repeating-linear-gradient(0deg, rgba(255,217,122,.18) 0 1px, transparent 1px 22px) bottom / 100% 40% no-repeat, #0a0a0b; }
.sw-echo { background: linear-gradient(#5c5c60, #333336); }
.ai { display: grid; gap: 8px; padding: 12px; border: 1px solid var(--accent); background: rgba(255,107,0,.06); }
.ai b { font-weight: 900; text-transform: uppercase; font-size: 14px; }
.ai span { color: var(--text2); font-size: 13px; }
.busy { opacity: .6; pointer-events: none; }
.hint { color: var(--text2); font-size: 13px; }
.row2 { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
@media (max-width: 1100px) { #build { grid-template-columns: 220px minmax(0, 1fr); } #build aside { display: none; } }
@media (max-width: 760px) { #build { grid-template-columns: 1fr; } .picker { grid-template-columns: 1fr; } }
''';

/// The builder's markup.
const builderHtml = r'''
<div id="build">
  <nav>
    <div class="field"><span>Reel</span>
      <select class="input" id="specPick"></select>
    </div>
    <button id="newSpec" style="width:100%">New reel</button>
    <div class="steps" id="steps"></div>
  </nav>
  <div class="canvas" id="canvas"></div>
  <aside id="side"></aside>
</div>
''';

/// The builder's script. Uses the studio's `$`, `toast`, `select` and
/// `refreshLibrary`.
const builderJs = r'''
const PACKS = [
  { id: 'glass', name: 'Glass Layers', shape: '9:16 · 10–30 s', blurb: 'The screens split into floating layers; one word per beat.' },
  { id: 'story', name: 'Story Ad', shape: '9:16 · 30–60 s', blurb: 'A hook, the problem, the app, its beats, proof, and a call to action.' },
  { id: 'kinetic', name: 'Kinetic Launch', shape: '16:9 · 15–30 s', blurb: 'A line per beat, word by word, the key part marked; the phone sweeps in.' },
  { id: 'glow', name: 'Dark Glow', shape: '16:9 · 20–40 s', blurb: 'One camera past glowing screens, a title and a line at each.' },
];
const LOOKS = [
  { id: 'mesh', name: 'Butter mesh', blurb: 'Light, soft drifting fields of the accent.' },
  { id: 'butter', name: 'Butter field', blurb: 'The brand colour as the ground.' },
  { id: 'studio', name: 'Studio', blurb: "A photo studio's pale sweep." },
  { id: 'grid', name: 'Grid floor', blurb: 'Dark, with a floor of lines in 3D.' },
  { id: 'ink', name: 'Ink glow', blurb: 'Dark ink with the accent glowing.' },
  { id: 'echo', name: 'Screen echo', blurb: 'The screen, huge and blurred behind.' },
];
const FORMATS = ['vertical', 'wide', 'square', 'portrait'];
const STEPS = [
  { id: 'screens', name: 'Screens', sub: 'which ones, in order' },
  { id: 'brief', name: 'Brief & style', sub: 'what it is for, how it looks' },
  { id: 'parts', name: 'Parts', sub: 'what each beat features' },
  { id: 'story', name: 'Story', sub: 'the words' },
  { id: 'ground', name: 'Ground', sub: 'what it sits on' },
  { id: 'preview', name: 'Preview', sub: 'watch it, then render' },
];

let styleClips = {}, styleKey = null, styleBusy = false;
let spec = null, step = 'screens', beatIndex = 0, catalogue = null, saving = null, groundShots = null;
const B = (html) => { const t = document.createElement('template'); t.innerHTML = html.trim(); return t.content.firstElementChild; };
const escB = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function blank(name) {
  return { name, pack: 'glass', format: 'vertical', look: 'mesh', music: null, open: 'mark', storyBy: 'words',
    brief: '', beats: [], end: { logo: 'wordmark', line: '' } };
}
function screenOf(id) { return catalogue && catalogue.screens.find((s) => s.id === id); }

// ── Tabs ────────────────────────────────────────────────────────────
function setTab(build) {
  document.body.classList.toggle('building', build);
  $('tabBuild').classList.toggle('on', build); $('tabLibrary').classList.toggle('on', !build);
  if (build) openBuilder();
}
$('tabLibrary').onclick = () => { setTab(false); history.replaceState(null, '', '#'); };
$('tabBuild').onclick = () => { setTab(true); history.replaceState(null, '', '#build'); };
// #build opens the studio on the builder; #build-<step> on a step of it.
if (location.hash.startsWith('#build')) {
  const s = location.hash.slice(7).replace(/-add$/, '');
  if (STEPS.some((x) => x.id === s)) step = s;
  setTimeout(() => setTab(true), 0);
  // #build-screens-add opens the picker too.
  if (location.hash.endsWith('-add')) setTimeout(() => openPicker(), 600);
}

async function openBuilder() {
  if (!catalogue) catalogue = await fetch('/api/catalogue').then((r) => r.json());
  try { styleClips = (await fetch('/api/styles').then((r) => r.json())).clips || {}; } catch {}
  const specs = await fetch('/api/specs').then((r) => r.json());
  const pick = $('specPick');
  pick.innerHTML = specs.length ? specs.map((s) => `<option value="${escB(s.name)}">${escB(s.name)}</option>`).join('') : '<option value="">No reels yet</option>';
  if (!spec && specs.length) { spec = { ...blank(specs[0].name), ...specs[0].spec, name: specs[0].name }; }
  if (spec) pick.value = spec.name;
  if (!spec) { newSpec(); return; }
  draw();
}
$('specPick').onchange = async (e) => {
  const name = e.target.value; if (!name) return;
  const s = await fetch('/api/spec?name=' + encodeURIComponent(name)).then((r) => r.json());
  spec = { ...blank(name), ...s, name }; step = 'screens'; beatIndex = 0; groundShots = null; draw();
};
$('newSpec').onclick = () => newSpec();
function newSpec() {
  let n = 1; const taken = [...$('specPick').options].map((o) => o.value);
  while (taken.includes('reel-' + n)) n++;
  spec = blank('reel-' + n); step = 'screens'; beatIndex = 0; groundShots = null;
  const o = document.createElement('option'); o.value = spec.name; o.textContent = spec.name; $('specPick').appendChild(o); $('specPick').value = spec.name;
  save(); draw();
}

// ── Saving ──────────────────────────────────────────────────────────
function save() {
  clearTimeout(saving);
  saving = setTimeout(async () => {
    const body = { ...spec }; delete body.name;
    const r = await fetch('/api/spec?name=' + encodeURIComponent(spec.name), { method: 'PUT', body: JSON.stringify(body) });
    if (!r.ok) toast('Could not save: ' + (await r.text()));
  }, 500);
}
function change(fn) { fn(); save(); draw(); }

// ── Steps ───────────────────────────────────────────────────────────
function done(id) {
  if (!spec) return false;
  return { brief: !!spec.pack, screens: spec.beats.length > 0, parts: spec.beats.length > 0 && spec.beats.every((b) => b.parts.length),
    story: spec.beats.length > 0 && spec.beats.every((b) => (b.word || b.line)), ground: !!spec.look, preview: false }[id];
}
function draw() {
  $('steps').innerHTML = '';
  STEPS.forEach((s, i) => {
    const b = B(`<button class="step${s.id === step ? ' on' : ''}${done(s.id) ? ' done' : ''}"><span class="k">${done(s.id) ? '✓' : i + 1}</span>${s.name}<small>${s.sub}</small></button>`);
    b.onclick = () => { step = s.id; draw(); };
    $('steps').appendChild(b);
  });
  const c = $('canvas'), side = $('side'); c.innerHTML = ''; side.innerHTML = '';
  ({ brief: drawBrief, screens: drawScreens, parts: drawParts, story: drawStory, ground: drawGround, preview: drawPreview })[step](c, side);
}
function next(label = 'Next') {
  const i = STEPS.findIndex((s) => s.id === step);
  const b = B(`<button class="primary" style="margin-top:22px">${label} →</button>`);
  b.onclick = () => { step = STEPS[Math.min(i + 1, STEPS.length - 1)].id; draw(); };
  return b;
}
function beatList(side, opts = {}) {
  side.appendChild(B('<h2>Beats <span>drag to reorder</span></h2>'));
  if (!spec.beats.length) { side.appendChild(B('<div class="hint">No beats yet. Pick screens to add them.</div>')); return; }
  const list = B('<div class="beats"></div>');
  spec.beats.forEach((b, i) => {
    const s = screenOf(b.screen);
    const el = B(`<div class="beat${opts.select && i === beatIndex ? ' on' : ''}" data-i="${i}"><button class="grip" title="Drag to reorder (or use the arrow keys)" aria-label="Move beat ${i + 1}">⠿</button>
      <div class="t"><b><span class="n">${i + 1}</span> ${escB(b.word || b.line || (s ? s.label : b.screen))}</b><span>${escB(s ? s.label : b.screen)} · ${b.parts.length} part${b.parts.length === 1 ? '' : 's'}</span></div>
      <button class="rm" title="Remove" aria-label="Remove beat ${i + 1}">✕</button></div>`);
    el.querySelector('.rm').onclick = () => change(() => { spec.beats.splice(i, 1); beatIndex = Math.max(0, Math.min(beatIndex, spec.beats.length - 1)); });
    el.querySelector('.t').onclick = () => { beatIndex = i; if (opts.select) draw(); else { step = 'parts'; draw(); } };
    const grip = el.querySelector('.grip');
    grip.onkeydown = (e) => {
      const to = e.key === 'ArrowUp' ? i - 1 : e.key === 'ArrowDown' ? i + 1 : -1;
      if (to < 0 || to >= spec.beats.length) return;
      e.preventDefault(); moveBeat(i, to);
      requestAnimationFrame(() => document.querySelector(`.beat[data-i="${to}"] .grip`)?.focus());
    };
    grip.onpointerdown = (e) => startDrag(e, el, list);
    list.appendChild(el);
  });
  side.appendChild(list);
}
function moveBeat(from, to) {
  change(() => {
    const [b] = spec.beats.splice(from, 1); spec.beats.splice(to, 0, b);
    if (beatIndex === from) beatIndex = to;
  });
}
// Drag a beat by its grip: it follows the pointer and the others make room;
// letting go puts it there.
function startDrag(e, el, list) {
  e.preventDefault();
  const from = +el.dataset.i;
  el.classList.add('dragging'); el.setPointerCapture(e.pointerId);
  const startY = e.clientY;
  const move = (ev) => {
    el.style.transform = `translateY(${ev.clientY - startY}px)`;
    const others = [...list.children].filter((x) => x !== el);
    let to = others.length;
    for (let k = 0; k < others.length; k++) {
      const r = others[k].getBoundingClientRect();
      if (ev.clientY < r.top + r.height / 2) { to = k; break; }
    }
    el.dataset.to = to;
    others.forEach((x, k) => x.classList.toggle('gap', k === to));
    list.classList.toggle('gap-end', to === others.length);
  };
  const up = () => {
    el.removeEventListener('pointermove', move); el.removeEventListener('pointerup', up); el.removeEventListener('pointercancel', up);
    const to = el.dataset.to === undefined ? from : +el.dataset.to;
    el.classList.remove('dragging'); el.style.transform = '';
    if (to !== from) moveBeat(from, to); else draw();
  };
  el.addEventListener('pointermove', move); el.addEventListener('pointerup', up); el.addEventListener('pointercancel', up);
}

// 1 ─ Brief
function drawBrief(c, side) {
  c.appendChild(B(`<div><h1>What is it for, and how should it look?</h1><p class="why">Watch each style on your screens and choose one. Then say what the reel should get across, and who writes the story: the AI, you, or both.</p></div>`));
  const name = B(`<div class="field"><label for="bName">Name (lowercase, for the file)</label><input class="input" id="bName" value="${escB(spec.name)}"></div>`);
  name.querySelector('input').onchange = (e) => {
    const v = e.target.value.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, '-');
    if (!v || v === spec.name) return;
    spec.name = v; const o = $('specPick').querySelector('option:checked'); if (o) { o.value = v; o.textContent = v; }
    save(); toast('Saved as ' + v);
  };
  c.appendChild(name);
  const key = JSON.stringify(spec.beats.slice(0, 2).map((b) => [b.screen, b.parts, b.word, b.line, b.move]) ) + spec.look;
  const packs = B('<div class="field"><span>Style</span><div class="styles"></div><div class="row2 stylebar"></div></div>');
  PACKS.forEach((p) => {
    const clip = styleClips[p.id];
    const wide = p.id === 'kinetic' || p.id === 'glow';
    const b = B(`<button class="card style${spec.pack === p.id ? ' on' : ''}"><div class="clip ${wide ? 'wide' : 'tall'}">${clip ? `<video src="${clip}" autoplay muted loop playsinline></video>` : `<span>${spec.beats.length ? 'Not rendered yet' : 'Pick screens to see it'}</span>`}</div><span class="shape">${p.shape}</span><b>${p.name}</b><span>${p.blurb}</span></button>`);
    b.onclick = () => change(() => { spec.pack = p.id; spec.format = wide ? 'wide' : 'vertical'; });
    packs.querySelector('.styles').appendChild(b);
  });
  const bar = packs.querySelector('.stylebar');
  if (!spec.beats.length) {
    const go = B('<button>Choose screens first</button>'); go.onclick = () => { step = 'screens'; draw(); }; bar.appendChild(go);
  } else {
    const stale = Object.keys(styleClips).length && styleKey !== null && styleKey !== key;
    const go = B(`<button class="${Object.keys(styleClips).length ? '' : 'primary'}">${styleBusy ? 'Rendering the styles… about a minute and a half' : Object.keys(styleClips).length ? (stale ? 'Your screens changed: preview again' : 'Preview again') : 'Preview every style on your screens'}</button>`);
    if (styleBusy) go.classList.add('busy');
    go.onclick = async () => {
      styleBusy = true; draw();
      const r = await fetch('/api/styles', { method: 'POST', body: JSON.stringify(spec) }).then((x) => x.json()).catch(() => ({ ok: false }));
      styleBusy = false;
      if (r.ok) { styleClips = r.clips; styleKey = key; } else toast('The style previews failed; see the log');
      if (step === 'brief') draw();
    };
    bar.appendChild(go);
    bar.appendChild(B(`<span class="hint">Played on your first ${Math.min(2, spec.beats.length)} screen${spec.beats.length > 1 ? 's' : ''}, on ${escB((LOOKS.find((l) => l.id === spec.look) || {}).name || 'the chosen ground')}.</span>`));
  }
  c.appendChild(packs);
  const fmt = B('<div class="field"><span>Frame</span><div class="seg"></div></div>');
  FORMATS.forEach((f) => { const b = B(`<button class="${spec.format === f ? 'on' : ''}">${f}</button>`); b.onclick = () => change(() => (spec.format = f)); fmt.querySelector('.seg').appendChild(b); });
  c.appendChild(fmt);
  const brief = B(`<div class="field"><label for="bBrief">What should it get across, and to whom?</label><textarea class="input" id="bBrief" placeholder="e.g. For couples who share bills: Khumio makes shared money easy, without the awkward chats.">${escB(spec.brief)}</textarea></div>`);
  brief.querySelector('textarea').oninput = (e) => { spec.brief = e.target.value; save(); };
  c.appendChild(brief);
  const sound = B('<div class="field"><span>Sound</span><div class="seg"></div></div>');
  [['Placeholder pad', null], ['No music', 'none']].forEach(([label, v]) => { const b = B(`<button class="${spec.music === v ? 'on' : ''}">${label}</button>`); b.onclick = () => change(() => (spec.music = v)); sound.querySelector('.seg').appendChild(b); });
  c.appendChild(sound);
  const who = B('<div class="field"><span>Who writes the story?</span><div class="cards"></div></div>');
  [['all', 'The AI, all of it', 'It picks the screens, the parts and the words from your brief. You review and change anything.'],
   ['words', 'Me, then the AI', 'You pick the screens and parts; the AI drafts the words for you to edit.'],
   ['me', 'Me, all of it', 'You pick everything and write every word.']].forEach(([id, t, d]) => {
    const b = B(`<button class="card${spec.storyBy === id ? ' on' : ''}"><b>${t}</b><span>${d}</span></button>`);
    b.onclick = () => change(() => (spec.storyBy = id));
    who.querySelector('.cards').appendChild(b);
  });
  c.appendChild(who);
  if (spec.storyBy === 'all') {
    const go = B('<button class="primary" style="margin-top:6px">Let the AI build it →</button>');
    go.onclick = () => aiDraft(true, go);
    c.appendChild(go);
  } else c.appendChild(next());
  side.appendChild(B(`<div class="ai"><b>How this works</b><span>Six steps. Every change is saved to <code>app_reels/specs/${escB(spec.name)}.json</code>. Preview renders it with the app's real screens.</span></div>`));
}

// 2 ─ Screens
function drawScreens(c, side) {
  c.appendChild(B(`<div><h1>Which screens?</h1><p class="why">Start with what you want to show. Each screen you add becomes a beat, in the order you add them; add one twice to feature two moments of it. Next you'll see every style played on the first two.</p></div>`));
  const add = B('<div class="row2" style="margin-bottom:16px"><button class="primary">+ Add screens from the app</button><span class="hint">Every screen, sheet and dialog in the app, by name. Pick some and the AI stages them here.</span></div>');
  add.querySelector('button').onclick = () => openPicker();
  c.appendChild(add);
  const lazy = B('<div class="ai" style="margin-bottom:18px"><b>Not sure which?</b><span>Describe the reel and let the AI choose the screens, the parts and the words. You can change all of it after.</span><button>Let the AI choose →</button></div>');
  lazy.querySelector('button').onclick = () => change(() => { spec.storyBy = 'all'; step = 'brief'; });
  c.appendChild(lazy);
  if (!catalogue) { c.appendChild(B('<p class="hint">Drawing the app\'s screens… this takes a minute the first time.</p>')); setTimeout(async () => { catalogue = await fetch('/api/catalogue').then((r) => r.json()); if (step === 'screens') draw(); }, 5000); return; }
  const grid = B('<div class="screens"></div>');
  catalogue.screens.forEach((s) => {
    const used = spec.beats.filter((b) => b.screen === s.id).length;
    const b = B(`<button class="scr"><img src="/catalogue/${s.image}" alt="${escB(s.label)}" loading="lazy"><b>${escB(s.label)}</b>${used ? `<span class="count">×${used}</span>` : ''}</button>`);
    b.onclick = () => change(() => spec.beats.push({ screen: s.id, parts: [], word: '', line: '' }));
    grid.appendChild(b);
  });
  c.appendChild(grid);
  c.appendChild(next());
  beatList(side);
}

let inventory = null, staging = false, pickerKind = 'all', pickerSearch = '';
const picked = new Set();

async function openPicker() {
  document.getElementById('picker')?.remove();
  const ov = B(`<div id="picker" class="overlay" role="dialog" aria-label="Add screens"><div class="panel">
    <div class="ph"><h2 style="font-size:24px">Add screens from the app</h2><button class="x" aria-label="Close">✕</button></div>
    <p class="hint" id="pTaken"></p>
    <div class="row2"><input class="input" id="pSearch" placeholder="Search screens, sheets, dialogs, routes…" style="flex:1;min-width:200px"><div class="seg" id="pKinds"></div></div>
    <div class="plist2" id="pList"><p class="hint">Reading the inventory…</p></div>
    <div class="pfoot">
      <button class="primary" id="pGo" disabled>Generate previews</button>
      <span class="hint" id="pNote"></span>
      <span style="flex:1"></span>
      <input class="input" id="pFind" placeholder="Not here? Describe it: the sheet that confirms a payment" style="max-width:360px">
      <button id="pFindGo">Ask the AI to find it</button>
      <button id="pRescan" title="Read the whole app again">Read the app again</button>
    </div></div></div>`);
  document.body.appendChild(ov);
  const close = () => ov.remove();
  ov.querySelector('.x').onclick = close;
  ov.onclick = (e) => { if (e.target === ov) close(); };
  document.addEventListener('keydown', function esc(e) { if (e.key === 'Escape') { close(); document.removeEventListener('keydown', esc); } });
  const search = ov.querySelector('#pSearch'); search.value = pickerSearch;
  search.oninput = () => { pickerSearch = search.value; drawPicker(); };
  [['all', 'All'], ['screen', 'Screens'], ['sheet', 'Sheets'], ['dialog', 'Dialogs']].forEach(([k, label]) => {
    const b = B(`<button class="${pickerKind === k ? 'on' : ''}">${label}</button>`);
    b.onclick = () => { pickerKind = k; ov.querySelectorAll('#pKinds button').forEach((x) => x.classList.toggle('on', x === b)); drawPicker(); };
    ov.querySelector('#pKinds').appendChild(b);
  });
  ov.querySelector('#pGo').onclick = () => generate(ov);
  ov.querySelector('#pFindGo').onclick = async (e) => {
    const d = ov.querySelector('#pFind').value.trim(); if (!d) return toast('Describe what to look for');
    e.target.textContent = 'Claude is looking…'; e.target.classList.add('busy');
    const r = await fetch('/api/inventory/find', { method: 'POST', body: JSON.stringify({ description: d }) }).then((x) => x.json()).catch(() => null);
    e.target.textContent = 'Ask the AI to find it'; e.target.classList.remove('busy');
    if (!r) return toast('The search failed; see the log');
    inventory = r; (r.added || []).forEach((i) => picked.add(i.name));
    toast(r.added && r.added.length ? 'Found: ' + r.added.map((i) => i.name).join(', ') : 'Nothing matched that');
    drawPicker();
  };
  ov.querySelector('#pRescan').onclick = async (e) => {
    e.target.textContent = 'Claude is reading the app…'; e.target.classList.add('busy');
    inventory = await fetch('/api/inventory/scan', { method: 'POST' }).then((x) => x.json()).catch(() => inventory);
    e.target.textContent = 'Read the app again'; e.target.classList.remove('busy');
    drawPicker();
  };
  if (!inventory) inventory = await fetch('/api/inventory').then((r) => r.json());
  drawPicker();
  search.focus();
}

function drawPicker() {
  const ov = document.getElementById('picker'); if (!ov || !inventory) return;
  const list = ov.querySelector('#pList');
  ov.querySelector('#pTaken').textContent = inventory.taken
    ? `${inventory.items.length} places in the app, read ${new Date(inventory.taken).toLocaleString()}. Ones already in the studio are marked.`
    : 'No inventory yet: Read the app to list its screens, sheets and dialogs.';
  const q = pickerSearch.toLowerCase();
  const rows = inventory.items.filter((i) => (pickerKind === 'all' || i.kind === pickerKind) &&
    (!q || [i.name, i.description, i.route, i.file].some((v) => String(v || '').toLowerCase().includes(q))));
  list.innerHTML = rows.length ? '' : '<p class="hint">Nothing matches. Ask the AI to find it, below.</p>';
  rows.forEach((i) => {
    const on = picked.has(i.name);
    const row = B(`<label class="irow${i.staged ? ' staged' : ''}"><input type="checkbox" ${on ? 'checked' : ''} ${i.staged ? 'disabled' : ''}>
      <span class="ik">${escB(i.kind || 'screen')}</span>
      <span class="in"><b>${escB(i.name)}</b><span>${escB(i.description || '')}</span></span>
      <span class="ir">${i.staged ? '<em>In the studio</em>' : escB(i.route || '')}</span></label>`);
    row.querySelector('input').onchange = (e) => { if (e.target.checked) picked.add(i.name); else picked.delete(i.name); updateGo(); };
    list.appendChild(row);
  });
  updateGo();
}
function updateGo() {
  const ov = document.getElementById('picker'); if (!ov) return;
  const go = ov.querySelector('#pGo');
  go.disabled = !picked.size || staging;
  go.textContent = staging ? 'Generating previews…' : picked.size ? `Generate previews for ${picked.size}` : 'Generate previews';
  ov.querySelector('#pNote').textContent = staging ? 'Claude is staging them; a few minutes. You can close this.' : '';
}
async function generate(ov) {
  const items = inventory.items.filter((i) => picked.has(i.name) && !i.staged);
  if (!items.length) return;
  staging = true; updateGo();
  toast(`Claude is staging ${items.length} screen${items.length === 1 ? '' : 's'}; a few minutes`);
  const r = await fetch('/api/screens/stage', { method: 'POST', body: JSON.stringify({ items }) }).then((x) => x.json()).catch((e) => ({ ok: false, error: String(e) }));
  staging = false; picked.clear();
  if (r.ok) {
    catalogue = await fetch('/api/catalogue').then((x) => x.json());
    inventory = await fetch('/api/inventory').then((x) => x.json());
    toast('Previews ready: ' + (r.summary || '').split('\n')[0]);
  } else toast('Could not stage them: ' + (r.error || 'see the log'));
  drawPicker(); if (step === 'screens') draw();
}

// 3 ─ Parts
function drawParts(c, side) {
  if (!spec.beats.length) { c.appendChild(B('<div><h1>Parts</h1><p class="why">Add screens first.</p></div>')); return; }
  beatIndex = Math.min(beatIndex, spec.beats.length - 1);
  const beat = spec.beats[beatIndex], s = screenOf(beat.screen);
  c.appendChild(B(`<div><h1>Beat ${beatIndex + 1}: what does it feature?</h1><p class="why">Click the parts of <b>${escB(s ? s.label : beat.screen)}</b> to feature, in order: the first rises highest. One to three reads best. Pick what shows the beat's point.</p></div>`));
  if (!s) { c.appendChild(B('<p class="hint">That screen is not in the catalogue.</p>')); return; }
  const wrap = B('<div class="picker"><div class="shot2"></div><div><div class="plist"></div><div class="field" style="margin-top:16px"><span>Move</span><div class="seg"></div></div></div></div>');
  const shot = wrap.querySelector('.shot2'); shot.appendChild(B(`<img src="/catalogue/${s.image}" alt="${escB(s.label)}">`));
  const isOn = (p) => beat.parts.findIndex((x) => x.type === p.name && (x.text || null) === (p.text || null));
  s.parts.forEach((p, n) => {
    const [x, y, w, h] = p.rect, i = isOn(p);
    const box = B(`<div class="pbox${i >= 0 ? ' on' : ''}" style="left:${100 * x / s.width}%;top:${100 * y / s.height}%;width:${100 * w / s.width}%;height:${100 * h / s.height}%"><b>${n + 1}</b></div>`);
    const row = B(`<button class="prow${i >= 0 ? ' on' : ''}"><span class="n">#${n + 1}</span><span><b>${escB(p.name)}</b><span>${p.text ? '“' + escB(p.text) + '”' : ''}</span></span><span class="o">${i >= 0 ? i + 1 : ''}</span></button>`);
    const toggle = () => change(() => { const j = isOn(p); if (j >= 0) beat.parts.splice(j, 1); else beat.parts.push({ type: p.name, text: p.text || null }); });
    box.onclick = toggle; row.onclick = toggle;
    shot.appendChild(box); wrap.querySelector('.plist').appendChild(row);
  });
  [['lift', 'Lift'], ['sweep', 'Lift + scan line']].forEach(([id, label]) => {
    const b = B(`<button class="${(beat.move || 'lift') === id ? 'on' : ''}">${label}</button>`);
    b.onclick = () => change(() => (beat.move = id)); wrap.querySelector('.seg').appendChild(b);
  });
  // Typing into one of the screen's fields, if it has any.
  const fields = s.parts.filter((p) => /Editable|Field|Input|TextField/.test(p.name));
  if (fields.length) {
    const ty = B(`<div class="field" style="margin-top:16px"><span>Type into a field</span>
      <select class="input"><option value="">No typing</option>${fields.map((p, i) => `<option value="${i}">${escB(p.name)}${p.text ? ' “' + escB(p.text) + '”' : ''}</option>`).join('')}</select>
      <input class="input" placeholder="What is typed, e.g. 186" value="${escB(beat.type || '')}"></div>`);
    const [sel, input] = [ty.querySelector('select'), ty.querySelector('input')];
    const cur = beat.typeInto ? fields.findIndex((p) => p.name === beat.typeInto.type && (p.text || null) === (beat.typeInto.text || null)) : -1;
    sel.value = cur >= 0 ? String(cur) : (beat.type ? '0' : '');
    sel.onchange = () => change(() => { const p = fields[+sel.value]; beat.typeInto = sel.value === '' ? undefined : { type: p.name, text: p.text || null }; if (sel.value === '') beat.type = undefined; });
    input.oninput = () => { beat.type = input.value || undefined; if (input.value && !beat.typeInto) { const p = fields[+(sel.value || 0)]; beat.typeInto = { type: p.name, text: p.text || null }; } save(); };
    wrap.querySelector('.plist').parentElement.appendChild(ty);
  }
  c.appendChild(wrap);
  const nb = B('<div class="row2" style="margin-top:22px"></div>');
  if (beatIndex < spec.beats.length - 1) { const b = B('<button class="primary">Next beat →</button>'); b.onclick = () => { beatIndex++; draw(); }; nb.appendChild(b); }
  else { nb.appendChild(next('On to the story')); }
  c.appendChild(nb);
  beatList(side, { select: true });
}

// 4 ─ Story
function drawStory(c, side) {
  const p = spec.pack;
  c.appendChild(B(`<div><h1>The story</h1><p class="why">${p === 'kinetic' ? 'A short line per beat; put the key part in {braces}.' : p === 'glow' ? 'A title per beat, key part in {braces}, and a line under it.' : 'One word per beat, ending in a full stop: what the person does.'} Draft them with the AI, or write them.</p></div>`));
  if (p === 'story') {
    const extra = B(`<div class="sb" style="margin-bottom:14px"><div class="h"><b>Before the beats</b></div>
      <div class="field"><label>Hook: questions, one per line</label><textarea class="input" id="sHook"></textarea></div>
      <div class="field"><label>Problem: one line each</label><textarea class="input" id="sProblem"></textarea></div>
      <div class="field"><label>Meet line</label><input class="input" id="sMeet"></div>
      <div class="field"><label>Proof: true lines only</label><textarea class="input" id="sProof"></textarea></div></div>`);
    const bind = (id, key, list) => { const el = extra.querySelector('#' + id); el.value = list ? (spec[key] || []).join('\n') : (spec[key] || '');
      el.oninput = () => { spec[key] = list ? el.value.split('\n').map((x) => x.trim()).filter(Boolean) : el.value; save(); }; };
    bind('sHook', 'hook', true); bind('sProblem', 'problem', true); bind('sMeet', 'meetLine', false); bind('sProof', 'proof', true);
    c.appendChild(extra);
  }
  const grid = B('<div class="story"></div>');
  spec.beats.forEach((b, i) => {
    const s = screenOf(b.screen);
    const card = B(`<div class="sb"><div class="h"><b>Beat ${i + 1}</b><span>${escB(s ? s.label : b.screen)} · ${b.parts.length} part${b.parts.length === 1 ? '' : 's'}</span></div>
      ${s ? `<img src="/catalogue/${s.image}" alt="">` : ''}
      ${p !== 'kinetic' ? `<input class="input" data-k="word" placeholder="${p === 'glow' ? 'Title, e.g. Shared {money}' : 'Word, e.g. Share.'}" value="${escB(b.word)}">` : ''}
      ${p === 'kinetic' || p === 'glow' ? `<input class="input" data-k="line" placeholder="${p === 'kinetic' ? 'Line, e.g. Split the {bill}.' : 'A line under it'}" value="${escB(b.line)}">` : ''}
      <div class="row2"><label class="hint" for="len${i}">Seconds</label><input class="input" style="width:80px" type="number" step="0.2" min="2" max="10" id="len${i}" data-k="length" value="${b.length ?? ''}" placeholder="5.6"></div></div>`);
    card.querySelectorAll('input').forEach((el) => (el.oninput = () => { const k = el.dataset.k; b[k] = k === 'length' ? (el.value ? +el.value : undefined) : el.value; save(); }));
    grid.appendChild(card);
  });
  c.appendChild(grid);
  const end = B(`<div class="sb" style="margin-top:14px;max-width:520px"><div class="h"><b>End card</b></div>
    <input class="input" id="eLine" placeholder="A closing line" value="${escB(spec.end?.line)}">
    <input class="input" id="eUrl" placeholder="An address (optional)" value="${escB(spec.end?.url || '')}"></div>`);
  end.querySelector('#eLine').oninput = (e) => { spec.end = { ...(spec.end || {}), line: e.target.value }; save(); };
  end.querySelector('#eUrl').oninput = (e) => { spec.end = { ...(spec.end || {}), url: e.target.value || undefined }; save(); };
  c.appendChild(end);
  c.appendChild(next());
  const ai = B(`<div class="ai"><b>Draft with the AI</b><span>Claude Code writes the words from your brief, the app's own copy and the parts you chose. Nothing is claimed that the copy doesn't say. You can change every word.</span><button class="primary">Draft the words</button></div>`);
  ai.querySelector('button').onclick = (e) => aiDraft(false, e.target);
  side.appendChild(ai);
  beatList(side);
}

async function aiDraft(all, button) {
  if (!all && !spec.beats.length) return toast('Pick screens first, or let the AI build it all.');
  const label = button.textContent; button.textContent = 'Asking Claude… about a minute'; button.classList.add('busy');
  try {
    const r = await fetch('/api/ai', { method: 'POST', body: JSON.stringify({ spec, brief: spec.brief, all }) }).then((x) => x.json());
    if (!r.ok) { toast(r.error || 'The AI did not answer'); return; }
    const d = r.draft;
    change(() => {
      if (all && Array.isArray(d.beats)) {
        spec.beats = d.beats.filter((b) => screenOf(b.screen)).map((b) => ({ screen: b.screen, parts: (b.parts || []).map((p) => ({ type: p.type, text: p.text || null })), word: b.word || '', line: b.line || '' }));
      } else if (Array.isArray(d.beats)) {
        d.beats.forEach((b, i) => { if (spec.beats[i]) { spec.beats[i].word = b.word || spec.beats[i].word; spec.beats[i].line = b.line || spec.beats[i].line; } });
      }
      for (const k of ['hook', 'problem', 'proof']) if (Array.isArray(d[k]) && d[k].length) spec[k] = d[k];
      if (d.meetLine) spec.meetLine = d.meetLine;
      if (d.end && d.end.line) spec.end = { ...(spec.end || {}), line: d.end.line };
      step = all ? 'parts' : 'story';
    });
    toast(all ? 'Drafted: check the parts and words, change anything' : 'Words drafted');
  } catch (e) { toast('The AI draft failed: ' + e); }
  finally { button.textContent = label; button.classList.remove('busy'); }
}

// 5 ─ Ground
function drawGround(c, side) {
  c.appendChild(B(`<div><h1>What does it sit on?</h1><p class="why">Choose the ground for the whole reel. A beat can take its own (on the right). <b>Render on this reel</b> shows each ground on your own frames, which takes a couple of minutes.</p></div>`));
  const grid = B('<div class="looks2"></div>');
  LOOKS.forEach((l) => {
    const img = groundShots && groundShots[l.id];
    const b = B(`<button class="lk${spec.look === l.id ? ' on' : ''}"><div class="sw ${img ? '' : 'sw-' + l.id}" ${img ? `style="background-image:url('${img}')"` : ''}></div><b>${l.name}</b><span>${l.blurb}</span></button>`);
    b.onclick = () => change(() => (spec.look = l.id));
    grid.appendChild(b);
  });
  c.appendChild(grid);
  const row = B('<div class="row2" style="margin-top:18px"></div>');
  const render = B('<button>Render on this reel</button>');
  render.onclick = async () => {
    if (!spec.beats.length) return toast('Add a beat first');
    render.textContent = 'Rendering the grounds…'; render.classList.add('busy');
    const at = spec.open ? 4.4 : 2.6;
    const r = await fetch(`/api/looks?name=${encodeURIComponent(spec.name)}&format=${spec.format}&at=${at}&looks=${LOOKS.map((l) => l.id).join(',')}`, { method: 'POST' }).then((x) => x.json());
    render.textContent = 'Render on this reel'; render.classList.remove('busy');
    if (!r.ok) return toast('Could not render the grounds; see the log');
    groundShots = Object.fromEntries(LOOKS.map((l) => [l.id, `/looks/${spec.name}/${l.id}.png?v=${Date.now()}`]));
    draw();
  };
  row.appendChild(render); row.appendChild(next());
  c.appendChild(row);
  side.appendChild(B('<h2>A beat of its own</h2>'));
  spec.beats.forEach((b, i) => {
    const s = screenOf(b.screen);
    const f = B(`<div class="field"><label>${i + 1}. ${escB(b.word || b.line || (s ? s.label : b.screen))}</label><select class="input"><option value="">Same as the reel</option>${LOOKS.map((l) => `<option value="${l.id}"${b.look === l.id ? ' selected' : ''}>${l.name}</option>`).join('')}</select></div>`);
    f.querySelector('select').onchange = (e) => change(() => { b.look = e.target.value || undefined; });
    side.appendChild(f);
  });
}

// 6 ─ Preview
function drawPreview(c, side) {
  const missing = spec.beats.filter((b) => !b.parts.length).length;
  c.appendChild(B(`<div><h1>Preview it</h1><p class="why">${spec.beats.length} beat${spec.beats.length === 1 ? '' : 's'}, ${escB(PACKS.find((p) => p.id === spec.pack).name)}, ${spec.format}, on ${escB((LOOKS.find((l) => l.id === spec.look) || {}).name || spec.look)}.${missing ? ` ${missing} beat${missing === 1 ? ' has' : 's have'} no parts chosen yet: ${missing === 1 ? 'it' : 'they'} will show the screen alone.` : ''} The preview renders in about a minute and opens in the player; change anything here and preview again.</p></div>`));
  const row = B('<div class="row2"></div>');
  const go = B('<button class="primary">Render the preview →</button>');
  go.onclick = async () => {
    await new Promise((r) => setTimeout(r, 600));
    await fetch(`/api/spec/preview?name=${encodeURIComponent(spec.name)}&format=${spec.format}`, { method: 'POST' });
    setTab(false); toast(`Rendering the preview of ${spec.name}…`);
    state = await fetch('/api/state').then((r) => r.json()); seenVersion = state.version; showLive(false);
  };
  row.appendChild(go);
  c.appendChild(row);
  c.appendChild(B(`<pre class="mono" style="margin-top:22px;font-size:12px;color:var(--text2);white-space:pre-wrap;border:1px solid var(--line2);padding:12px;background:var(--deep)">${escB(JSON.stringify((({ name, ...rest }) => rest)(spec), null, 2))}</pre>`));
  side.appendChild(B(`<div class="ai"><b>Where it lives</b><span><code>app_reels/specs/${escB(spec.name)}.json</code>. It renders like any reel: <code>dart run blaq_reel render ${escB(spec.name)}</code>, or Render final in the Library.</span></div>`));
}
''';
