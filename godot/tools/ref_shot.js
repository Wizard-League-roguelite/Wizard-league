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
  await page.route('**/*', r => { const u = r.request().url(); if (u.startsWith('file:')) r.continue(); else r.abort(); });
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
