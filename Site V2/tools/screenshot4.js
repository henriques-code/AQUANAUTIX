const puppeteer = require('puppeteer-core');
const path = require('path');

const ROOT = path.join(__dirname, '..');

const FILE = 'file:///' + path.resolve(ROOT, 'app-5screens.html').replace(/\\/g, '/');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const LABELS = ['oraculo','mapa','vision','logbook','perfil'];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    args: ['--no-sandbox','--disable-setuid-sandbox','--disable-gpu'],
    headless: 'new',
  });

  for (let i = 0; i < 5; i++) {
    const page = await browser.newPage();
    await page.setViewport({ width: 500, height: 900, deviceScaleFactor: 2 });
    await page.goto(FILE, { waitUntil: 'networkidle0', timeout: 30000 });
    await new Promise(r => setTimeout(r, 2000));

    // Esconde todos os phone-wraps excepto o i-ésimo
    // E esconde o header, footer, scene padding
    await page.evaluate((idx) => {
      const wraps = document.querySelectorAll('.phone-wrap');
      wraps.forEach((w, j) => {
        if (j !== idx) w.style.display = 'none';
      });
      // centre the remaining one
      const scene = document.querySelector('.scene');
      scene.style.padding = '20px';
      scene.style.justifyContent = 'center';
      document.querySelector('.header').style.display = 'none';
      const footer = document.querySelector('.footer');
      if (footer) footer.style.display = 'none';
    }, i);

    await new Promise(r => setTimeout(r, 300));

    const fullH = await page.evaluate(() => document.body.scrollHeight);
    await page.setViewport({ width: 500, height: fullH, deviceScaleFactor: 2 });
    await new Promise(r => setTimeout(r, 200));

    const out = path.join(ROOT, 'images', `screen_${i+1}_${LABELS[i]}.png`);
    await page.screenshot({ path: out, fullPage: true });
    console.log(`✓ screen_${i+1}_${LABELS[i]}.png`);
    await page.close();
  }

  await browser.close();
  console.log('Done.');
})();
