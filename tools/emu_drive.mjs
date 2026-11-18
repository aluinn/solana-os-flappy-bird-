#!/usr/bin/env node
// Drive the hosted Solana OS emulator in headless Chrome: install this app over
// the emulator's Console (`lua put`), run it, press keys and take screenshots.
// Uses only Node's built-ins (global WebSocket, fetch) and an installed Chrome
// through the DevTools protocol: no npm packages.
//
//   node tools/emu_drive.mjs [script.json]
//
// A script is a JSON array of steps:
//   {"wait": 1500}                      sleep, ms
//   {"key": "Enter"}                    press a key (Enter = SELECT, Escape = CANCEL)
//   {"console": "lua list"}             run a console command
//   {"shot": "docs/assets/x.png", "what": "screen" | "badge"}
//   {"text": 800}                       print the last N chars of the console log
//   {"repeat": 30, "steps": [ ... ]}    run the inner steps N times
//   {"eval": "document.title"}          run JS in the page and print the result
// The app in ./solana-flappy is installed first unless NO_INSTALL=1.
// HEADED=1 node tools/emu_drive.mjs   opens a visible window to play in.

import { spawn } from "node:child_process";
import { readFileSync, readdirSync, statSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { tmpdir } from "node:os";

const EMU = process.env.EMU_URL || "https://solana.com/breakpoint/badge/emulator";
const CHROME = process.env.CHROME || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const APP_DIR = process.env.APP_DIR || "solana-flappy";
const APP_ID = JSON.parse(readFileSync(join(APP_DIR, "app.json"), "utf8")).id;
const PORT = 9300 + Math.floor(Math.random() * 500);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const HEADED = !!process.env.HEADED;  // HEADED=1: visible window, left open for you to play
const chrome = spawn(CHROME, [
  ...(HEADED ? [] : ["--headless=new", "--disable-gpu"]), `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${join(tmpdir(), "emu-drive-" + PORT)}`, "--window-size=1100,1500",
  "--hide-scrollbars", "about:blank",
], { stdio: "ignore" });
process.on("exit", () => chrome.kill());

async function connect() {
  for (let i = 0; i < 50; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
      const page = list.find((t) => t.type === "page");
      if (page) return page.webSocketDebuggerUrl;
    } catch {}
    await sleep(200);
  }
  throw new Error("Chrome did not start");
}

const ws = new WebSocket(await connect());
await new Promise((r) => (ws.onopen = r));
let id = 0;
const pending = new Map();
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id); }
};
const cdp = (method, params = {}) => new Promise((res, rej) => {
  const n = ++id;
  pending.set(n, (d) => (d.error ? rej(new Error(method + ": " + d.error.message)) : res(d.result)));
  ws.send(JSON.stringify({ id: n, method, params }));
});
const evalJs = async (expression) => (await cdp("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true })).result.value;

await cdp("Page.enable");
await cdp("Emulation.setDeviceMetricsOverride", { width: 1100, height: 1500, deviceScaleFactor: 2, mobile: false });
await cdp("Page.navigate", { url: EMU });
await sleep(9000); // the wasm firmware boots and shows the launcher

async function consoleCmd(line) {
  // the Console panel is a collapsed <details>: open it so the input can take focus
  await evalJs(`(() => { const i = document.querySelector('#emu-cmd'); i.closest('details').open = true; i.focus(); i.value = ''; })()`);
  await cdp("Input.insertText", { text: line });
  await cdp("Input.dispatchKeyEvent", { type: "keyDown", key: "Enter", code: "Enter", windowsVirtualKeyCode: 13, text: "\r" });
  await cdp("Input.dispatchKeyEvent", { type: "keyUp", key: "Enter", code: "Enter", windowsVirtualKeyCode: 13 });
  await sleep(120);
}

function files(dir) {
  const out = [];
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    if (statSync(p).isDirectory()) out.push(...files(p));
    else out.push(p);
  }
  return out;
}

async function install() {
  // app.json first (the badge checks it), then everything else.
  const all = files(APP_DIR).map((p) => relative(APP_DIR, p)).sort((a, b) => (a === "app.json" ? -1 : b === "app.json" ? 1 : 0));
  for (const rel of all) {
    const b64 = readFileSync(join(APP_DIR, rel)).toString("base64");
    await consoleCmd(`lua put ${APP_ID} ${rel} begin`);
    for (let i = 0; i < b64.length; i += 128) await consoleCmd(`lua put ${APP_ID} ${rel} ${b64.slice(i, i + 128)}`);
    await consoleCmd(`lua put ${APP_ID} ${rel} end`);
  }
}

const keyMap = { Enter: 13, Escape: 27, ArrowUp: 38, ArrowDown: 40, ArrowLeft: 37, ArrowRight: 39 };
async function press(key, hold = 60) {
  await evalJs(`document.activeElement && document.activeElement.blur()`);
  const k = { key, code: key, windowsVirtualKeyCode: keyMap[key] || key.toUpperCase().charCodeAt(0) };
  await cdp("Input.dispatchKeyEvent", { type: "rawKeyDown", ...k });
  await sleep(hold);
  await cdp("Input.dispatchKeyEvent", { type: "keyUp", ...k });
}

async function shot(path, what) {
  // "screen" = the 320x218 LCD canvas; "badge" = the whole drawn badge board
  const sel = what === "badge" ? `svg[aria-label^="Solana OS emulator"]` : `canvas`;
  const r = await evalJs(`(() => {
    const b = document.querySelector('${sel}').getBoundingClientRect();
    return { x: b.x + scrollX, y: b.y + scrollY, width: b.width, height: b.height };
  })()`);
  // For the board shot, hide the rest of the page (nav text bleeds in at the edges)
  if (what === "badge") await evalJs(`(() => { const st = document.createElement('style'); st.id = 'emu-drive-hide';
    st.textContent = '* { visibility: hidden !important } svg[aria-label^="Solana OS emulator"], svg[aria-label^="Solana OS emulator"] *, canvas { visibility: visible !important }';
    document.head.appendChild(st); })()`);
  const { data } = await cdp("Page.captureScreenshot", { format: "png", clip: { ...r, scale: 1 }, captureBeyondViewport: true });
  if (what === "badge") await evalJs(`document.getElementById('emu-drive-hide').remove()`);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, Buffer.from(data, "base64"));
  console.log("saved", path, `${Math.round(r.width)}x${Math.round(r.height)}`);
}

const consoleText = (n) => evalJs(`document.querySelector('#emu-cmd').closest('details').querySelector('pre').innerText.slice(-${n})`);

const steps = process.argv[2] ? JSON.parse(readFileSync(process.argv[2], "utf8")) : [];
if (!process.env.NO_INSTALL) { await install(); await consoleCmd(`lua run ${APP_ID}`); await sleep(1500); }
async function run(list) {
  for (const s of list) {
    if (s.repeat) for (let i = 0; i < s.repeat; i++) await run(s.steps);
    else if (s.wait) await sleep(s.wait);
    else if (s.key) await press(s.key, s.hold);
    else if (s.console) await consoleCmd(s.console);
    else if (s.shot) await shot(s.shot, s.what || "screen");
    else if (s.text) console.log(await consoleText(s.text));
    else if (s.eval) console.log(await evalJs(s.eval));
  }
}
await run(steps);
if (HEADED) { console.log("Emulator is open with the app running. Press Ctrl+C here to close it."); await new Promise(() => {}); }
chrome.kill();
process.exit(0);
