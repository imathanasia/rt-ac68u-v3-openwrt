#!/bin/sh
# Capture the same page set as the RT-AC3200 repo (1440x900, 2x scale).
# usage: ROUTER=http://192.168.1.4:8181 USER=root PASS=... scripts/screenshots.sh
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
(async () => {
  const b = await chromium.launch({ executablePath: process.env.CHROME ||
    '/root/.cache/ms-playwright/chromium-1248/chrome-linux64/chrome' });
  const p = await b.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });
  await p.goto(base + '/cgi-bin/luci/', { waitUntil: 'networkidle' });
  await p.screenshot({ path: out + '/luci-login.png' });
  const u = await p.$('input[name=luci_username]'), w = await p.$('input[name=luci_password]');
  if (u && w) {
    await u.fill(user); await w.fill(pass);
    await Promise.all([p.waitForNavigation({ waitUntil: 'networkidle' }), p.press('input[name=luci_password]', 'Enter')]);
  }
  for (const [path, name] of [
    ['/cgi-bin/luci/admin/status/overview', 'luci-overview'],
    ['/cgi-bin/luci/admin/status/statistics', 'luci-statistics'],
    ['/cgi-bin/luci/admin/status/nlbwmon', 'luci-nlbwmon'],
    ['/cgi-bin/luci/admin/services/sqm', 'luci-sqm'],
    ['/cgi-bin/luci/admin/network/wireless', 'luci-wireless'],
    ['/cgi-bin/luci/admin/services/rtac68u', 'router-page'],
    ['/cgi-bin/luci/admin/services/adguardhome', 'adguard']
  ]) {
    try { await p.goto(base + path, { waitUntil: 'networkidle' }); await p.screenshot({ path: out + '/' + name + '.png' }); }
    catch (e) { console.log('skip', name, e.message); }
  }
  await b.close();
})();
JS
ls -l "$OUT"/*.png | tail -n 8
