#!/bin/sh
# Capture the page set used in README/images (1440x900, 2x scale).
# usage: ROUTER=http://192.168.1.4:8181 PASS=changeme scripts/screenshots.sh
# Radios should be ON for the wireless shot: run `wifi-radio on` first, `off` after.
set -eu
ROUTER=${ROUTER:-http://192.168.1.4:8181}
USER=${USER:-root}
PASS=${PASS:?set PASS}
OUT=${OUT:-images}
PW=${PW:-/root/projects/flipwatch}
mkdir -p "$OUT"
node - "$ROUTER" "$USER" "$PASS" "$OUT" "$PW" <<'JS'
const [,, base, user, pass, out, pwdir] = process.argv;
const { chromium } = require(pwdir + '/node_modules/playwright-core');

const PAGES = [
  ['/cgi-bin/luci/admin/status/overview',   'luci-overview',   false],
  ['/cgi-bin/luci/admin/statistics/graphs', 'luci-statistics', false],
  ['/cgi-bin/luci/admin/services/nlbw',     'luci-nlbwmon',    false],
  ['/cgi-bin/luci/admin/network/sqm',       'luci-sqm',        false],
  ['/cgi-bin/luci/admin/network/wireless',  'luci-wireless',   false],
  ['/cgi-bin/luci/admin/services/rtac68u',  'router-page',     true ],
  ['/cgi-bin/luci/admin/services/adguardhome', 'adguard',      false]
];

(async () => {
  const b = await chromium.launch({ executablePath: process.env.CHROME ||
    '/root/.cache/ms-playwright/chromium-1248/chrome-linux64/chrome' });
  const ctx = await b.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });
  const p = await ctx.newPage();
  const fails = [];

  await p.goto(base + '/cgi-bin/luci/', { waitUntil: 'networkidle' });
  await p.screenshot({ path: out + '/luci-login.png' });

  await p.fill('input[name=luci_username]', user);
  await p.fill('input[name=luci_password]', pass);
  await Promise.all([
    p.waitForURL(/\/admin\//, { timeout: 20000 }).catch(() => {}),
    p.press('input[name=luci_password]', 'Enter')
  ]);
  await p.waitForLoadState('networkidle').catch(() => {});
  const logged = await p.evaluate(() => !!document.querySelector('.main .nav, #mainmenu, .main-menu, aside'));
  if (!logged) { console.error('LOGIN FAILED'); }
  console.log('login:', logged ? 'ok' : 'unknown');

  for (const [path, name, full] of PAGES) {
    try {
      await p.goto(base + path, { waitUntil: 'networkidle' });
      await p.waitForTimeout(1200);
      const txt = await p.evaluate(() => document.body.innerText || '');
      const bad = /404|Not Found|Page not found|Log in/i.test(txt) && !/login/i.test(path);
      if (bad) fails.push(name);
      await p.screenshot({ path: out + '/' + name + '.png', fullPage: full });
      console.log((bad ? 'BAD  ' : 'ok   ') + name + '  ' + txt.trim().split('\n')[0].slice(0, 60));
    } catch (e) {
      fails.push(name);
      console.log('FAIL ' + name + '  ' + e.message);
    }
  }
  await b.close();
  if (fails.length) { console.log('pages needing attention: ' + fails.join(', ')); process.exit(3); }
})();
JS
ls -l "$OUT"/*.png | tail -n 8
