# Changelog

## v3 — project page, branding, authenticated UI

- **Services → ★ RT-AC68U**: the project page is a LuCI view (login required by
  construction), showing radio state, hardware (femctrl 6, table 0x0a link), service states,
  recovery steps, a first-5-minutes checklist, and a Wi-Fi QR when a radio is on.
- **Footer badge on every page**: `patches/luci-footer-badge.patch` adds a fixed
  "★ RT-AC68U project" link to the LuCI base footer (theme-independent).
- **Branding**: `DISTRIB_DESCRIPTION` and `os-release PRETTY_NAME` become
  `OpenWrt 25.12 (r0-25058cf) · RT-AC68U V3 mod by ImAthanasia`; the DTS model string gains
  `, mod by ImAthanasia`.
- **Baked default credentials**: `root / changeme` (printed on the page, change with
  `passwd`).
- `qrencode` added for the Wi-Fi QR. Radios still ship off; the QR only appears when one is on.
- Docs: `use-cases.md`, `limitations.md`, `optional-packages.md`, `discoveries.md`,
  `r7000-probe-plan.md`, `ac3200-backport.md`; screenshot script under `scripts/`.

## v2 — homelab feature set, radios off by default

- **Radios stay off unless asked.** `wifi-radio on|off|status` (`/usr/sbin/wifi-radio`)
  starts/stops the APs; at boot the b43 phy driver loads but no AP interface is up, so the
  unit transmits nothing. `/etc/init.d/ac68u-wifi` ships disabled and
  `/etc/uci-defaults/95-wifi-off.sh` enforces it.
- **Packages added** (on top of the 353-package AC-PHY image): `ser2net`, `p910nd`,
  `usbip`, `udpxy`, `watchcat`, `wifischedule`, `ttyd` + LuCI apps, `luci-app-statistics`,
  `luci-app-commands`, `luci-app-wol`, `luci-app-upnp`, `smartmontools`, `htop`, `curl`,
  `speedtest-go`. Image: 52,428,800 B, 378 packages.
- **Tailscale is off until it has a node key** (`/etc/uci-defaults/96-tailscale-off.sh`);
  AdGuard Home stays on (LAN DNS → 127.0.0.1:5353 → DoH).
- **Not changed:** AP-mode network (192.168.1.200, upstream 192.168.1.1, DHCP off),
  AdGuard Home, SQM, ksmbd, aria2, nlbwmon, vnstat2, banip, mwan3 — all present since v1.
- The 32 MiB initramfs image is no longer built (`CONFIG_TARGET_ROOTFS_INITRAMFS` off):
  with the extra packages it exceeded the trx limit for the initramfs variant only.
- Flashed from DD-WRT r66631 through the CFE recovery page (DD-WRT's own upgrade cannot
  write it: its `linux` mtd is only 30 MB).

## v1 — OpenWrt with open-source BCM4360 Wi-Fi (AC-PHY)

- First hardware-validated image: both radios broadcasting, LuCI reachable, IRQ layout fixed.
- Source: flatstik/AC66U_B1 `b43-ac-phy` @ 25058cf7, kernel 6.18.60, b43 AC-PHY, femctrl 6.
