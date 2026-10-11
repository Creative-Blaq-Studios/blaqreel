/// The studio's page: served by `blaq_reel studio`.
const studioPage = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BlaqReel Studio</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;900&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
  :root {
    color-scheme: dark;
    --bg: #0A0A0A; --surface: #0D0D0D; --deep: #080808;
    --line: #1A1A1A; --line2: #222222;
    --accent: #FF6B00; --accent-hover: #E06000;
    --text: #F5F5F5; --text2: #888888; --muted: #666666;
    --ok: #22C55E; --warn: #FBBF24; --bad: #EF4444;
  }
  * { box-sizing: border-box; }
  html, body { margin: 0; height: 100%; background: var(--bg); color: var(--text);
    font: 400 14px/1.4 Outfit, system-ui, sans-serif; }
  body { display: grid; grid-template-rows: auto 1fr auto; min-height: 100vh;
    background-image: linear-gradient(var(--line) 1px, transparent 1px),
      linear-gradient(90deg, var(--line) 1px, transparent 1px);
    background-size: 48px 48px; background-position: -1px -1px; }
  header { display: flex; align-items: center; gap: 16px; padding: 12px 20px;
    border-bottom: 1px solid var(--line2); background: var(--deep); flex-wrap: wrap; }
  .brand { font-weight: 900; text-transform: uppercase; letter-spacing: -0.02em; font-size: 18px; }
  .brand b { color: var(--accent); }
  .mono { font-family: 'JetBrains Mono', ui-monospace, monospace; }
  .tag { font: 600 11px 'JetBrains Mono', monospace; text-transform: uppercase;
    letter-spacing: .08em; color: var(--text2); border: 1px solid var(--line2); padding: 4px 8px; }
  .status { display: flex; align-items: center; gap: 8px; margin-left: auto; }
  .dot { width: 8px; height: 8px; background: var(--ok); }
  .dot.busy { background: var(--warn); animation: pulse 1s infinite; }
  .dot.bad { background: var(--bad); }
  @keyframes pulse { 50% { opacity: .3; } }
  button { font: 600 12px 'JetBrains Mono', monospace; text-transform: uppercase; letter-spacing: .06em;
    background: var(--surface); color: var(--text); border: 1px solid var(--line2);
    padding: 8px 12px; cursor: pointer; }
  button:hover { border-color: var(--accent); }
  button.primary { background: var(--accent); color: #0A0A0A; border-color: var(--accent); }
  button.primary:hover { background: var(--accent-hover); }
  button.on { border-color: var(--accent); color: var(--accent); }
  main { display: grid; grid-template-columns: 1fr 280px; gap: 0; min-height: 0; }
  .stage { display: grid; place-items: center; padding: 20px; min-height: 0; position: relative; }
  video { max-width: 100%; max-height: calc(100vh - 290px); background: #000;
    box-shadow: 0 30px 80px rgba(0,0,0,.6); outline: 1px solid var(--line2); }
  .empty { color: var(--text2); text-align: center; }
  aside { border-left: 1px solid var(--line2); background: var(--deep); padding: 16px;
    overflow: auto; display: flex; flex-direction: column; gap: 18px; }
  aside h2 { margin: 0 0 8px; font: 600 11px 'JetBrains Mono', monospace; color: var(--text2);
    text-transform: uppercase; letter-spacing: .1em; }
  .stills { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  .stills a { display: block; border: 1px solid var(--line2); }
  .stills a:hover { border-color: var(--accent); }
  .stills img { width: 100%; display: block; }
  .stills span { display: block; font: 400 11px 'JetBrains Mono', monospace; color: var(--text2); padding: 4px 6px; }
  .log { font: 400 11px/1.5 'JetBrains Mono', monospace; color: var(--text2); white-space: pre-wrap;
    word-break: break-word; max-height: 220px; overflow: auto; }
  .keys { font: 400 12px 'JetBrains Mono', monospace; color: var(--text2); display: grid;
    grid-template-columns: auto 1fr; gap: 4px 12px; }
  .keys b { color: var(--text); font-weight: 600; }
  footer { border-top: 1px solid var(--line2); background: var(--deep); padding: 12px 20px 18px; }
  .transport { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
  .time { font: 600 20px 'JetBrains Mono', monospace; min-width: 132px; }
  .time small { font-size: 12px; color: var(--text2); font-weight: 400; }
  .spacer { flex: 1; }
  .timeline { position: relative; height: 92px; background: var(--surface);
    border: 1px solid var(--line2); cursor: pointer; user-select: none; touch-action: none; }
  .scene { position: absolute; top: 34px; height: 30px; border-right: 1px solid var(--bg);
    padding: 6px 8px; font: 600 11px 'JetBrains Mono', monospace; overflow: hidden; white-space: nowrap;
    color: var(--text); background: #171717; }
  .scene:nth-child(even) { background: #1F1F1F; }
  .overlap { position: absolute; top: 34px; height: 30px; z-index: 1; pointer-events: none;
    background: repeating-linear-gradient(135deg, rgba(255,107,0,.35) 0 4px, transparent 4px 8px); }
  .word { position: absolute; top: 6px; font: 600 11px Outfit, sans-serif; color: var(--accent);
    border-left: 2px solid var(--accent); padding-left: 4px; white-space: nowrap;
    max-width: 92px; overflow: hidden; text-overflow: ellipsis; }
  .cue { position: absolute; bottom: 6px; width: 2px; height: 14px; background: var(--text2); }
  .cue[data-s="whoosh"] { background: #8AB4FF; height: 18px; }
  .cue[data-s="tap"] { background: var(--ok); }
  .cue[data-s="chime"], .cue[data-s="rise"] { background: var(--warn); }
  .head { position: absolute; top: 0; bottom: 0; width: 2px; background: var(--text);
    box-shadow: 0 0 0 1px rgba(0,0,0,.5); pointer-events: none; }
  .hover { position: absolute; top: -22px; font: 400 11px 'JetBrains Mono', monospace; color: var(--text2);
    transform: translateX(-50%); pointer-events: none; display: none; }
  .ticks { position: absolute; left: 0; right: 0; top: 66px; height: 24px; pointer-events: none; }
  .ticks i { position: absolute; top: 0; font: 400 10px 'JetBrains Mono', monospace; color: var(--muted);
    border-left: 1px solid var(--line2); padding-left: 3px; height: 100%; font-style: normal; }
  .toast { position: fixed; bottom: 140px; left: 50%; transform: translateX(-50%);
    background: var(--text); color: var(--bg); padding: 8px 14px; font: 600 12px 'JetBrains Mono', monospace;
    opacity: 0; transition: opacity .2s; pointer-events: none; }
  .toast.show { opacity: 1; }
  @media (max-width: 760px) {
    main { grid-template-columns: 1fr; }
    aside { border-left: 0; border-top: 1px solid var(--line2); }
    video { max-height: 60vh; }
  }
</style>
</head>
<body>
<header>
  <div class="brand">Blaq<b>Reel</b> Studio</div>
  <span class="tag" id="reelName">—</span>
  <span class="tag" id="formatName">—</span>
  <div class="status"><span class="dot" id="dot"></span><span class="mono" id="status">Starting</span></div>
  <button id="renderBtn" title="R">Re-render</button>
  <button class="primary" id="stillBtn" title="S">Still at playhead</button>
</header>
<main>
  <div class="stage" id="stage">
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
        <b>R</b><span>Re-render</span>
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
<div class="toast" id="toast"></div>
<script>
const $ = (id) => document.getElementById(id);
const video = $('video');
let reel = null, version = -1, fps = 30, loop = false;

function toast(text) {
  const t = $('toast'); t.textContent = text; t.classList.add('show');
  clearTimeout(toast.h); toast.h = setTimeout(() => t.classList.remove('show'), 1600);
}
const fmt = (s) => s.toFixed(2) + 's';
const frameOf = (s) => Math.round(s * fps);

function drawTimeline() {
  if (!reel) return;
  const L = reel.length, lanes = $('lanes'), ticks = $('ticks');
  lanes.innerHTML = ''; ticks.innerHTML = '';
  const pct = (s) => (100 * s / L) + '%';
  let wordIndex = 0;
  reel.scenes.forEach((sc, i) => {
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
      m.style.top = (wordIndex++ % 2 ? 18 : 4) + 'px'; m.title = `${w.text} @ ${fmt(w.at)}`;
      lanes.appendChild(m);
    });
  });
  reel.cues.forEach((c) => {
    const m = document.createElement('div');
    m.className = 'cue'; m.dataset.s = c.sound; m.style.left = pct(c.at);
    m.title = `${c.sound} @ ${fmt(c.at)}`;
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
  if (reel) {
    const s = video.currentTime;
    $('head').style.left = (100 * s / reel.length) + '%';
    $('time').innerHTML = `${fmt(s)} <small>frame ${frameOf(s)} / ${frameOf(reel.length)}</small>`;
    if (loop && !video.paused) {
      const sc = sceneAt(s);
      if (sc && s >= sc.end - 0.02) video.currentTime = sc.start;
    }
  }
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);

function seek(s) {
  if (!reel) return;
  video.currentTime = Math.max(0, Math.min(reel.length - 1 / fps, s));
}
function stepFrames(n) { video.pause(); seek(Math.round(video.currentTime * fps + n) / fps); }

const tl = $('timeline');
function timeFromEvent(e) {
  const r = tl.getBoundingClientRect();
  return Math.max(0, Math.min(1, (e.clientX - r.left) / r.width)) * (reel ? reel.length : 0);
}
let dragging = false;
tl.addEventListener('pointerdown', (e) => { dragging = true; tl.setPointerCapture(e.pointerId); video.pause(); seek(timeFromEvent(e)); });
tl.addEventListener('pointermove', (e) => {
  const h = $('hover'), s = timeFromEvent(e);
  h.style.display = 'block'; h.style.left = (100 * s / (reel ? reel.length : 1)) + '%'; h.textContent = fmt(s);
  if (dragging) seek(s);
});
tl.addEventListener('pointerup', () => { dragging = false; });
tl.addEventListener('pointerleave', () => { $('hover').style.display = 'none'; });

$('play').onclick = () => (video.paused ? video.play() : video.pause());
video.onplay = () => ($('play').textContent = 'Pause');
video.onpause = () => ($('play').textContent = 'Play');
$('back').onclick = () => stepFrames(-1);
$('fwd').onclick = () => stepFrames(1);
$('prev').onclick = () => { const sc = sceneAt(video.currentTime - 0.05); const i = reel.scenes.indexOf(sc); seek(video.currentTime - sc.start > 0.3 ? sc.start : (reel.scenes[Math.max(0, i - 1)].start)); };
$('next').onclick = () => { const sc = sceneAt(video.currentTime); const i = reel.scenes.indexOf(sc); if (reel.scenes[i + 1]) seek(reel.scenes[i + 1].start); };
document.querySelectorAll('[data-rate]').forEach((b) => b.onclick = () => {
  video.playbackRate = +b.dataset.rate;
  document.querySelectorAll('[data-rate]').forEach((x) => x.classList.toggle('on', x === b));
});
$('loop').onclick = () => { loop = !loop; $('loop').classList.toggle('on', loop); };
$('mute').onclick = () => { video.muted = !video.muted; $('mute').textContent = video.muted ? 'Sound off' : 'Sound on'; };
$('renderBtn').onclick = () => fetch('/api/render', { method: 'POST' }).then(() => toast('Re-rendering'));

async function still() {
  const s = +video.currentTime.toFixed(2);
  toast(`Rendering a still at ${fmt(s)}…`);
  const r = await fetch('/api/still?t=' + s, { method: 'POST' }).then((x) => x.json());
  if (!r.ok) return toast('Still failed — see the log');
  const box = $('stills');
  if (!box.querySelector('a')) box.innerHTML = '';
  const a = document.createElement('a');
  a.href = r.url + '?v=' + Date.now(); a.target = '_blank'; a.title = r.path;
  a.innerHTML = `<img src="${a.href}" alt="Still at ${fmt(s)}"><span>${fmt(s)} · frame ${frameOf(s)}</span>`;
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
    const text = `${reel.name} @ ${fmt(video.currentTime)} (frame ${frameOf(video.currentTime)})`;
    navigator.clipboard?.writeText(text); toast('Copied: ' + text);
  }
});

async function poll() {
  try {
    const st = await fetch('/api/state').then((r) => r.json());
    const dot = $('dot');
    dot.className = 'dot' + (st.rendering ? ' busy' : st.status.startsWith('Render failed') ? ' bad' : '');
    $('status').textContent = st.status;
    $('log').textContent = st.log.length ? st.log.join('\n') : '—';
    if (st.reel && st.version !== version) {
      const at = video.currentTime || 0, playing = !video.paused;
      version = st.version; reel = st.reel; fps = reel.fps;
      $('reelName').textContent = reel.name + ' · ' + fmt(reel.length);
      $('formatName').textContent = `${reel.format} ${reel.width}×${reel.height} · ${fps} fps`;
      video.src = `/files/${reel.video}?v=${version}`;
      video.hidden = false; $('empty').hidden = true;
      video.addEventListener('loadedmetadata', () => { seek(at); if (playing) video.play(); }, { once: true });
      drawTimeline();
      if (version > 0) toast('Preview updated');
    }
  } catch (e) { $('status').textContent = 'Studio stopped'; $('dot').className = 'dot bad'; }
  setTimeout(poll, 1000);
}
poll();
</script>
</body>
</html>
''';
