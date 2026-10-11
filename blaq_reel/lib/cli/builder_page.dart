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
/* The steps, the reel and New reel run across the top, so the canvas has
   the width. */
#build { display: none; grid-template-columns: minmax(0, 1fr) 300px; grid-template-rows: minmax(0, 1fr); min-height: 0; }
body.building #build { display: grid; }
#build aside { overflow: auto; padding: 16px 14px; background: var(--deep); }
/* The builder's reel and steps live in the studio's header while building. */
#buildNav { display: flex; align-items: center; gap: 10px; flex: 1 1 auto; min-width: 0; padding-left: 12px; border-left: 1px solid var(--line2); }
body:not(.building) #buildNav { display: none; }
#buildNav .field { display: flex; align-items: center; gap: 8px; margin: 0; flex: none; }
#buildNav #specPick { width: 150px; padding: 5px 8px; }
#buildNav .field > label { display: none; }
body.building header .status span:last-child { display: none; }
#buildNav #newSpec { width: auto !important; white-space: nowrap; flex: none; }
#buildNav .steps { min-width: 0; flex: 0 1 auto; }
#build aside { border-left: 1px solid var(--line2); display: flex; flex-direction: column; gap: 14px; }
.canvas { overflow: auto; padding: 22px 26px 40px; min-width: 0; }
.canvas h1 { font-weight: 900; text-transform: uppercase; letter-spacing: -0.02em; font-size: 30px; margin: 0 0 6px; }
.canvas .why { color: var(--text2); margin: 0 0 20px; max-width: 70ch; }
.steps { display: flex; gap: 0; margin-left: auto; flex: none; }
.step { all: unset; display: flex; gap: 7px; align-items: center; padding: 7px 10px; white-space: nowrap; flex: none;
  border-bottom: 2px solid transparent; cursor: pointer; font-weight: 600; font-size: 13px; }
