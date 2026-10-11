import 'dart:convert';

/// The pages the CLI writes for the decisions a reel needs: which parts of
/// which screens to feature (`map`), which ground (`looks`), and whether
/// the beats are right (`storyboard`). Each ends in a note the person can
/// copy back to whoever is writing the reel.

/// Slim scroll bars for every BlaqReel page, the studio's included: a 4px
/// thumb on no track, brighter under the pointer and orange while dragged.
/// Chrome and Safari draw the `::-webkit-scrollbar` rules; Firefox, which has
/// none, gets its own thin bar. (Chrome ignores the webkit rules wherever
/// `scrollbar-width` is set, so those stay Firefox-only.)
const scrollbarCss = r'''
::-webkit-scrollbar { width:10px; height:10px; }
::-webkit-scrollbar-track, ::-webkit-scrollbar-corner { background:transparent; }
::-webkit-scrollbar-thumb { background:#2A2A2A; border:3px solid transparent; background-clip:padding-box; min-height:32px; }
::-webkit-scrollbar-thumb:hover { background-color:#444444; }
::-webkit-scrollbar-thumb:active { background-color:#FF6B00; }
::-webkit-scrollbar-button { display:none; }
@supports not selector(::-webkit-scrollbar) {
  * { scrollbar-width:thin; scrollbar-color:#2A2A2A transparent; }
}
''';

const _css =
    scrollbarCss +
    r'''
:root { color-scheme: dark; --bg:#0A0A0A; --surface:#0D0D0D; --deep:#080808; --line:#1A1A1A; --line2:#222222;
  --accent:#FF6B00; --text:#F5F5F5; --text2:#888888; --muted:#666666; --ok:#22C55E;
  --mono:'JetBrains Mono', ui-monospace, Menlo, monospace; --display:'Outfit', system-ui, sans-serif; }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--text); font:400 15px/1.5 var(--display);
  background-image:linear-gradient(var(--line) 1px,transparent 1px),linear-gradient(90deg,var(--line) 1px,transparent 1px);
  background-size:56px 56px; padding-bottom:140px; }
.wrap { max-width:1280px; margin:0 auto; padding-inline:24px; padding-block:36px 24px; }
.eyebrow { font:600 12px var(--mono); letter-spacing:.14em; text-transform:uppercase; color:var(--accent); }
h1 { font-weight:900; text-transform:uppercase; letter-spacing:-.03em; line-height:.95; font-size:clamp(30px,5vw,56px); margin:10px 0 12px; text-wrap:balance; }
h2 { font-weight:900; text-transform:uppercase; letter-spacing:-.02em; font-size:22px; margin:0; }
.lede { color:var(--text2); max-width:66ch; margin:0 0 28px; font-size:17px; }
.mono { font-family:var(--mono); }
.dim { color:var(--text2); }
.bar { position:fixed; left:0; right:0; bottom:0; background:var(--deep); border-top:1px solid var(--line2);
  padding:12px 24px calc(12px + env(safe-area-inset-bottom,0px)); display:flex; gap:12px; align-items:center; flex-wrap:wrap; z-index:5; }
.bar .note { flex:1 1 420px; min-width:0; font:400 12px/1.45 var(--mono); color:var(--text2); white-space:pre-wrap; max-height:76px; overflow:auto; }
button { font:600 12px var(--mono); text-transform:uppercase; letter-spacing:.06em; background:var(--surface); color:var(--text);
  border:1px solid var(--line2); padding:9px 13px; cursor:pointer; }
button:hover { border-color:var(--accent); }
button.primary { background:var(--accent); color:#0A0A0A; border-color:var(--accent); }
button:focus-visible, .part:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
''';

String _page(String title, String body, String script) =>
    '''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;900&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>$_css</style></head><body>$body<script>$script</script></body></html>''';

String _js(Object? data) => jsonEncode(data).replaceAll('</', r'<\/');

