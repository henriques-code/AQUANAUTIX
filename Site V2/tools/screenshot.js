const puppeteer = require('puppeteer-core');
const path = require('path');

/** Raiz Site V2 (pai de /tools) */
const ROOT = path.join(__dirname, '..');

const FILE = 'file:///' + path.resolve(ROOT, 'monetization-prototype.html').replace(/\\/g, '/');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const SCREENS = [
  { id: 'planos',     name: '1_planos' },
  { id: 'oraculo',   name: '2_oraculo' },
  { id: 'alertas',   name: '3_alertas' },
  { id: 'spots',     name: '4_spots' },
  { id: 'afiliacao', name: '5_afiliacao' },
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
    headless: 'new',
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 2 });
  await page.goto(FILE, { waitUntil: 'networkidle0', timeout: 30000 });

  // wait for fonts
  await new Promise(r => setTimeout(r, 2000));

  for (const s of SCREENS) {
    await page.evaluate((id) => {
      window.showScreen(id);
    }, s.id);
    await new Promise(r => setTimeout(r, 800));

    // full page height
    const bodyH = await page.evaluate(() => document.body.scrollHeight);
    await page.setViewport({ width: 1440, height: bodyH, deviceScaleFactor: 2 });

    const outPath = path.join(ROOT, 'images', `${s.name}.png`);
    await page.screenshot({ path: outPath, fullPage: false });
    console.log('✓', outPath);

    // reset viewport
    await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 2 });
  }

  await browser.close();
  console.log('Done.');
})();
