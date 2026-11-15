
> **v3 build (2026-11-15):** `images/openwrt-AC68U-V3-homelab-v3.trx` — 52,428,800 B,
> sha256 `15eb4cd5c9da83bf…`, 379 packages. Project page **Services → ★ RT-AC68U** (login
> required), footer badge on every LuCI page, version string and DTS model credit the project,
> default login `root / changeme`. Radios stay **off** (`wifi-radio on|off|status`); Tailscale
> stays off until it has a node key. See
> [`CHANGELOG.md`](CHANGELOG.md) and [`docs/features-preview.html`](docs/features-preview.html).

# ASUS RT-AC68U V3 — OpenWrt with open-source BCM4360 Wi-Fi

**Validated on the unit** (2026‑11‑14): the image was flashed from a clean state and came up
with both radios broadcasting, the web UI reachable and the interrupt layout already fixed.
Throughput and long-term stability are still to be measured from a client.

| | |
|---|---|
| Image | `openwrt-AC68U-V3-WIFI-acphy.trx` |
| Size | 41,680,896 B (39.8 MiB) |
| SHA-256 | `30b1e42b2d826d0a76d40abcc40d970dbeecc538c4c50708b0b45ec0b265fd01` |
| Packages | 353 |
| Source | `flatstik/AC66U_B1` branch `b43-ac-phy` @ `25058cf7` + V3 device tree |
| Kernel | 6.18.60 · mac80211/backports 7.2 · b43 **AC-PHY** |
| Wi-Fi | 2× BCM4360 (d11 core rev 42, AC-PHY rev 1, radio 2069 rev 4), **femctrl 6** |
| Network | LAN `192.168.1.200`, DHCP off, upstream `192.168.1.1` (AP mode) |
| Access | SSH + LuCI. Root password is set locally on the unit; change it with `passwd`. |

## Hardware (read off this unit)

| | |
|---|---|
| SoC | bcma chip `53030` pkg `0x02` → **BCM47094** (newer Northstar die) |
| Switch | **BCM53011** rev 0, 5‑port GbE |
| RAM / NAND | 256 MiB / 128 MiB Macronix MX30LF1G18AC, BCH‑8 |
| Radio data | NVRAM, `devpath0=pci/1/1` (2.4), `devpath1=pci/2/1` (5); `1:femctrl=6` |
| IRQs | 34 eth0 · 44 b43 (2.4) · 45 b43 (5) |
| Flash | 126 MiB firmware area, 122 MiB UBI → ~80 MiB overlay |

The upstream `asus,rt-ac68u` DTS targets the older 53010 die with a BCM53012 switch, so this
image adds `bcm47094-asus-rt-ac68u-v3.dts` with the two overrides upstream uses for the
Netgear R6400 v2 (other 53030 board): `brcm,bcm4709-pinmux` and `brcm,ns-bx-usb3-phy`.

## Verified

| Check | Result |
|---|---|
| Boot from clean flash | yes, model `Asus RT-AC68U V3 (BCM47094)` |
| b43 probe | both radios, core rev 42, AC‑PHY rev 1, radio 2069 rev 4, no `-95` |
| APs auto-configured | `AC68U-V3-2G` ch1/HT20 20 dBm and `AC68U-V3-5G` ch36/VHT80 23 dBm |
| LuCI | login + overview HTTP 200 |
| Dashboard | `http://192.168.1.200/ac68u.html` HTTP 200, live JSON |
| AP mode | LAN 192.168.1.200, DHCP server off, default route via 192.168.1.1 |
| Interrupt pinning | eth0 + 2.4 GHz radio on CPU1, 5 GHz radio on CPU0 |
| iperf3 test server | `192.168.1.200:5201`, started at boot (disable with `/etc/init.d/ac68u-iperf stop; ... disable`) |
| HTTP test endpoints | `/cgi-bin/speed-down?mb=N`, `/cgi-bin/speed-up` |
| DNS | clients → dnsmasq(:53) → AdGuard(:5353); 191k filter rules loaded |

## Not verified yet

- Throughput per band from a client (`iperf3`), and the 2.4 GHz-under-5 GHz-load contention
  test the pinning is for.
