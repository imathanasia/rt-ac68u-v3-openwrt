# Screenshots

Captured from this unit with headless Chromium (1440×900, 2× scale, full page for the project
page). Re-capture with `ROUTER=http://<host>:8181 USER=root PASS=... scripts/screenshots.sh`.

| File | Page |
|---|---|
| `luci-login.png` | LuCI login |
| `luci-overview.png` | Status → Overview |
| `luci-statistics.png` | Statistics → Graphs |
| `luci-nlbwmon.png` | Statistics → nlbwmon |
| `luci-sqm.png` | Services → SQM |
| `luci-wireless.png` | Network → Wireless (captured with radios on, both APs up) |
| `router-page.png` | Services → ★ Router project (baked page, `/admin/services/router`; captured with radios on, so the Wi-Fi QR is visible) |
| `adguard.png` | AdGuard Home UI |

All shots except `luci-login.png` are taken after logging in; the script fails a page that
returns 404 or the login form, so a broken path cannot silently ship a blank screenshot.
