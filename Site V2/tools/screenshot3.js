const puppeteer = require('puppeteer-core');
const path = require('path');

const ROOT = path.join(__dirname, '..');

const FILE = 'file:///' + path.resolve(ROOT, 'app-5screens.html').replace(/\\/g, '/');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const SCREENS = [
  { idx: 0, name: 'app_s1_oraculo' },
  { idx: 1, name: 'app_s2_mapa' },
  { idx: 2, name: 'app_s3_vision' },
  { idx: 3, name: 'app_s4_logbook' },
  { idx: 4, name: 'app_s5_perfil' },
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
    headless: 'new',
  });

  for (const s of SCREENS) {
    const page = await browser.newPage();
    // deviceScaleFactor:1 evita o problema de coordenadas duplicadas
    await page.setViewport({ width: 1600, height: 900, deviceScaleFactor: 1 });
    await page.goto(FILE, { waitUntil: 'networkidle0', timeout: 30000 });
    await new Promise(r => setTimeout(r, 2500));

    const wraps = await page.$$('.phone-wrap');
    const box   = await wraps[s.idx].boundingBox();

    const pad = 24;
    const clip = {
      x:      Math.max(0, Math.floor(box.x - pad)),
      y:      Math.max(0, Math.floor(box.y - pad)),
      width:  Math.ceil(box.width  + pad * 2),
      height: Math.ceil(box.height + pad * 2),
    };

    // expand viewport to cover the element
    await page.setViewport({ width: clip.x + clip.width + 10, height: clip.y + clip.height + 10, deviceScaleFactor: 2 });
    await new Promise(r => setTimeout(r, 300));

    const out = path.join(ROOT, 'images', `${s.name}.png`);
    await page.screenshot({
      path: out,
      clip: { x: clip.x * 2, y: clip.y * 2, width: clip.width * 2, height: clip.height * 2 },
    });

    console.log(`✓ ${s.name}.png`);
    await page.close();
  }

  // full overview — todos juntos
  const page2 = await browser.newPage();
  await page2.setViewport({ width: 1600, height: 900, deviceScaleFactor: 1 });
  await page2.goto(FILE, { waitUntil: 'networkidle0', timeout: 30000 });
  await new Promise(r => setTimeout(r, 2500));
  const fullH = await page2.evaluate(() => document.body.scrollHeight);
  await page2.setViewport({ width: 1600, height: fullH, deviceScaleFactor: 2 });
  await new Promise(r => setTimeout(r, 300));
  await page2.screenshot({ path: path.join(ROOT, 'images', 'app_overview.png') });
  console.log('✓ app_overview.png');
  await page2.close();

  await browser.close();
  console.log('Done.');
})();
