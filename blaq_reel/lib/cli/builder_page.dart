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
  { id: 'kinetic', name: 'Kinetic Launch', shape: '16:9 · 15–30 s', blurb: 'A line per beat, word by word, the key part marked; the phone sweeps in.' },
  { id: 'glow', name: 'Dark Glow', shape: '16:9 · 20–40 s', blurb: 'One camera past glowing screens, a title and a line at each.' },
  { id: 'story', name: 'Story Ad', shape: '9:16 · 30–60 s', blurb: 'A hook, the problem, the app, its beats, proof, and a call to action.' },
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
  { id: 'brief', name: 'Brief', sub: 'what it is for' },
  { id: 'screens', name: 'Screens', sub: 'which ones, in order' },
  { id: 'parts', name: 'Parts', sub: 'what each beat features' },
  { id: 'story', name: 'Story', sub: 'the words' },
  { id: 'ground', name: 'Ground', sub: 'what it sits on' },
  { id: 'preview', name: 'Preview', sub: 'watch it, then render' },
];

let spec = null, step = 'brief', beatIndex = 0, catalogue = null, saving = null, groundShots = null;
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
  const s = location.hash.slice(7);
  if (STEPS.some((x) => x.id === s)) step = s;
  setTimeout(() => setTab(true), 0);
}

async function openBuilder() {
  if (!catalogue) catalogue = await fetch('/api/catalogue').then((r) => r.json());
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
  spec = { ...blank(name), ...s, name }; step = 'brief'; beatIndex = 0; groundShots = null; draw();
};
$('newSpec').onclick = () => newSpec();
function newSpec() {
  let n = 1; const taken = [...$('specPick').options].map((o) => o.value);
  while (taken.includes('reel-' + n)) n++;
  spec = blank('reel-' + n); step = 'brief'; beatIndex = 0; groundShots = null;
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
  side.appendChild(B('<h2>Beats</h2>'));
  if (!spec.beats.length) { side.appendChild(B('<div class="hint">No beats yet. Pick screens to add them.</div>')); return; }
  const list = B('<div class="beats"></div>');
  spec.beats.forEach((b, i) => {
    const s = screenOf(b.screen);
    const el = B(`<div class="beat${opts.select && i === beatIndex ? ' on' : ''}"><span class="n">${i + 1}</span>
      <div class="t"><b>${escB(b.word || b.line || (s ? s.label : b.screen))}</b><span>${escB(s ? s.label : b.screen)} · ${b.parts.length} part${b.parts.length === 1 ? '' : 's'}</span></div>
      <div class="ops"><button title="Earlier">↑</button><button title="Later">↓</button><button title="Remove">✕</button></div></div>`);
    const [up, down, rm] = el.querySelectorAll('.ops button');
    up.onclick = () => change(() => { if (i > 0) [spec.beats[i - 1], spec.beats[i]] = [spec.beats[i], spec.beats[i - 1]]; });
    down.onclick = () => change(() => { if (i < spec.beats.length - 1) [spec.beats[i + 1], spec.beats[i]] = [spec.beats[i], spec.beats[i + 1]]; });
    rm.onclick = () => change(() => { spec.beats.splice(i, 1); beatIndex = Math.max(0, Math.min(beatIndex, spec.beats.length - 1)); });
    el.querySelector('.t').onclick = () => { beatIndex = i; if (opts.select) draw(); else { step = 'parts'; draw(); } };
    list.appendChild(el);
  });
  side.appendChild(list);
}

// 1 ─ Brief
function drawBrief(c, side) {
  c.appendChild(B(`<div><h1>What is this reel for?</h1><p class="why">Name it, choose a style and a frame, and say what it should get across. Then choose who writes the story: the AI, you, or both.</p></div>`));
  const name = B(`<div class="field"><label for="bName">Name (lowercase, for the file)</label><input class="input" id="bName" value="${escB(spec.name)}"></div>`);
  name.querySelector('input').onchange = (e) => {
    const v = e.target.value.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, '-');
    if (!v || v === spec.name) return;
    spec.name = v; const o = $('specPick').querySelector('option:checked'); if (o) { o.value = v; o.textContent = v; }
    save(); toast('Saved as ' + v);
  };
  c.appendChild(name);
  const packs = B('<div class="field"><span>Style</span><div class="cards"></div></div>');
  PACKS.forEach((p) => {
    const b = B(`<button class="card${spec.pack === p.id ? ' on' : ''}"><span class="shape">${p.shape}</span><b>${p.name}</b><span>${p.blurb}</span></button>`);
    b.onclick = () => change(() => { spec.pack = p.id; if (p.id === 'kinetic' || p.id === 'glow') spec.format = 'wide'; });
    packs.querySelector('.cards').appendChild(b);
  });
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
  c.appendChild(B(`<div><h1>Which screens?</h1><p class="why">Each screen you add becomes a beat, in the order you add them. Add a screen twice to feature two moments of it.</p></div>`));
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
