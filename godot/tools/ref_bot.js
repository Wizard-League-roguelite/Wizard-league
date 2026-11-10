// Runs dev/bot.js inside the original browser game and writes its transcript.
// Usage: node tools/ref_bot.js <seed> <battles> <out.txt>
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
(async () => {
  const [seed, battles, out] = [Number(process.argv[2] || 1), Number(process.argv[3] || 3), process.argv[4] || '/tmp/bot_ref.txt'];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', e => console.log('PAGE ERROR:', e.message));
  await page.route('**/*', r => r.request().url().startsWith('file:') ? r.continue() : r.abort());
  // Two seeded random streams: game logic, and visuals drawn from animation-frame callbacks.
  const visualSites = JSON.parse(fs.readFileSync(path.join(__dirname, 'visual_rng_sites.json'), 'utf8'));
  await page.addInitScript((sites) => {
    const visualSet = new Set(sites);
    let logic = null, visual = null, count = 0;
    const mk = s0 => { let s = s0 >>> 0; return () => { s = (s + 0x6D2B79F5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
    const orig = Math.random;
    window._rngTrace = [];
    window.JS_rngCount = () => count;
    Math.random = () => {
      if (!logic) return orig();
      // classify the call site (file:line of the caller) exactly as the converter does
      const frame = ((new Error()).stack.split('\n')[2] || '');
      const m = frame.match(/([\w.]+\.js):(\d+):\d+/);
      if (m && visualSet.has(m[1] + ':' + m[2])) return visual();
      count++;
      const v = logic();
      window._rngTrace.push(count + ' ' + v.toFixed(6));
      return v;
    };
    window.JS_seedRandom = seed => { logic = mk(seed); visual = mk(seed ^ 0x9E3779B9); };
  }, visualSites);
  await page.goto('file://' + path.resolve(__dirname, '../../index.html'));
  await page.addScriptTag({ path: path.resolve(__dirname, '../dev/bot.js') });
  await page.waitForTimeout(500);
  await page.evaluate(([seed, battles]) => {
    localStorage.clear();
    activeSaveSlot = 0; patchActiveSlot({ playerName: 'Bot' }); playerName = 'Bot'; sandboxMode = false;
    showBetweenRuns();
    botStart(seed, battles);
  }, [seed, battles]);
  const t0 = Date.now();
  while (Date.now() - t0 < 20 * 60 * 1000) {
    if (await page.evaluate(() => _botDone)) break;
    await page.waitForTimeout(1000);
  }
  fs.writeFileSync(out, (await page.evaluate(() => _botLog)).join('\n') + '\n');
  fs.writeFileSync(out + '.trace', (await page.evaluate(() => window._rngTrace)).join('\n') + '\n');
  console.log('ref bot done:', out);
  await browser.close();
})();
