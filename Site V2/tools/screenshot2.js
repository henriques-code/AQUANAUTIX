const puppeteer = require('puppeteer-core');
const path = require('path');

const ROOT = path.join(__dirname, '..');

const FILE = 'file:///' + path.resolve(ROOT, 'app-5screens.html').replace(/\\/g, '/');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
    headless: 'new',
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1600, height: 900, deviceScaleFactor: 2 });
  await page.goto(FILE, { waitUntil: 'networkidle0', timeout: 30000 });
  await new Promise(r => setTimeout(r, 3000));

  // Full page — todos os 5 telemóveis juntos
  const fullH = await page.evaluate(() => document.body.scrollHeight);
  await page.setViewport({ width: 1600, height: fullH, deviceScaleFactor: 2 });
  await page.screenshot({ path: path.join(ROOT, 'images', 'app_5screens_full.png') });
  console.log('✓ app_5screens_full.png');

  // Screenshots individuais por phone-wrap
  await page.setViewport({ width: 1600, height: 900, deviceScaleFactor: 2 });
  const labels = ['oraculo','mapa','vision','logbook','perfil'];
  const wraps = await page.$$('.phone-wrap');

  for (let i = 0; i < wraps.length; i++) {
    const box = await wraps[i].boundingBox();
    const clip = {
      x: Math.max(0, box.x - 10),
      y: Math.max(0, box.y - 10),
      width: box.width + 20,
      height: box.height + 20,
    };
    await page.setViewport({ width: 1600, height: Math.ceil(clip.y + clip.height + 20), deviceScaleFactor: 2 });
    await page.screenshot({
      path: path.join(ROOT, 'images', `app_${i+1}_${labels[i]}.png`),
      clip: { x: clip.x*2, y: clip.y*2, width: clip.width*2, height: clip.height*2 },
    });
    console.log(`✓ app_${i+1}_${labels[i]}.png`);
  }

  await browser.close();
  console.log('Done.');
})();
