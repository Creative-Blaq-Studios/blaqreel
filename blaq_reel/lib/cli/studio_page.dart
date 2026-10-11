import 'animator_page.dart';
import 'builder_page.dart';
import 'pages.dart' show scrollbarCss;

/// The studio's page: served by `blaq_reel studio`. The builder's own CSS,
/// markup and script are spliced in where the markers are.
final studioPage = _studioBase
    .replaceFirst('/*SCROLLBARS*/', scrollbarCss)
    .replaceFirst('/*BUILD_CSS*/', builderCss + animatorCss)
    .replaceFirst('<!--BUILD_HTML-->', builderHtml)
    .replaceFirst('/*BUILD_JS*/', builderJs + animatorJs);

const _studioBase = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BlaqReel Studio</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;900&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
  /*SCROLLBARS*/
  :root {
    color-scheme: dark;
    --bg: #0A0A0A; --surface: #0D0D0D; --deep: #080808; --raised: #141414;
    --line: #1A1A1A; --line2: #222222;
    --accent: #FF6B00; --accent-hover: #E06000;
    --text: #F5F5F5; --text2: #888888; --muted: #666666;
    --ok: #22C55E; --warn: #FBBF24; --bad: #EF4444;
    --mono: 'JetBrains Mono', ui-monospace, monospace;
  }
  * { box-sizing: border-box; }
  html, body { margin: 0; height: 100%; background: var(--bg); color: var(--text);
    font: 400 14px/1.4 Outfit, system-ui, sans-serif; }
  body { display: grid; grid-template-rows: auto 1fr auto; height: 100vh; overflow: hidden;
    background-image: linear-gradient(var(--line) 1px, transparent 1px),
      linear-gradient(90deg, var(--line) 1px, transparent 1px);
    background-size: 48px 48px; background-position: -1px -1px; }
  header { display: flex; align-items: center; gap: 14px; padding: 12px 20px;
    border-bottom: 1px solid var(--line2); background: var(--deep); flex-wrap: wrap; }
  .brand { font-weight: 900; text-transform: uppercase; letter-spacing: -0.02em; font-size: 18px; }
  .brand b { color: var(--accent); }
  .now { display: flex; align-items: center; gap: 8px; min-width: 0; }
  .mode { font: 600 10px var(--mono); text-transform: uppercase; letter-spacing: .1em;
    padding: 4px 7px; background: var(--accent); color: #0A0A0A; white-space: nowrap; }
  .mode.final { background: var(--text); }
  .nowname { font-weight: 600; font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 340px; }
  .now { flex: 0 1 auto; }
  .tag { font: 600 11px var(--mono); text-transform: uppercase; letter-spacing: .08em;
    color: var(--text2); border: 1px solid var(--line2); padding: 4px 8px; white-space: nowrap; }
  .status { display: flex; align-items: center; gap: 8px; margin-left: auto; font: 400 12px var(--mono); color: var(--text2); }
  .dot { width: 8px; height: 8px; background: var(--ok); flex: none; }
  .dot.busy { background: var(--warn); animation: pulse 1s infinite; }
  .dot.bad { background: var(--bad); }
  @keyframes pulse { 50% { opacity: .3; } }
  button { font: 600 12px var(--mono); text-transform: uppercase; letter-spacing: .06em;
    background: var(--surface); color: var(--text); border: 1px solid var(--line2);
    padding: 8px 12px; cursor: pointer; }
  button:hover:not(:disabled) { border-color: var(--accent); }
  button:disabled { opacity: .35; cursor: default; }
  button.primary { background: var(--accent); color: #0A0A0A; border-color: var(--accent); }
  button.primary:hover:not(:disabled) { background: var(--accent-hover); }
  button.on { border-color: var(--accent); color: var(--accent); }
  main { display: grid; grid-template-columns: 290px 1fr 250px; min-height: 0; }
  nav { border-right: 1px solid var(--line2); background: var(--deep); overflow: auto; padding: 16px 14px; }
  h2 { margin: 0 0 10px; font: 600 11px var(--mono); color: var(--text2);
    text-transform: uppercase; letter-spacing: .1em; display: flex; justify-content: space-between; }
  h2 span { color: var(--muted); }
  section + section { margin-top: 22px; }
  .reel { border: 1px solid var(--line2); background: var(--surface); padding: 8px 10px; margin-bottom: 6px; }
  .reel.active { border-color: var(--accent); }
  .reel-top { display: flex; justify-content: space-between; align-items: baseline; gap: 8px; }
  .reel-name { font-weight: 600; }
  .reel-meta { font: 400 11px var(--mono); color: var(--text2); }
  .chips { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 6px; }
  .chip { font: 600 9px var(--mono); text-transform: uppercase; letter-spacing: .04em;
    padding: 4px 5px; background: var(--raised); border: 1px solid var(--line2); color: var(--text2); cursor: pointer; }
  .chip:hover { border-color: var(--accent); color: var(--text); }
  .chip.on { background: var(--accent); border-color: var(--accent); color: #0A0A0A; }
  .video { display: grid; grid-template-columns: 54px 1fr; gap: 10px; align-items: center;
    padding: 8px; border: 1px solid var(--line2); background: var(--surface); margin-bottom: 8px; cursor: pointer; width: 100%;
    text-align: left; font: inherit; color: inherit; text-transform: none; letter-spacing: 0; }
  .video:hover { border-color: var(--accent); }
  .video.active { border-color: var(--text); background: var(--raised); }
  .thumb { width: 54px; height: 54px; background: #000; display: grid; place-items: center; overflow: hidden; }
  .thumb img { max-width: 54px; max-height: 54px; display: block; }
  .v-name { font-weight: 600; font-size: 13px; }
  .v-meta { font: 400 11px var(--mono); color: var(--text2); margin-top: 2px; }
  .empty-note { color: var(--muted); font-size: 12px; }
  .stage { display: grid; place-items: center; padding: 20px; min-height: 0; min-width: 0; position: relative; }
  video { max-width: 100%; max-height: calc(100vh - 290px); background: #000;
    box-shadow: 0 30px 80px rgba(0,0,0,.6); outline: 1px solid var(--line2); }
  .empty { color: var(--text2); text-align: center; max-width: 320px; }
  aside { border-left: 1px solid var(--line2); background: var(--deep); padding: 16px;
    overflow: auto; display: flex; flex-direction: column; gap: 18px; }
  .stills { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  .stills a { display: block; border: 1px solid var(--line2); }
  .stills a:hover { border-color: var(--accent); }
  .stills img { width: 100%; display: block; }
  .stills span { display: block; font: 400 11px var(--mono); color: var(--text2); padding: 4px 6px; }
  .log { font: 400 11px/1.5 var(--mono); color: var(--text2); white-space: pre-wrap;
    word-break: break-word; max-height: 220px; overflow: auto; }
  .keys { font: 400 12px var(--mono); color: var(--text2); display: grid;
    grid-template-columns: auto 1fr; gap: 4px 12px; }
  .keys b { color: var(--text); font-weight: 600; }
  footer { border-top: 1px solid var(--line2); background: var(--deep); padding: 12px 20px 18px; }
  .transport { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
  .time { font: 600 20px var(--mono); min-width: 132px; }
  .time small { font-size: 12px; color: var(--text2); font-weight: 400; }
  .spacer { flex: 1; }
  .timeline { position: relative; height: 92px; background: var(--surface);
    border: 1px solid var(--line2); cursor: pointer; user-select: none; touch-action: none; }
  .scene { position: absolute; top: 34px; height: 30px; border-right: 1px solid var(--bg);
    padding: 6px 8px; font: 600 11px var(--mono); overflow: hidden; white-space: nowrap;
    color: var(--text); background: #171717; }
  .scene:nth-child(even) { background: #1F1F1F; }
  .overlap { position: absolute; top: 34px; height: 30px; z-index: 1; pointer-events: none;
    background: repeating-linear-gradient(135deg, rgba(255,107,0,.35) 0 4px, transparent 4px 8px); }
  .word { position: absolute; top: 4px; font: 600 11px Outfit, sans-serif; color: var(--accent);
    border-left: 2px solid var(--accent); padding-left: 4px; white-space: nowrap;
    max-width: 92px; overflow: hidden; text-overflow: ellipsis; }
  .cue { position: absolute; bottom: 6px; width: 2px; height: 14px; background: var(--text2); }
  .cue[data-s="whoosh"] { background: #8AB4FF; height: 18px; }
  .cue[data-s="tap"], .cue[data-s="tick"] { background: var(--ok); }
  .cue[data-s="chime"], .cue[data-s="rise"] { background: var(--warn); }
  .voice { position: absolute; top: 66px; height: 6px; background: #C084FC; }
  .head { position: absolute; top: 0; bottom: 0; width: 2px; background: var(--text);
    box-shadow: 0 0 0 1px rgba(0,0,0,.5); pointer-events: none; z-index: 2; }
  .hover { position: absolute; top: -22px; font: 400 11px var(--mono); color: var(--text2);
    transform: translateX(-50%); pointer-events: none; display: none; }
  .ticks { position: absolute; left: 0; right: 0; top: 72px; height: 18px; pointer-events: none; }
  .ticks i { position: absolute; top: 0; font: 400 10px var(--mono); color: var(--muted);
    border-left: 1px solid var(--line2); padding-left: 3px; height: 100%; font-style: normal; }
  .toast { position: fixed; bottom: 140px; left: 50%; transform: translateX(-50%);
    background: var(--text); color: var(--bg); padding: 8px 14px; font: 600 12px var(--mono);
    opacity: 0; transition: opacity .2s; pointer-events: none; z-index: 10; }
  .toast.show { opacity: 1; }
  @media (max-width: 1100px) { main { grid-template-columns: 250px 1fr; } aside { display: none; } }
  @media (max-width: 760px) {
    body { height: auto; overflow: auto; }
    main { grid-template-columns: 1fr; }
    nav { border-right: 0; border-bottom: 1px solid var(--line2); max-height: 40vh; }
    video { max-height: 60vh; }
  }
/*BUILD_CSS*/
</style>
</head>
<body>
<header>
  <div class="brand">Blaq<b>Reel</b> Studio</div>
  <div class="tabs" role="tablist"><button id="tabLibrary" class="tab on" role="tab">Library</button><button id="tabBuild" class="tab" role="tab">Build</button></div>
  <div class="now"><span class="mode" id="mode">Live preview</span><span class="nowname" id="nowName">—</span></div>
  <span class="tag" id="formatName">—</span>
  <div class="status"><span class="dot" id="dot"></span><span id="status">Starting</span></div>
  <button id="renderBtn" title="R — render the preview again">Re-render</button>
  <button id="finalBtn" title="Render the finished video of this reel and format">Render final</button>
  <button class="primary" id="stillBtn" title="S">Still</button>
</header>
<main>
  <nav>
    <section>
      <h2>Rendered videos <span id="videoCount"></span></h2>
      <div id="videos"><div class="empty-note">None yet.</div></div>
    </section>
    <section>
      <h2>Reels <span>work on one live</span></h2>
      <div id="reels"><div class="empty-note">Reading the reels…</div></div>
    </section>
  </nav>
  <div class="stage">
    <div class="empty" id="empty">Rendering the first preview…</div>
    <video id="video" playsinline preload="auto" hidden></video>
  </div>
  <aside>
    <section><h2>Stills</h2><div class="stills" id="stills"><span style="color:var(--muted)">Press S for a full-size still at the playhead.</span></div></section>
    <section><h2>Keys</h2>
      <div class="keys">
        <b>Space</b><span>Play / pause</span>
        <b>← →</b><span>One frame</span>
        <b>⇧ ← →</b><span>One second</span>
        <b>[ ]</b><span>Previous / next scene</span>
        <b>S</b><span>Full-size still</span>
        <b>C</b><span>Copy the time</span>
        <b>R</b><span>Re-render the preview</span>
        <b>L</b><span>Loop the scene</span>
      </div>
    </section>
    <section><h2>Log</h2><div class="log" id="log">—</div></section>
  </aside>
</main>
<footer>
  <div class="transport">
    <button id="prev" title="Previous scene">⏮</button>
    <button id="back" title="One frame back">◀</button>
    <button id="play" class="primary" title="Space">Play</button>
    <button id="fwd" title="One frame on">▶</button>
    <button id="next" title="Next scene">⏭</button>
    <div class="time" id="time">0.00s <small>frame 0</small></div>
    <div class="spacer"></div>
    <button data-rate="0.25">¼×</button>
    <button data-rate="0.5">½×</button>
    <button data-rate="1" class="on">1×</button>
    <button id="loop">Loop scene</button>
    <button id="mute">Sound on</button>
  </div>
  <div class="timeline" id="timeline">
    <div id="lanes"></div>
    <div class="ticks" id="ticks"></div>
    <div class="head" id="head"></div>
    <div class="hover" id="hover"></div>
  </div>
</footer>
<!--BUILD_HTML-->
<div class="toast" id="toast"></div>
<script>
const $ = (id) => document.getElementById(id);
const video = $('video');
// What plays: the live preview of the reel being worked on, or a finished
// video from out/.
let mode = 'live', playingFile = null;
let reel = null, fps = 30, loop = false;
let state = null, seenVersion = -1, seenLibrary = -1, library = { reels: [], videos: [] };

function toast(text) {
  const t = $('toast'); t.textContent = text; t.classList.add('show');
  clearTimeout(toast.h); toast.h = setTimeout(() => t.classList.remove('show'), 1700);
}
const fmt = (s) => (+s).toFixed(2) + 's';
const frameOf = (s) => Math.round(s * fps);
const mb = (b) => (b / 1048576).toFixed(1) + ' MB';
function ago(iso) {
  const s = (Date.now() - new Date(iso)) / 1000;
  if (s < 90) return 'just now';
  if (s < 3600) return Math.round(s / 60) + ' min ago';
  if (s < 86400) return Math.round(s / 3600) + ' h ago';
  return new Date(iso).toLocaleDateString();
}
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ── Timeline ──────────────────────────────────────────────────────────
function length() { return reel ? reel.length : (video.duration || 0); }
function drawTimeline() {
  const lanes = $('lanes'), ticks = $('ticks');
  lanes.innerHTML = ''; ticks.innerHTML = '';
  const L = length();
  if (!L) return;
  const pct = (s) => (100 * s / L) + '%';
  let wi = 0;
  (reel ? reel.scenes : []).forEach((sc, i) => {
    const d = document.createElement('div');
    d.className = 'scene'; d.style.left = pct(sc.start); d.style.width = pct(sc.end - sc.start);
    d.textContent = sc.name; d.title = `${sc.name}  ${fmt(sc.start)} – ${fmt(sc.end)}`;
    lanes.appendChild(d);
    const nx = reel.scenes[i + 1];
    if (nx && nx.start < sc.end) {
      const o = document.createElement('div');
      o.className = 'overlap'; o.style.left = pct(nx.start); o.style.width = pct(sc.end - nx.start);
      o.title = `${nx.enter} ${fmt(nx.start)} – ${fmt(sc.end)}`;
      lanes.appendChild(o);
    }
    sc.words.forEach((w) => {
      const m = document.createElement('div');
      m.className = 'word'; m.style.left = pct(w.at); m.textContent = w.text;
      m.style.top = (wi++ % 2 ? 18 : 4) + 'px'; m.title = `${w.text} @ ${fmt(w.at)}`;
      lanes.appendChild(m);
    });
  });
  (reel ? reel.cues : []).forEach((c) => {
    const m = document.createElement('div');
    m.className = 'cue'; m.dataset.s = c.sound; m.style.left = pct(c.at);
    m.title = `${c.sound} @ ${fmt(c.at)}`;
    lanes.appendChild(m);
  });
  (reel ? reel.voice || [] : []).forEach((v) => {
    const m = document.createElement('div');
    m.className = 'voice'; m.style.left = pct(v.at); m.style.width = pct(Math.min(3, L - v.at));
    m.title = `voice @ ${fmt(v.at)}: ${v.text}`;
    lanes.appendChild(m);
  });
  const step = L > 40 ? 5 : L > 12 ? 2 : 1;
  for (let s = 0; s <= L; s += step) {
    const i = document.createElement('i'); i.style.left = pct(s); i.textContent = s + 's';
    ticks.appendChild(i);
  }
}
function sceneAt(s) {
  if (!reel) return null;
  return [...reel.scenes].reverse().find((sc) => s >= sc.start) || reel.scenes[0];
}
function tick() {
  const L = length();
  if (L) {
    const s = video.currentTime;
    $('head').style.left = (100 * s / L) + '%';
    $('time').innerHTML = `${fmt(s)} <small>frame ${frameOf(s)} / ${frameOf(L)}</small>`;
    if (loop && !video.paused) {
      const sc = sceneAt(s);
      if (sc && s >= sc.end - 0.02) video.currentTime = sc.start;
    }
  }
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);
function seek(s) { const L = length(); if (L) video.currentTime = Math.max(0, Math.min(L - 1 / fps, s)); }
function stepFrames(n) { video.pause(); seek(Math.round(video.currentTime * fps + n) / fps); }

const tl = $('timeline');
function timeFromEvent(e) {
  const r = tl.getBoundingClientRect();
  return Math.max(0, Math.min(1, (e.clientX - r.left) / r.width)) * length();
}
let dragging = false;
tl.addEventListener('pointerdown', (e) => { dragging = true; tl.setPointerCapture(e.pointerId); video.pause(); seek(timeFromEvent(e)); });
tl.addEventListener('pointermove', (e) => {
  const h = $('hover'), s = timeFromEvent(e), L = length() || 1;
  h.style.display = 'block'; h.style.left = (100 * s / L) + '%'; h.textContent = fmt(s);
  if (dragging) seek(s);
});
tl.addEventListener('pointerup', () => { dragging = false; });
tl.addEventListener('pointerleave', () => { $('hover').style.display = 'none'; });

// ── What plays ────────────────────────────────────────────────────────
function load(src, meta, keepTime) {
  const at = keepTime ? video.currentTime || 0 : 0, playing = keepTime && !video.paused;
  reel = meta; fps = meta ? meta.fps : 30;
  video.src = src; video.hidden = false; $('empty').hidden = true;
  video.addEventListener('loadedmetadata', () => { seek(at); drawTimeline(); if (playing) video.play(); }, { once: true });
  drawTimeline();
}

function showLive(keepTime) {
  mode = 'live'; playingFile = null;
  $('mode').textContent = 'Live preview'; $('mode').className = 'mode';
  const p = state && state.preview;
  $('nowName').textContent = state ? state.reel : '—';
  $('formatName').textContent = state ? state.format : '—';
  if (p && p.name === state.reel && p.format === state.format) {
    load(`/files/${p.video}?v=${state.version}`, p, keepTime);
    $('formatName').textContent = `${p.format} ${p.width}×${p.height} · ${p.fps} fps · ${fmt(p.length)}`;
  } else {
    video.pause(); video.hidden = true; $('empty').hidden = false; reel = null; drawTimeline();
    $('empty').textContent = `Rendering the preview of ${state ? state.reel + ' · ' + state.format : 'the reel'}… about a minute.`;
  }
  drawLibrary();
}

async function showVideo(v) {
  mode = 'video'; playingFile = v.file;
  $('mode').textContent = 'Rendered'; $('mode').className = 'mode final';
  $('nowName').textContent = v.file;
  const meta = await fetch(`/api/meta?reel=${encodeURIComponent(v.reel)}&format=${v.format}`).then((r) => r.json());
  $('formatName').textContent = meta
    ? `${meta.format} ${meta.width}×${meta.height} · ${meta.fps} fps · ${fmt(v.duration)} · ${mb(v.bytes)}`
    : `${v.format} · ${fmt(v.duration)} · ${mb(v.bytes)}`;
  load(`/out/${encodeURIComponent(v.file)}?m=${encodeURIComponent(v.modified)}`, meta, false);
  drawLibrary();
}

// ── Library ───────────────────────────────────────────────────────────
function drawLibrary() {
  const reels = $('reels');
  if (!library.reels.length) {
    reels.innerHTML = '<div class="empty-note">Reading the reels…</div>';
  } else {
    reels.innerHTML = '';
    library.reels.forEach((r) => {
      const working = state && state.reel === r.name;
      const box = document.createElement('div');
      box.className = 'reel' + (working && mode === 'live' ? ' active' : '');
      const first = r.formats.find((f) => working && f.format === state.format) || r.formats[0];
      box.innerHTML = `<div class="reel-top"><span class="reel-name">${esc(r.name)}</span>
        <span class="reel-meta">${fmt(first.length)} · ${first.scenes} scenes</span></div><div class="chips"></div>`;
      const chips = box.querySelector('.chips');
      r.formats.forEach((f) => {
        const c = document.createElement('button');
        c.className = 'chip' + (working && state.format === f.format && mode === 'live' ? ' on' : '');
        c.textContent = f.format; c.title = `Work on ${r.name} in ${f.format}, live`;
        c.onclick = () => select(r.name, f.format);
        chips.appendChild(c);
      });
      reels.appendChild(box);
    });
  }
  const vids = $('videos');
  $('videoCount').textContent = library.videos.length ? library.videos.length : '';
  if (!library.videos.length) {
    vids.innerHTML = '<div class="empty-note">None yet. Press Render final.</div>';
    return;
  }
  vids.innerHTML = '';
  library.videos.forEach((v) => {
    const b = document.createElement('button');
    b.className = 'video' + (mode === 'video' && playingFile === v.file ? ' active' : '');
    b.title = `Play ${v.file}`;
    b.innerHTML = `<div class="thumb"><img loading="lazy" alt="" src="/thumbs/${encodeURIComponent(v.file.replace(/\.mp4$/, '.jpg'))}?m=${encodeURIComponent(v.modified)}"></div>
      <div><div class="v-name">${esc(v.reel)} <span style="color:var(--text2);font-weight:400">· ${esc(v.format)}</span></div>
      <div class="v-meta">${fmt(v.duration)} · ${mb(v.bytes)} · ${ago(v.modified)}</div></div>`;
    b.onclick = () => showVideo(v);
    vids.appendChild(b);
  });
}

// ?video=<file> opens the studio on that finished video.
let wanted = new URLSearchParams(location.search).get('video');
async function refreshLibrary() {
  library = await fetch('/api/library').then((r) => r.json());
  drawLibrary();
  const v = wanted && library.videos.find((x) => x.file === wanted);
  if (v) { wanted = null; await showVideo(v); }
}

async function select(name, format) {
  await fetch(`/api/select?reel=${encodeURIComponent(name)}&format=${format}`, { method: 'POST' });
  state = await fetch('/api/state').then((r) => r.json());
  seenVersion = state.version;
  showLive(false);
  toast(`Working on ${name} · ${format}`);
}

// ── Controls ──────────────────────────────────────────────────────────
$('play').onclick = () => (video.paused ? video.play() : video.pause());
video.onplay = () => ($('play').textContent = 'Pause');
video.onpause = () => ($('play').textContent = 'Play');
$('back').onclick = () => stepFrames(-1);
$('fwd').onclick = () => stepFrames(1);
$('prev').onclick = () => { if (!reel) return seek(0); const sc = sceneAt(video.currentTime - 0.05); const i = reel.scenes.indexOf(sc); seek(video.currentTime - sc.start > 0.3 ? sc.start : reel.scenes[Math.max(0, i - 1)].start); };
$('next').onclick = () => { if (!reel) return; const sc = sceneAt(video.currentTime); const i = reel.scenes.indexOf(sc); if (reel.scenes[i + 1]) seek(reel.scenes[i + 1].start); };
document.querySelectorAll('[data-rate]').forEach((b) => b.onclick = () => {
  video.playbackRate = +b.dataset.rate;
  document.querySelectorAll('[data-rate]').forEach((x) => x.classList.toggle('on', x === b));
});
$('loop').onclick = () => { loop = !loop; $('loop').classList.toggle('on', loop); };
$('mute').onclick = () => { video.muted = !video.muted; $('mute').textContent = video.muted ? 'Sound off' : 'Sound on'; };
$('renderBtn').onclick = () => { fetch('/api/render', { method: 'POST' }); if (mode !== 'live') showLive(false); toast('Re-rendering the preview'); };
$('finalBtn').onclick = () => {
  fetch('/api/final', { method: 'POST' });
  toast(`Rendering the final ${state.reel} · ${state.format}; it appears under Rendered videos`);
};

async function still() {
  const s = +video.currentTime.toFixed(2);
  const which = mode === 'video'
    ? library.videos.find((v) => v.file === playingFile)
    : { reel: state.reel, format: state.format };
  toast(`Rendering a still at ${fmt(s)}…`);
  const r = await fetch(`/api/still?t=${s}&reel=${encodeURIComponent(which.reel)}&format=${which.format}`, { method: 'POST' }).then((x) => x.json());
  if (!r.ok) return toast('Still failed — see the log');
  const box = $('stills');
  if (!box.querySelector('a')) box.innerHTML = '';
  const a = document.createElement('a');
  a.href = r.url + '?v=' + Date.now(); a.target = '_blank'; a.title = r.path;
  a.innerHTML = `<img src="${a.href}" alt="Still at ${fmt(s)}"><span>${esc(which.reel)} ${fmt(s)}</span>`;
  box.prepend(a);
  toast('Still saved');
}
$('stillBtn').onclick = still;

document.addEventListener('keydown', (e) => {
  if (e.target.tagName === 'INPUT') return;
  if (e.code === 'Space') { e.preventDefault(); $('play').click(); }
  else if (e.key === 'ArrowLeft') { e.preventDefault(); e.shiftKey ? (video.pause(), seek(video.currentTime - 1)) : stepFrames(-1); }
  else if (e.key === 'ArrowRight') { e.preventDefault(); e.shiftKey ? (video.pause(), seek(video.currentTime + 1)) : stepFrames(1); }
  else if (e.key === '[') $('prev').click();
  else if (e.key === ']') $('next').click();
  else if (e.key === 's' || e.key === 'S') still();
  else if (e.key === 'r' || e.key === 'R') $('renderBtn').click();
  else if (e.key === 'l' || e.key === 'L') $('loop').click();
  else if (e.key === 'c' || e.key === 'C') {
    const name = mode === 'video' ? playingFile : `${state.reel} · ${state.format}`;
    const text = `${name} @ ${fmt(video.currentTime)} (frame ${frameOf(video.currentTime)})`;
    navigator.clipboard?.writeText(text); toast('Copied: ' + text);
  }
});

// ── Polling ───────────────────────────────────────────────────────────
async function poll() {
  try {
    state = await fetch('/api/state').then((r) => r.json());
    if (window.onStudioState) window.onStudioState(state);
    const dot = $('dot');
    dot.className = 'dot' + (state.job ? ' busy' : state.status.includes('failed') ? ' bad' : '');
    $('status').textContent = state.job ? state.job + '…' : state.status;
    $('log').textContent = state.log.length ? state.log.join('\n') : '—';
    $('finalBtn').title = `Render the finished ${state.reel} · ${state.format}`;
    if (state.library !== seenLibrary) { seenLibrary = state.library; await refreshLibrary(); }
    if (state.version !== seenVersion) {
      const first = seenVersion < 0 && !wanted;
      seenVersion = state.version;
      if (mode === 'live') {
        showLive(!first);
        if (!first && state.preview) toast('Preview updated');
      }
    }
  } catch (e) { $('status').textContent = 'Studio stopped'; $('dot').className = 'dot bad'; }
  setTimeout(poll, 1000);
}
poll();
setInterval(refreshLibrary, 15000);
/*BUILD_JS*/
</script>
</body>
</html>
''';