/// The map: each screen with a numbered outline on every part that could
/// be featured. Click parts to choose them; the note says which.
String mapPage(Map<String, Object?> map, {required String app}) => _page(
  '${map['reel']} · parts',
  '''
<div class="wrap">
  <div class="eyebrow">BlaqReel · $app · step 2 of 5</div>
  <h1>What should each beat feature?</h1>
  <p class="lede">Every screen in <b>${map['reel']}</b>, with a numbered outline on each card, row, field and photo that can lift, be tapped or be zoomed into. Click the ones you want shown, in the order you want them. The note at the bottom says which; copy it back.</p>
  <div id="screens"></div>
</div>
<div class="bar"><div class="note" id="note">Nothing chosen yet.</div>
  <button id="clear">Clear</button><button class="primary" id="copy">Copy note</button></div>
<style>
.screen { display:grid; grid-template-columns:minmax(0,360px) minmax(0,1fr); gap:24px; margin-bottom:40px;
  background:var(--surface); border:1px solid var(--line2); padding:18px; }
.shot { position:relative; align-self:start; max-width:100%; }
.shot img { width:100%; display:block; border:1px solid var(--line2); }
.box { position:absolute; border:2px solid rgba(255,107,0,.55); background:rgba(255,107,0,.06); cursor:pointer; }
.box b { position:absolute; left:-2px; top:-2px; transform:translateY(-100%); background:var(--accent); color:#0A0A0A;
  font:600 11px var(--mono); padding:1px 5px; }
.box.on { border-color:var(--ok); background:rgba(34,197,94,.14); }
.box.on b { background:var(--ok); }
.box.hot { border-color:var(--text); }
.list { display:grid; gap:6px; align-content:start; min-width:0; }
.part { all:unset; display:grid; grid-template-columns:44px minmax(0,1fr) auto; gap:10px; align-items:center;
  padding:8px 10px; border:1px solid var(--line2); background:var(--deep); cursor:pointer; }
.part:hover, .part.hot { border-color:var(--text2); }
.part.on { border-color:var(--ok); }
.part .n { font:600 13px var(--mono); color:var(--accent); }
.part.on .n { color:var(--ok); }
.part .name { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.part .text { color:var(--text2); font-size:13px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.part code { font:400 11px var(--mono); color:var(--muted); display:block; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.part .order { font:600 11px var(--mono); color:var(--ok); }
.head { display:flex; justify-content:space-between; align-items:baseline; gap:12px; margin-bottom:10px; }
@media (max-width:800px) { .screen { grid-template-columns:1fr; } }
</style>''',
  '''
const map = ${_js(map)};
let n = 0; const parts = []; const chosen = [];
const host = document.getElementById('screens');
map.screens.forEach((s) => {
  const el = document.createElement('section'); el.className = 'screen';
  el.innerHTML = `<div class="shot"><img src="\${s.image}" alt="\${s.scene} screen"></div>
    <div><div class="head"><h2>\${s.scene}</h2><span class="mono dim">\${s.screen} · from \${s.start.toFixed(1)}s</span></div><div class="list"></div></div>`;
  const shot = el.querySelector('.shot'), list = el.querySelector('.list');
  s.parts.forEach((p) => {
    const id = ++n; const part = { id, scene: s.scene, screen: s.screen, ...p }; parts.push(part);
    const [x, y, w, h] = p.rect;
    const box = document.createElement('div'); box.className = 'box';
    box.style.left = (100 * x / s.width) + '%'; box.style.top = (100 * y / s.height) + '%';
    box.style.width = (100 * w / s.width) + '%'; box.style.height = (100 * h / s.height) + '%';
    box.innerHTML = `<b>\${id}</b>`; shot.appendChild(box);
    const row = document.createElement('button'); row.className = 'part';
    row.innerHTML = `<span class="n">#\${id}</span><span style="min-width:0"><span class="name">\${p.name}</span>
      <span class="text">\${p.text ? '“' + p.text.replace(/</g, '&lt;') + '”' : ''}</span><code>\${p.pick.replace(/</g, '&lt;')}</code></span><span class="order"></span>`;
    list.appendChild(row);
    part.box = box; part.row = row;
    const toggle = () => { const i = chosen.indexOf(part); if (i >= 0) chosen.splice(i, 1); else chosen.push(part); draw(); };
    box.onclick = toggle; row.onclick = toggle;
    const hot = (on) => { box.classList.toggle('hot', on); row.classList.toggle('hot', on); };
    box.onmouseenter = row.onmouseenter = () => hot(true);
    box.onmouseleave = row.onmouseleave = () => hot(false);
  });
  host.appendChild(el);
});
function draw() {
  parts.forEach((p) => { const i = chosen.indexOf(p); p.box.classList.toggle('on', i >= 0); p.row.classList.toggle('on', i >= 0);
    p.row.querySelector('.order').textContent = i >= 0 ? (i + 1) + '.' : ''; });
  const note = document.getElementById('note');
  if (!chosen.length) { note.textContent = 'Nothing chosen yet.'; return; }
  const by = {};
  chosen.forEach((p) => (by[p.scene] ??= []).push(p));
  note.textContent = 'Feature these in ' + map.reel + ', in this order:\\n' + Object.entries(by).map(([scene, ps]) =>
    '• ' + scene + ': ' + ps.map((p) => '#' + p.id + ' ' + p.name + (p.text ? ' “' + p.text + '”' : '') + ' → ' + p.pick).join('; ')).join('\\n');
}
document.getElementById('clear').onclick = () => { chosen.length = 0; draw(); };
document.getElementById('copy').onclick = async (e) => {
  const text = document.getElementById('note').textContent;
  try { await navigator.clipboard.writeText(text); e.target.textContent = 'Copied'; }
  catch { const r = document.createRange(); r.selectNodeContents(document.getElementById('note')); getSelection().removeAllRanges(); getSelection().addRange(r); }
  setTimeout(() => (e.target.textContent = 'Copy note'), 1400);
};
''',
);