- USB 3.0 SuperSpeed with an actual device (the controller enumerates 5000M).
- Long soak.
- `ac68u-wifi-test` reports all of the above at a glance.

## Features

LuCI/SSL, AdGuard Home, Tailscale, SQM/CAKE, WireGuard, ocserv, ksmbd/SMB, USB storage
(ext4/exfat/ntfs3), cifsmount, statistics/collectd, nlbwmon, vnstat2, wifihistory, watchcat,
banip, mwan3+pbr, DDNS, smartdns, https-dns-proxy, attendedsysupgrade, nut, IRQ-balance, ttyd,
smartmontools, iperf3, htop, curl/wget, wsdd2, mosquitto (broker), USB tethering modules.

## Files baked in

| Purpose | Path |
|---|---|
| Auto AP setup on first boot (waits for both radios) | `/etc/init.d/ac68u-wifi` |
| Wi-Fi settings | `/etc/ac68u-wifi.conf` |
| Interrupt pinning + irqbalance bans | `/etc/init.d/ac68u-irq` |
| AP-mode LAN 192.168.1.200 | `/etc/uci-defaults/98-ap-mode.sh` |
| LuCI ucode handler fix (uhttpd 2026.11) | `/etc/uci-defaults/89-uhttpd-luci` |
| AdGuard + DNS chain | `/etc/adguardhome/adguardhome.yaml`, `91-adguard-dns.sh` |
| Live status dashboard | `/www/ac68u.html`, `/www/cgi-bin/ac68u-status` |
| Wi-Fi health check / iperf3 | `/usr/bin/ac68u-wifi-test` |
| Manual AP helper | `/usr/bin/ac68u-wifi-ap` |
| USB extroot | `/root/usb-overlay.sh` |

## Flash / rollback

From a running OpenWrt (SSH):

```sh
cd /tmp
wget http://192.168.1.22:8000/ac68u-v3-wifi/openwrt-AC68U-V3-WIFI-acphy.trx
sha256sum openwrt-AC68U-V3-WIFI-acphy.trx   # must equal the value above
sysupgrade -n openwrt-AC68U-V3-WIFI-acphy.trx
```

Offline: ASUS CFE recovery (hold **Reset** at power‑on until the LED blinks slowly, then
`http://192.168.1.1/`) and upload the same file. Rollback: the no‑Wi‑Fi image
`../ac68u-v3/openwrt-AC68U-V3-wired-stable.trx`, or stock ASUS firmware, the same way.

## b43-next image (forward path)

The maintainers are retiring #26349 in favour of **b43-next**
(aleferri/rhgndf, out-of-tree, own bcma/ssb copies), packaged as
`kmod-b43-next` in openwrt/openwrt#26717. A build with that package was
validated on the unit: both cards hand over to `bcma-next-pci-bridge`, both
bands come up as AP, IRQ pinning still works (the IRQs are renamed
`b43_next`).

* Image: `broadcom-firmware/ac68u-v3-wifi-b43next/openwrt-AC68U-V3-WIFI-b43next.trx`
  — 42,729,472 B, sha256 `b39dd6a80f7f98060366ba72c85d4ee058bf82a57020075310084c5b2859b241`
* Driver: b43-next `ee7ed443` (n-fixes, 2026-11-14), DFS on, firmware squashed to corerev 42 / AC.
* No local enable step is needed: the package's post-install enables
  `/etc/init.d/b43-next` during image assembly (`/rom/etc/rc.d/S15b43-next`).
  Only `ac68u-irq` was adapted to match `b43_next`.

The #26349 snapshot documented below stays as the fallback image.

## Provenance / licensing

- b43 and the AC‑PHY patches are GPL‑2.0, reverse‑engineered from Broadcom `wl` traces
  (`aleferri/b43-ac-wip`); the series is **unmerged**.
- Firmware blobs: Broadcom `broadcom-wl-6.30.163.46` via `b43-fwcutter`
  (sha256 `a07c3b6b…335c2d`), the same path OpenWrt already uses for b43 firmware.
  Do not redistribute this image as an official build.
- Upstream reports: `docs/upstream-report-ac68u-v3.md` (the board) and
  `docs/upstream-report-uhttpd-luci.md` (build/UI findings).
