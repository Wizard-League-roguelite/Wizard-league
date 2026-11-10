// Smoke test for the web export: serves the folder the way GitHub Pages does (plain static
// files under a sub-path, no cross-origin-isolation headers), boots the game in headless
// Chromium, clicks PLAY and checks that it runs cleanly and that music is fetched.
// Usage: node web_smoke.js <export-dir> [screenshot.png]
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const dir = path.resolve(process.argv[2] || '../build/web'), shot = process.argv[3];
const BASE = '/Wizard-league/play/';
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.mp3': 'audio/mpeg' };

const server = http.createServer((req, res) => {
  let u = decodeURIComponent(req.url.split('?')[0]);
  if (!u.startsWith(BASE)) { res.writeHead(404); return res.end(); }
  let f = path.join(dir, u.slice(BASE.length) || 'index.html');
  if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
});

(async () => {
  await new Promise(r => server.listen(0, r));
  const url = `http://localhost:${server.address().port}${BASE}`;
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const problems = [], seen = [];
  let booted = false;
  page.on('console', m => {
    const t = m.text();
    if (t.includes('Godot Engine v')) booted = true;
    if (/SCRIPT ERROR|USER ERROR|Parse Error|Failed loading|could not fetch/i.test(t) || (m.type() === 'error' && !/AudioContext/.test(t))) problems.push('console: ' + t);
  });
  page.on('pageerror', e => problems.push('pageerror: ' + e.message));
  page.on('requestfailed', r => problems.push('request failed: ' + r.url()));
  page.on('response', r => { seen.push(r.url()); if (r.status() >= 400) problems.push(`http ${r.status()}: ${r.url()}`); });

  await page.goto(url);
  const t0 = Date.now();
  while (!booted && Date.now() - t0 < 120000) await page.waitForTimeout(500);
  if (!booted) problems.push('engine did not start within 120 s');
  await page.waitForTimeout(8000);                       // title screen is up
  const overlay = await page.evaluate(() => { const el = document.getElementById('status'); return el ? getComputedStyle(el).visibility : 'gone'; });
  if (overlay === 'visible') problems.push('loading overlay still visible (engine reported an error or never finished loading)');
  await page.mouse.click(640, 457);                      // PLAY (also unlocks audio)
  const t1 = Date.now();
  while (!seen.some(u => u.endsWith('/audio/menu.mp3')) && Date.now() - t1 < 30000) await page.waitForTimeout(500);
  if (!seen.some(u => u.endsWith('/audio/menu.mp3'))) problems.push('menu music was never requested after clicking PLAY');
  await page.waitForTimeout(4000);
  const png = await page.screenshot(shot ? { path: shot } : {});
  if (png.length < 15000) problems.push('screenshot looks blank (' + png.length + ' bytes)');
  await browser.close().catch(() => {});
  server.close();
  if (problems.length) { console.error('WEB SMOKE TEST FAILED\n  ' + problems.join('\n  ')); process.exit(1); }
  console.log(`web smoke test passed (${seen.length} requests, boot ${(t1 - t0) / 1000 | 0} s)`);
  process.exit(0);
})().catch(e => { console.error('WEB SMOKE TEST FAILED\n  ' + e.message); process.exit(1); });