/// The looks: the same moments of a reel on each ground. Click one to
/// choose it, for the whole reel or for one scene.
String looksPage({
  required String reel,
  required String app,
  required List<String> looks,
  required List<double> times,
  required Map<String, String> blurbs,
}) => _page(
  '$reel · grounds',
  '''
<div class="wrap">
  <div class="eyebrow">BlaqReel · $app · step 3 of 5</div>
  <h1>Which ground should it sit on?</h1>
  <p class="lede">The same moments of <b>$reel</b> on every ground. Click one to choose it for the whole reel. To give a single beat its own ground, choose it again and name the beat in the note.</p>
  <div id="grid"></div>
</div>
<div class="bar"><div class="note" id="note">Nothing chosen yet.</div>
  <input id="scene" placeholder="Only for this beat (optional), e.g. Scan." style="font:400 13px var(--mono);background:var(--surface);color:var(--text);border:1px solid var(--line2);padding:9px;min-width:220px">
  <button class="primary" id="copy">Copy note</button></div>
<style>
#grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(210px,1fr)); gap:14px; }
.look { all:unset; display:grid; gap:8px; background:var(--surface); border:1px solid var(--line2); padding:10px; cursor:pointer; align-content:start; }
.look:hover { border-color:var(--text2); }
.look.on { border-color:var(--ok); }
.look img { width:100%; display:block; border:1px solid var(--line2); }
.look .frames { display:grid; gap:6px; grid-template-columns:repeat(auto-fit,minmax(90px,1fr)); }
.look b { font-weight:900; text-transform:uppercase; font-size:17px; }
.look span { color:var(--text2); font-size:13px; }
</style>''',
  '''
const looks = ${_js(looks)}, times = ${_js(times)}, blurbs = ${_js(blurbs)};
const grid = document.getElementById('grid'); const picks = [];
looks.forEach((l) => {
  const b = document.createElement('button'); b.className = 'look';
  b.innerHTML = `<div class="frames">\${times.map((t) => `<img src="\${l}-\${t}s.png" alt="\${l} at \${t}s">`).join('')}</div>
    <b>\${l}</b><span>\${blurbs[l] || ''}</span>`;
  b.onclick = () => {
    const scene = document.getElementById('scene').value.trim();
    picks.push(scene ? l + ' for ' + scene : l + ' for the whole reel');
    grid.querySelectorAll('.look').forEach((x) => x.classList.toggle('on', x === b));
    document.getElementById('note').textContent = 'Grounds for $reel:\\n' + picks.map((p) => '• ' + p).join('\\n');
    document.getElementById('scene').value = '';
  };
  grid.appendChild(b);
});
document.getElementById('copy').onclick = async (e) => {
  try { await navigator.clipboard.writeText(document.getElementById('note').textContent); e.target.textContent = 'Copied'; } catch {}
  setTimeout(() => (e.target.textContent = 'Copy note'), 1400);
};
''',
);