.step:hover { background: var(--surface); }
.step:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.step .k { font: 600 11px var(--mono); color: var(--text2); }
.step.on { border-bottom-color: var(--accent); }
.step.on .k { color: var(--accent); }
.step.done .k { color: var(--ok); }
.step small { display: none; }
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
.scr .pic { aspect-ratio: 9 / 16; display: grid; place-items: center; padding: 14px; border: 1px solid var(--line2);
  background: radial-gradient(circle at 50% 40%, #2A2622, #121212 70%); }
.scr .pic img { border: 0; max-height: 100%; object-fit: contain; filter: drop-shadow(0 6px 14px rgba(0,0,0,.45)); }
.scr .sub { font: 400 11px var(--mono); color: var(--text2); text-transform: uppercase; letter-spacing: .08em; }
.sect { font: 600 11px var(--mono); text-transform: uppercase; letter-spacing: .12em; color: var(--text2); margin: 22px 0 10px; }
.comp-note { border-left: 2px solid var(--warn); padding: 6px 10px; color: var(--text2); font-size: 13px; margin-top: 10px; }
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
/* The Parts step fits the window: nothing scrolls the page; what is long
   (the parts list, the timeline) scrolls inside itself. */
.canvas.fixed { overflow: hidden; display: flex; flex-direction: column; padding: 10px 12px; }
.canvas.fixed > * { flex: none; }
.canvas.fixed > .grow { flex: 1 1 auto; min-height: 0; }
.canvas.fixed .pmode { margin-bottom: 10px; }
.canvas.fixed .why { margin-bottom: 12px; }
.canvas.fixed .picker { grid-template-columns: auto minmax(0, 1fr); grid-template-rows: minmax(0, 1fr); align-items: stretch; }
.canvas.fixed .shot2 { height: 100%; aspect-ratio: 393 / 852; max-width: 46vw; justify-self: start; }
.canvas.fixed .shot2 img { width: 100%; height: 100%; object-fit: contain; }
.canvas.fixed .picker > div:last-child { overflow: auto; min-height: 0; padding-right: 4px; }
.canvas.fixed .tled { height: auto; min-height: 0; }
.canvas.fixed .tl-time { max-height: 32vh; }
/* One row on top: every beat (scrolling sideways if there are many), the
   Pick/Animate switch, and the way on. */
.beatbar { display: flex; gap: 8px; align-items: center; margin-bottom: 10px; }
.beatbar > * { flex: none; }
.beatbar .bnav { padding: 6px 11px; font-size: 14px; line-height: 1; }
.beatbar .beatSel { width: 260px; padding: 6px 8px; }
.beatbar > .seg { margin-left: 8px; }
body.fab-on .canvas.fixed { padding-bottom: 10px; }
.prow { all: unset; display: grid; grid-template-columns: 36px minmax(0,1fr) 22px; gap: 8px; align-items: center; padding: 8px 10px;
  border: 1px solid var(--line2); background: var(--surface); cursor: pointer; }
.prow.on { border-color: var(--ok); }
.prow .n { font: 600 12px var(--mono); color: var(--accent); }
.prow.on .n { color: var(--ok); }
.prow b { font-weight: 600; font-size: 13px; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.prow span { color: var(--text2); font-size: 12px; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.prow .o { font: 600 11px var(--mono); color: var(--ok); }
.moves { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px; margin-top: 22px; }
.mv { all: unset; cursor: pointer; display: grid; gap: 6px; padding: 10px; border: 1px solid var(--line2); background: var(--surface); }
.mv:hover { border-color: var(--text2); }
.mv.on { border-color: var(--accent); }
.mv b { font-weight: 600; font-size: 13px; }
.mv.on b { color: var(--accent); }
.mv span { font-size: 11.5px; color: var(--text2); line-height: 1.35; }
.mv .mvst { height: 96px; display: grid; place-items: center; background: radial-gradient(circle at 50% 40%, #241F1A, #101010 75%); perspective: 260px; overflow: hidden; }
.mv .mvph { position: relative; width: 44px; height: 84px; border: 1.5px solid #3A3A3A; border-radius: 9px; background: #1B1B1B; transform-style: preserve-3d; }
.mv .mvbar { position: absolute; left: 4px; width: 33px; height: 15px; border-radius: 3px; background: #F2F2F2; box-shadow: 0 2px 6px rgba(0,0,0,.35);
  --x: 0px; --y: 0px; --r: 0deg; --s: 1; --d: 0s; animation: mvgo 2.6s var(--ease, cubic-bezier(.45,0,.25,1)) var(--d) infinite; }
.mv .mvbar:nth-child(1) { top: 9px; background: #FFD97A; }
.mv .mvbar:nth-child(2) { top: 34px; }
.mv .mvbar:nth-child(3) { top: 59px; }
@keyframes mvgo { 0%, 12% { transform: none; } 40%, 82% { transform: translate(var(--x), var(--y)) rotate(var(--r)) scale(var(--s)); } 100% { transform: none; } }
.mv-lift .mvbar, .mv-orbit .mvbar, .mv-tap .mvbar { --s: 1.14; --y: -3px; }
.mv-lift .mvbar:nth-child(2), .mv-orbit .mvbar:nth-child(2) { --d: .12s; } .mv-lift .mvbar:nth-child(3), .mv-orbit .mvbar:nth-child(3) { --d: .24s; }
.mv-sweep .mvbar:nth-child(1) { --s: 1.45; --y: 4px; z-index: 2; } .mv-sweep .mvbar { --s: 1.08; }
.mv-sweep .mvbar:nth-child(1)::after { content: ''; position: absolute; left: 0; right: 0; height: 2px; background: var(--accent); box-shadow: 0 0 6px var(--accent); animation: mvscan 2.6s linear infinite; }
@keyframes mvscan { 0%, 35% { top: 0; opacity: 0; } 40% { opacity: 1; } 75% { top: 100%; opacity: 1; } 80%, 100% { top: 100%; opacity: 0; } }
.mv-spread .mvbar:nth-child(1) { --x: -24px; --y: -6px; --r: -9deg; } .mv-spread .mvbar:nth-child(2) { --x: 25px; --r: 9deg; --d: .1s; } .mv-spread .mvbar:nth-child(3) { --x: -22px; --y: 8px; --r: -7deg; --d: .2s; }
.mv-fan .mvbar:nth-child(1) { --x: -9px; --y: 27px; --r: -14deg; } .mv-fan .mvbar:nth-child(2) { --y: 6px; --s: 1.05; --d: .1s; z-index: 2; } .mv-fan .mvbar:nth-child(3) { --x: 9px; --y: -16px; --r: 14deg; --d: .2s; z-index: 3; }
.mv-zoom .mvbar:nth-child(1) { --y: 24px; --s: 1.9; z-index: 2; } .mv-zoom .mvph { animation: mvdim 2.6s ease infinite; }
@keyframes mvdim { 0%, 15%, 100% { opacity: 1; } 40%, 82% { opacity: .55; } }
.mv-tap .mvbar { --d: .55s; }
.mv-tap .mvph::after { content: ''; position: absolute; width: 14px; height: 14px; border-radius: 50%; background: rgba(255,255,255,.85); left: 15px; top: 10px; animation: mvtap 2.6s ease infinite; }
@keyframes mvtap { 0%, 4% { opacity: 0; transform: translate(10px, 14px) scale(1.3); } 14% { opacity: 1; transform: none; } 20% { transform: scale(.8); } 28%, 100% { opacity: 0; transform: scale(1.4); } }
.mv-pop .mvbar { --s: 1.16; --y: -3px; --ease: cubic-bezier(.34, 1.56, .64, 1); }
.mv-pop .mvbar:nth-child(2) { --d: .3s; } .mv-pop .mvbar:nth-child(3) { --d: .6s; }
.mv-orbit .mvph { animation: mvorbit 2.6s ease-in-out infinite alternate; }
@keyframes mvorbit { from { transform: rotateY(-38deg); } to { transform: rotateY(38deg); } }
@media (prefers-reduced-motion: reduce) { .mv * , .mv *::after { animation: none !important; } }
.seg { display: inline-flex; border: 1px solid var(--line2); }
.seg button { border: 0; border-right: 1px solid var(--line2); }
.seg button:last-child { border-right: 0; }
.seg button.on { background: var(--accent); color: #0A0A0A; }
.story { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 12px; }
.sb { display: grid; gap: 8px; padding: 10px; border: 1px solid var(--line2); background: var(--surface); align-content: start; }
.sb img { width: 100%; display: block; border: 1px solid var(--line2); max-height: 260px; object-fit: cover; object-position: top; }
.sb .pic { height: 260px; display: grid; place-items: center; padding: 18px; border: 1px solid var(--line2);
  background: radial-gradient(circle at 50% 40%, #2A2622, #121212 70%); }
.sb .pic img { border: 0; object-fit: contain; max-height: 100%; }
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
#agentFab { position: fixed; right: 16px; bottom: calc(var(--fab-bottom, 16px) + env(safe-area-inset-bottom, 0px)); z-index: 16;
  display: inline-flex; align-items: center; gap: 8px; padding: 10px 14px; background: var(--deep); color: var(--text);
  border: 1px solid var(--line2); box-shadow: 0 10px 30px rgba(0,0,0,.5); font: 600 12px var(--mono); text-transform: uppercase; letter-spacing: .06em; }
#agentFab[hidden] { display: none; }
/* Room under every scrolling column, so its last item scrolls clear of the
   floating button instead of sitting under it. */
body.fab-on aside, body.fab-on .canvas, body.fab-on #build aside { padding-bottom: 88px; }
#agentFab .mk { color: var(--accent); font-size: 15px; line-height: 1; }
#agentFab .badge:empty { display: none; }
#agentFab .badge { font-size: 12px; }
#agentFab.ok .badge { color: var(--ok); }
#agentFab.failed .badge { color: var(--bad); }
#agentFab.running { border-color: var(--accent); animation: glow 1.6s ease-in-out infinite; }
#agentFab.running .mk { animation: spin 3s linear infinite; display: inline-block; }
#agentFab[aria-expanded="true"] { border-color: var(--accent); }
@keyframes glow { 0%, 100% { box-shadow: 0 0 0 0 rgba(255,107,0,.0), 0 10px 30px rgba(0,0,0,.5); }
  50% { box-shadow: 0 0 22px 4px rgba(255,107,0,.45), 0 10px 30px rgba(0,0,0,.5); } }
@keyframes spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { #agentFab.running, #agentFab.running .mk { animation: none; } }
#agent { position: fixed; right: 16px; bottom: calc(var(--fab-bottom, 16px) + 54px + env(safe-area-inset-bottom, 0px)); width: min(440px, calc(100vw - 32px));
  z-index: 15; background: var(--deep); border: 1px solid var(--line2); box-shadow: 0 20px 60px rgba(0,0,0,.6);
  display: flex; flex-direction: column; max-height: min(640px, calc(100vh - var(--fab-bottom, 16px) - 54px - 24px)); overflow: hidden; }
#agent[hidden] { display: none; }
#agent.running { border-color: var(--accent); }
#agent.failed { border-color: var(--bad); }
#agent .ah { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-bottom: 1px solid var(--line2); flex: none; }
#agent .ah .who { font: 600 10px var(--mono); letter-spacing: .1em; text-transform: uppercase; color: var(--accent); flex: none; }
#agent .ah b { font-weight: 600; flex: 1; min-width: 0; overflow-wrap: anywhere; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
#agent .ah .t { font: 400 11px var(--mono); color: var(--text2); flex: none; }
#agent .ah button { padding: 3px 8px; font-size: 11px; flex: none; }
#agent .chat { overflow-y: auto; overflow-x: hidden; padding: 12px; display: flex; flex-direction: column; gap: 6px; min-height: 0; flex: 1 1 auto; overscroll-behavior: contain; }
#agent .st { display: grid; grid-template-columns: 58px minmax(0, 1fr); gap: 8px; font: 400 12px/1.45 var(--mono); color: var(--text2); }
#agent .st span { overflow-wrap: anywhere; min-width: 0; }
#agent .st i { font-style: normal; color: var(--muted); }
#agent .st.edit span { color: var(--accent); }
#agent .st.run span { color: var(--warn); }
#agent .st.note span { color: var(--ok); }
#agent .msg { background: var(--surface); border: 1px solid var(--line2); border-left: 2px solid var(--accent); padding: 10px 12px; margin-block: 4px;
  font-size: 13.5px; line-height: 1.5; color: var(--text); overflow-wrap: anywhere; min-width: 0; }
#agent .msg p { margin: 0 0 8px; } #agent .msg p:last-child { margin: 0; }
#agent .msg ul { margin: 0 0 8px; padding-left: 18px; } #agent .msg li { margin-bottom: 4px; }
#agent .msg code { font: 400 12px var(--mono); background: var(--deep); border: 1px solid var(--line2); padding: 0 4px; }
#agent .msg.err { border-left-color: var(--bad); color: var(--bad); white-space: pre-wrap; }
#agent .msg .when { display: block; font: 400 10px var(--mono); color: var(--muted); margin-bottom: 6px; letter-spacing: .08em; text-transform: uppercase; }
#agent .files { display: flex; flex-wrap: wrap; gap: 4px; align-items: center; font: 400 11px var(--mono); color: var(--text2); }
#agent .files code { font: 400 11px var(--mono); border: 1px solid var(--line2); padding: 2px 6px; color: var(--text); overflow-wrap: anywhere; }
#agent .af { border-top: 1px solid var(--line2); padding: 8px 12px; flex: none; }
#agent .sess { display: flex; gap: 8px; align-items: center; font: 400 11px var(--mono); color: var(--text2); }
#agent .sess code { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
#agent .sess button { padding: 5px 9px; font-size: 10px; flex: none; }
.pulse { width: 8px; height: 8px; background: var(--accent); animation: pulse 1s infinite; flex: none; }
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
@media (max-width: 1100px) { #build { grid-template-columns: minmax(0, 1fr); } #build aside { display: none; } }
@media (max-width: 760px) { #build { grid-template-columns: 1fr; } .picker { grid-template-columns: 1fr; } .moves { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
''';

/// The builder's markup.
const builderHtml = r'''
<button id="agentFab" hidden aria-haspopup="dialog" aria-expanded="false"><span class="mk">✳</span><span class="lb">Claude Code</span><span class="badge"></span></button>
<aside id="agent" hidden aria-live="polite" aria-label="Claude Code"></aside>
<div id="build">
  <nav id="buildNav">
    <div class="field"><label for="specPick">Reel</label>
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
// How a beat's parts leave its screen (Glass Layers and Story Ad).
const MOVES = [
  ['lift', 'Lift', 'Straight up off the screen.'],
  ['sweep', 'Lift + scan', 'Up, with a scan line reading the first.'],
  ['spread', 'Spread', 'Pulled apart round the phone, past its sides.'],
  ['fan', 'Fan', 'Gathered in the middle, fanned like cards.'],
  ['zoom', 'Zoom in', 'The first comes forward, large; the rest dims.'],
  ['tap', 'Tap', 'A finger picks the first, then they lift.'],
  ['pop', 'Pop', 'One by one, each with a spring.'],
  ['orbit', 'Orbit', 'They lift while the camera circles the phone.'],
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
const partsMode = {};   // each beat's Parts mode: 'pick' or 'animate'
let spec = null, step = 'screens', beatIndex = 0, catalogue = null, saving = null, groundShots = null;
const B = (html) => { const t = document.createElement('template'); t.innerHTML = html.trim(); return t.content.firstElementChild; };
const escB = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function blank(name) {
  return { name, pack: 'glass', format: 'vertical', look: 'mesh', music: null, open: 'mark', storyBy: 'words',
    brief: '', beats: [], end: { logo: 'wordmark', line: '' } };
}
// A spec written by hand may leave out what the builder always writes.
function whole(sp) {
  sp.beats = (sp.beats || []).map((b) => ({ ...b, parts: b.parts || [], word: b.word ?? '', line: b.line ?? '' }));
  return sp;
}
function screenOf(id) { return catalogue && catalogue.screens.find((s) => s.id === id); }
// A piece of the app on its own (a button, a card), not a whole screen.
function isComp(id) { const s = screenOf(id); return !!s && s.kind === 'component'; }

// ── Claude Code, live ───────────────────────────────────────────────
// Every headless Claude Code run the studio starts (drafts, inventory,
// staging) shows here as it happens: its steps, the files it changed, and
// the command that reopens the session in a terminal.
let agentOpen = false, agentSeen = null, agentLast = null;
function ago2(iso) { const s = Math.max(0, (Date.now() - new Date(iso)) / 1000); return s < 60 ? Math.round(s) + 's' : Math.floor(s / 60) + 'm ' + Math.round(s % 60) + 's'; }
// Claude's answer, lightly: paragraphs, "- " lists, `code` and **bold**.
function mdLite(text) {
  const inline = (t) => escB(t).replace(/`([^`]+)`/g, '<code>$1</code>').replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
  return text.trim().split(/\n{2,}/).map((block) => {
    const lines = block.split('\n');
    if (lines.every((l) => /^\s*[-*] /.test(l))) return `<ul>${lines.map((l) => `<li>${inline(l.replace(/^\s*[-*] /, ''))}</li>`).join('')}</ul>`;
    return `<p>${lines.map(inline).join('<br>')}</p>`;
  }).join('');
}
// The floating button sits above the Library's transport bar, or at the
// foot of the page in the builder.
function placeFab() {
  const footer = document.querySelector('footer');
  const lift = document.body.classList.contains('building') || !footer ? 16 : footer.offsetHeight + 16;
  document.body.style.setProperty('--fab-bottom', lift + 'px');
}
window.addEventListener('resize', placeFab);
$('agentFab').onclick = () => { agentOpen = !agentOpen; window.onStudioState({ agent: agentLast }); };
document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && agentOpen) { agentOpen = false; window.onStudioState({ agent: agentLast }); } });
window.onStudioState = (st) => {
  const a = st.agent, fab = $('agentFab'), box = $('agent');
  agentLast = a;
  placeFab();
  document.body.classList.toggle('fab-on', !!a);
  if (!a) { fab.hidden = true; box.hidden = true; return; }
  // A new run opens the panel once, so its start is seen; after that it is
  // the person's to open and close.
  if (agentSeen !== a.started) { agentSeen = a.started; if (!a.done) agentOpen = true; }
  fab.hidden = false;
  fab.className = a.done ? (a.ok ? 'ok' : 'failed') : 'running';
  fab.querySelector('.badge').textContent = a.done ? (a.ok ? '✓' : '✕') : '';
  fab.querySelector('.lb').textContent = a.done ? 'Claude Code' : 'Claude is working';
  fab.setAttribute('aria-expanded', String(agentOpen));
  fab.title = a.task;
  box.hidden = !agentOpen;
  if (!agentOpen) return;
  box.className = a.done ? (a.ok ? '' : 'failed') : 'running';
  // Built once per run and then only added to, so a scroll the person made
  // stays where they left it; it follows new lines only from the bottom.
  if (box.dataset.run !== a.started) {
    box.dataset.run = a.started; box.dataset.key = '';
    box.innerHTML = `<div class="ah"><span class="who">Claude Code</span><b></b><span class="t"></span>
        <button id="agClose" title="Close (Esc)" aria-label="Close">✕</button></div>
      <div class="chat"></div><div class="af" hidden></div>`;
    box.querySelector('#agClose').onclick = () => { agentOpen = false; window.onStudioState({ agent: agentLast }); };
  }
  const head = box.querySelector('.ah b');
  head.textContent = a.task; head.title = a.task;
  box.querySelector('.ah .t').textContent = a.done ? (a.ok ? 'done' : 'failed') : ago2(a.started);
  const key = [a.steps.length, a.done, a.files.length, a.error, a.sessionId].join('|');
  if (box.dataset.key === key) return;
  box.dataset.key = key;
  const chat = box.querySelector('.chat');
  const atBottom = chat.scrollHeight - chat.scrollTop - chat.clientHeight < 40;
  const top = chat.scrollTop;
  const time = (iso) => new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
  const answer = a.done && a.ok && a.result && !/^[\[{]/.test(a.result) ? a.result : '';
  const steps = a.steps.filter((x) => !/^[\[{]/.test(x.text)
    // The answer's first line also arrives as a step; say it once.
    && !(answer && x.kind === 'say' && answer.startsWith(x.text.replace(/…$/, ''))));
  chat.innerHTML = (steps.length ? steps.map((x) => x.kind === 'say'
      ? `<div class="msg"><span class="when">${time(x.at)}</span>${escB(x.text)}</div>`
      : `<div class="st ${x.kind}"><i>${time(x.at)}</i><span>${escB(x.text)}</span></div>`).join('')
    : '<div class="st"><i></i><span>Starting a session…</span></div>')
    + (a.files.length ? `<div class="files">Changed ${a.files.map((f) => `<code>${escB(f)}</code>`).join('')}</div>` : '')
    + (answer ? `<div class="msg"><span class="when">Answer</span>${mdLite(answer)}</div>` : '')
    + (a.error ? `<div class="msg err">${escB(a.error)}</div>` : '');
  chat.scrollTop = atBottom ? chat.scrollHeight : top;
  const foot = box.querySelector('.af');
  foot.hidden = !a.sessionId;
  foot.innerHTML = a.sessionId ? `<div class="sess"><code title="${escB(a.resume)}">session ${escB(a.sessionId)}</code><button id="agCopy">Copy resume command</button></div>` : '';
  const cp = box.querySelector('#agCopy');
  if (cp) cp.onclick = async () => { try { await navigator.clipboard.writeText(a.resume); toast('Copied: ' + a.resume); } catch { toast(a.resume); } };
};

// ── Tabs ────────────────────────────────────────────────────────────
function setTab(build) {
  document.body.classList.toggle('building', build);
  // The builder's reel and steps sit in the header, after the tabs.
  const nav = $('buildNav');
  if (build && nav.parentElement.tagName !== 'HEADER') document.querySelector('header .tabs').after(nav);
  requestAnimationFrame(placeFab);
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
  // The reel worked on last, else the one changed most recently.
  let last = null; try { last = localStorage.getItem('blaqreel-reel'); } catch {}
  const first = specs.find((x) => x.name === last) || specs[0];
  if (!spec && first) { spec = whole({ ...blank(first.name), ...first.spec, name: first.name }); }
  if (spec) pick.value = spec.name;
  if (!spec) { newSpec(); return; }
  draw();
}
$('specPick').onchange = async (e) => {
  const name = e.target.value; if (!name) return;
  const s = await fetch('/api/spec?name=' + encodeURIComponent(name)).then((r) => r.json());
  spec = whole({ ...blank(name), ...s, name }); step = 'screens';
  try { localStorage.setItem('blaqreel-reel', name); } catch {} beatIndex = 0; groundShots = null; draw();
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
  try { localStorage.setItem('blaqreel-reel', spec.name); } catch {}
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
  return { brief: !!spec.pack, screens: spec.beats.length > 0, parts: spec.beats.length > 0 && spec.beats.every((b) => b.parts.length || isComp(b.screen)),
    story: spec.beats.length > 0 && spec.beats.every((b) => (b.word || b.line)), ground: !!spec.look, preview: false }[id];
}
function draw() {
  stopAnimator();
  $('steps').innerHTML = '';
  STEPS.forEach((s, i) => {
    const b = B(`<button class="step${s.id === step ? ' on' : ''}${done(s.id) ? ' done' : ''}" title="${escB(s.sub)}"><span class="k">${done(s.id) ? '✓' : i + 1}</span>${s.name}<small>${s.sub}</small></button>`);
    b.onclick = () => { step = s.id; draw(); };
    $('steps').appendChild(b);
  });
  const c = $('canvas'), side = $('side'); c.innerHTML = ''; side.innerHTML = ''; c.className = 'canvas';
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
      <div class="t"><b><span class="n">${i + 1}</span> ${escB(b.word || b.line || (s ? s.label : b.screen))}</b><span>${escB(s ? s.label : b.screen)} · ${isComp(b.screen) ? 'component' : `${b.parts.length} part${b.parts.length === 1 ? '' : 's'}${b.parts.length && b.move && b.move !== 'lift' ? ' · ' + (MOVES.find((m) => m[0] === b.move) || [, b.move])[1].toLowerCase() : ''}`}</span></div>
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
  if (spec.beats.some((b) => isComp(b.screen)) && (spec.pack === 'kinetic' || spec.pack === 'glow')) {
    packs.appendChild(B(`<div class="comp-note">${spec.pack === 'glow' ? 'Dark Glow leaves components out: its camera travels past screens.' : 'Kinetic Launch shows a component\'s beat as its line alone.'} Glass Layers and Story Ad show them large, on their own.</div>`));
  }
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
  [['all', 'The AI, all of it', 'It picks the parts, the moves and the words for your screens (and the screens too, if you have not chosen any). You review and change anything.'],
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
  const add = B('<div class="row2" style="margin-bottom:16px"><button class="primary">+ Add from the app</button><span class="hint">Every screen, sheet, dialog and component in the app, by name. Pick some and the AI stages them here.</span></div>');
  add.querySelector('button').onclick = () => openPicker();
  c.appendChild(add);
  const lazy = B('<div class="ai" style="margin-bottom:18px"><b>Not sure which?</b><span>Describe the reel and let the AI choose the screens, the parts and the words. You can change all of it after.</span><button>Let the AI choose →</button></div>');
  lazy.querySelector('button').onclick = () => change(() => { spec.storyBy = 'all'; step = 'brief'; });
  c.appendChild(lazy);
  if (!catalogue) { c.appendChild(B('<p class="hint">Drawing the app\'s screens… this takes a minute the first time.</p>')); setTimeout(async () => { catalogue = await fetch('/api/catalogue').then((r) => r.json()); if (step === 'screens') draw(); }, 5000); return; }
  // Screens first, then the pieces of the app shown on their own.
  [['screen', 'Screens'], ['component', 'Components · shown on their own, no phone']].forEach(([kind, title]) => {
    const list = catalogue.screens.filter((s) => (s.kind || 'screen') === kind);
    if (!list.length) return;
    c.appendChild(B(`<div class="sect">${title}</div>`));
    const grid = B('<div class="screens"></div>');
    list.forEach((s) => {
      const used = spec.beats.filter((b) => b.screen === s.id).length;
      const img = `<img src="/catalogue/${s.image}" alt="${escB(s.label)}" loading="lazy">`;
      const b = B(`<button class="scr">${kind === 'component' ? `<span class="pic">${img}</span>` : img}<b>${escB(s.label)}</b>${used ? `<span class="count">×${used}</span>` : ''}</button>`);
      b.onclick = () => change(() => spec.beats.push({ screen: s.id, parts: [], word: '', line: '' }));
      grid.appendChild(b);
    });
    c.appendChild(grid);
  });
  c.appendChild(next());
  beatList(side);
}

let inventory = null, staging = false, pickerKind = 'all', pickerSearch = '';
const picked = new Set();

async function openPicker() {
  document.getElementById('picker')?.remove();
  const ov = B(`<div id="picker" class="overlay" role="dialog" aria-label="Add from the app"><div class="panel">
    <div class="ph"><h2 style="font-size:24px">Add from the app</h2><button class="x" aria-label="Close">✕</button></div>
    <p class="hint" id="pTaken"></p>
    <div class="row2"><input class="input" id="pSearch" placeholder="Search screens, sheets, dialogs, components, routes…" style="flex:1;min-width:200px"><div class="seg" id="pKinds"></div></div>
    <div class="plist2" id="pList"><p class="hint">Reading the inventory…</p></div>
    <div class="pfoot">
      <button class="primary" id="pGo" disabled>Generate previews</button>
      <span class="hint" id="pNote"></span>
      <span style="flex:1"></span>
      <input class="input" id="pFind" placeholder="Not here? Describe it: the loading spinner, the sheet that confirms a payment" style="max-width:360px">
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
  [['all', 'All'], ['screen', 'Screens'], ['sheet', 'Sheets'], ['dialog', 'Dialogs'], ['component', 'Components']].forEach(([k, label]) => {
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
    : 'No inventory yet: Read the app to list its screens, sheets, dialogs and components.';
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
  // One slim row: which beat (step through, or jump), and Pick or Animate.
  const prow = B(`<div class="beatbar"><button class="bnav" aria-label="Previous beat" ${beatIndex === 0 ? 'disabled' : ''}>‹</button>
    <select class="input beatSel" aria-label="Beat">${spec.beats.map((b, i) => { const bs = screenOf(b.screen), ready = b.parts.length || isComp(b.screen); return `<option value="${i}" ${i === beatIndex ? 'selected' : ''}>${i + 1} / ${spec.beats.length} · ${escB(b.word || (bs ? bs.label : b.screen))}${ready ? '' : ' · no parts yet'}</option>`; }).join('')}</select>
    <button class="bnav" aria-label="Next beat" ${beatIndex === spec.beats.length - 1 ? 'disabled' : ''}>›</button></div>`);
  const [prev, nextB] = prow.querySelectorAll('.bnav');
  prev.onclick = () => { beatIndex--; draw(); }; nextB.onclick = () => { beatIndex++; draw(); };
  prow.querySelector('.beatSel').onchange = (e) => { beatIndex = +e.target.value; draw(); };
  c.classList.add('fixed');
  if (!s) { c.appendChild(B('<p class="hint">That screen is not in the catalogue.</p>')); return; }
  if (s.kind === 'component') {
    c.appendChild(B(`<div><h1>Beat ${beatIndex + 1}: ${escB(s.label)}</h1><p class="why"><b>${escB(s.label)}</b> is a piece of the app, so this beat shows it whole: large, on the ground, doing what it does. There is nothing to pick.</p></div>`));
    c.appendChild(B(`<div class="scr" style="max-width:320px;cursor:default"><span class="pic"><img src="/catalogue/${s.image}" alt="${escB(s.label)}"></span></div>`));
    beatList(side, { select: true });
    return;
  }
  // Two jobs: which parts lift (Pick), then how they and the words move
  // (Animate, the timeline editor).
  const mode = partsMode[beatIndex] || (beat.parts.length ? 'animate' : 'pick');
  const head = B(`<div class="seg" role="tablist" aria-label="Pick or animate"><button data-mode="pick" class="${mode === 'pick' ? 'on' : ''}">Pick${beat.parts.length ? ' (' + beat.parts.length + ')' : ''}</button><button data-mode="animate" class="${mode === 'animate' ? 'on' : ''}">Animate</button></div>`);
  head.querySelectorAll('[data-mode]').forEach((b) => (b.onclick = () => { partsMode[beatIndex] = b.dataset.mode; draw(); }));
  prow.appendChild(head);
  if (mode === 'animate') {
    // The beat picker and the switch join the editor's own toolbar.
    c.appendChild(timelineEditor(beat, s, beatIndex, side, [...prow.children])).classList.add('grow');
    if (beatIndex === spec.beats.length - 1) { const on = next('On to the story'); on.style.marginTop = '10px'; c.appendChild(on); }
    return;
  }
  c.appendChild(prow);
  const nb = B('<div class="row2" style="margin-top:12px"></div>');
  c.appendChild(B(`<p class="why" style="margin-top:-4px">Click the parts of <b>${escB(s.label)}</b> to feature, in order: the first rises highest. One to three reads best; up to six lift. Then animate them.</p>`));
  const wrap = B('<div class="picker grow"><div class="shot2"></div><div><div class="plist"></div></div></div>');
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
  const go = B('<button class="primary">Animate them →</button>'); go.onclick = () => { partsMode[beatIndex] = 'animate'; draw(); };
  nb.appendChild(go); c.appendChild(nb);
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
    const card = B(`<div class="sb"><div class="h"><b>Beat ${i + 1}</b><span>${escB(s ? s.label : b.screen)} · ${isComp(b.screen) ? 'component' : `${b.parts.length} part${b.parts.length === 1 ? '' : 's'}`}</span></div>
      ${s ? `${isComp(b.screen) ? `<span class="pic">` : ''}<img src="/catalogue/${s.image}" alt="">${isComp(b.screen) ? '</span>' : ''}` : ''}
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
  const hadScreens = spec.beats.length > 0;
  try {
    const r = await fetch('/api/ai', { method: 'POST', body: JSON.stringify({ spec, brief: spec.brief, all }) }).then((x) => x.json());
    if (!r.ok) { toast(r.error || 'The AI did not answer'); return; }
    const d = r.draft;
    change(() => {
      const valid = (b) => (b.parts || []).filter((p) => p && p.type).map((p) => ({ type: p.type, text: p.text || null }));
      const move = (m) => (MOVES.some(([id]) => id === m) ? m : undefined);
      if (all && Array.isArray(d.beats) && hadScreens) {
        // The screens are the person's: keep every one, in order, and fill
        // in only what they have not chosen.
        d.beats.forEach((b, i) => {
          const mine = spec.beats[i]; if (!mine) return;
          if (!mine.parts.length && !isComp(mine.screen)) mine.parts = valid(b);
          if (!mine.move && move(b.move)) mine.move = move(b.move);
          mine.word = b.word || mine.word; mine.line = b.line || mine.line;
        });
      } else if (all && Array.isArray(d.beats)) {
        spec.beats = d.beats.filter((b) => screenOf(b.screen)).map((b) => ({ screen: b.screen, parts: valid(b), move: move(b.move), word: b.word || '', line: b.line || '' }));
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
  const missing = spec.beats.filter((b) => !b.parts.length && !isComp(b.screen)).length;
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
