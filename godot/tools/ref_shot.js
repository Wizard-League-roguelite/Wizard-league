// Reference screenshots of the original browser game (for visual comparison with the Godot port).
// Usage: node tools/ref_shot.js steps.json   — steps: {"wait":ms} {"click":"sel"} {"shot":"file.png"} {"eval":"js"} {"type":"sel","value":"x"}
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
(async () => {
  const steps = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const [w, h] = (process.env.RES || '1280x720').split('x').map(Number);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
  page.on('pageerror', e => console.log('PAGE ERROR:', e.message));
  page.on('console', m => { if (m.type() === 'error') console.log('CONSOLE:', m.text()); });
  // Serve the same fonts the Godot port bundles (Cinzel; Gelasio standing in for Georgia) so text metrics are comparable.
  const F = 'file://' + path.resolve(__dirname, '../fonts') + '/';
  const face = (fam, w, st, file) => `@font-face{font-family:'${fam}';font-weight:${w};font-style:${st};src:url('${F}${file}') format('woff2');}`;
  const fontCss = face('Cinzel', 400, 'normal', 'Cinzel-Regular.woff2') + face('Cinzel', 700, 'normal', 'Cinzel-Bold.woff2') +
    face('Georgia', 400, 'normal', 'Gelasio-400-normal.woff2') + face('Georgia', 700, 'normal', 'Gelasio-700-normal.woff2') +
    face('Georgia', 400, 'italic', 'Gelasio-400-italic.woff2') + face('Georgia', 700, 'italic', 'Gelasio-700-italic.woff2');
  await page.route('**/*', r => { const u = r.request().url();
    if (u.startsWith('file:')) r.continue();
    else if (u.includes('fonts.googleapis.com')) r.fulfill({ contentType: 'text/css', body: fontCss });
    else r.abort(); });
  if (process.env.SEED) await page.addInitScript(seed => { let s = seed >>> 0; Math.random = () => { s = (s + 0x6D2B79F5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }, Number(process.env.SEED));
  await page.goto('file://' + path.resolve(__dirname, '../../index.html'));
  for (const s of steps) {
    if (s.wait != null) await page.waitForTimeout(s.wait);
    else if (s.click) await page.click(s.click, { force: true }).catch(e => console.log('click failed', s.click, e.message.split('\n')[0]));
    else if (s.clickxy) await page.mouse.click(s.clickxy[0], s.clickxy[1]);
    else if (s.type) await page.fill(s.type, s.value);
    else if (s.eval) console.log('EVAL', JSON.stringify(await page.evaluate(s.eval).catch(e => 'ERR ' + e.message)));
    else if (s.shot) { await page.screenshot({ path: s.shot }); console.log('saved', s.shot); }
  }
  await browser.close();
})();