/// The storyboard: a frame from each scene with its timing, words and
/// sounds, and a note field per scene for changes.
String storyboardPage({
  required Map<String, Object?> reel,
  required String app,
  required List<Map<String, Object?>> frames,
}) => _page(
  '${reel['name']} · storyboard',
  '''
<div class="wrap">
  <div class="eyebrow">BlaqReel · $app · step 4 of 5</div>
  <h1>${reel['name']}: ${(reel['length']! as num).toStringAsFixed(1)} seconds, ${(reel['scenes']! as List).length} scenes</h1>
  <p class="lede">A frame from each scene, with its timing, words and sounds. Write what should change under any of them; the note collects them all. When it reads right, it is ready to render.</p>
  <div id="board"></div>
</div>
<div class="bar"><div class="note" id="note">No changes noted yet.</div>
  <button class="primary" id="copy">Copy note</button></div>
<style>
#board { display:grid; grid-template-columns:repeat(auto-fill,minmax(230px,1fr)); gap:14px; }
.frame { background:var(--surface); border:1px solid var(--line2); padding:10px; display:grid; gap:8px; align-content:start; min-width:0; }
.frame img { width:100%; display:block; border:1px solid var(--line2); }
.frame .t { font:600 12px var(--mono); color:var(--accent); }
.frame b { font-weight:900; text-transform:uppercase; font-size:18px; }
.frame .meta { font:400 12px var(--mono); color:var(--text2); }
.frame textarea { font:400 13px var(--display); background:var(--deep); color:var(--text); border:1px solid var(--line2); padding:8px; min-height:56px; resize:vertical; }
.frame textarea:focus { outline:none; border-color:var(--accent); }
</style>''',
  '''
const reel = ${_js(reel)}, frames = ${_js(frames)};
const board = document.getElementById('board');
const key = 'blaqreel-notes-' + reel.name;
let notes = {}; try { notes = JSON.parse(localStorage.getItem(key) || '{}'); } catch {}
reel.scenes.forEach((s, i) => {
  const f = frames[i]; const el = document.createElement('div'); el.className = 'frame';
  const words = s.words.map((w) => '“' + w.text + '” at ' + w.at.toFixed(1) + 's').join(', ') || 'no words';
  const cues = reel.cues.filter((c) => c.at >= s.start && c.at < s.end).map((c) => c.sound);
  el.innerHTML = `<img src="\${f.image}" alt="\${s.name} at \${f.at}s">
    <div class="t">\${s.start.toFixed(1)}s – \${s.end.toFixed(1)}s\${s.enter ? ' · in by ' + s.enter : ''}</div>
    <b>\${s.name}</b><div class="meta">\${words}\${cues.length ? '<br>sounds: ' + [...new Set(cues)].join(', ') : ''}</div>
    <textarea id="note-\${i}" placeholder="What should change here?"></textarea>`;
  const ta = el.querySelector('textarea'); ta.value = notes[s.name] || '';
  ta.oninput = () => { notes[s.name] = ta.value; try { localStorage.setItem(key, JSON.stringify(notes)); } catch {} draw(); };
  board.appendChild(el);
});
function draw() {
  const lines = reel.scenes.filter((s) => (notes[s.name] || '').trim()).map((s) => '• ' + s.name + ': ' + notes[s.name].trim());
  document.getElementById('note').textContent = lines.length ? 'Changes to ' + reel.name + ':\\n' + lines.join('\\n') : 'No changes noted yet.';
}
draw();
document.getElementById('copy').onclick = async (e) => {
  try { await navigator.clipboard.writeText(document.getElementById('note').textContent); e.target.textContent = 'Copied'; } catch {}
  setTimeout(() => (e.target.textContent = 'Copy note'), 1400);
};
''',
);
