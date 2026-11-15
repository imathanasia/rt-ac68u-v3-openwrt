# Roadmap

**2026-11-14 update — driver move.**  b43-next is now the maintained line;
#26349 is being closed in favour of it and its package is
openwrt/openwrt#26717 (`kmod-b43-next`).  A b43-next build (f864076b) was
flashed and validated on the unit: both bands as AP, handover to
`bcma-next-pci-bridge` (bcmn0/bcmn1), IRQ pinning intact, LuCI fine.  The
driver-rebase item below is therefore superseded by "track b43-next
commits and rebuild from the package".

# Roadmap and deep-dive findings

State: the image in `broadcom-firmware/ac68u-v3-wifi/` is flashed and validated on the unit
(both APs, LuCI, AP-mode LAN, IRQ pinning). The items below are the realistic next steps,
ordered by value. Nothing here is built yet.

## A. Driver: rebase the AC-PHY snapshot (highest value, doable)

Our image embeds **b43-ac-wip `7bc6476` (2026‑11‑06)** via OpenWrt PR #26349. Upstream has
since added (aleferri/b43-ac-wip, newest `c509fb83`, 2026‑11‑12):

| Commit | Change | Relevant to this board? |
|---|---|---|
| `b38b9d90` | mirror the 80 MHz FIR row for a negative IQ slope | **yes** — we run VHT80 on ch36 |
| `7f999ad5` | arm the radar detector only on the AP's channel (not during scans) | yes if DFS channels are used |
| `67191cd6` | convert tempsense on a fit to 63 stock readings | cosmetic (reported temperature) |
| `f84b121a` | beamforming on an open BSS (with `txbf=1`) | optional experiment |
| `547f1c11` | chipcontrol bit 4 on femctrl 3 boards | **no** — ours is femctrl 6, and our dmesg already shows the read/write |
| `c509fb83`, `e7124538` | BCM43217 (N-PHY) traces, tracer tooling | no |

How to rebuild: clone `aleferri/b43-ac-wip` at `c509fb83`, run its
`scripts/phase1-to-openwrt.sh` (the fork used exactly this to produce `816-02/03`), replace
those patches in `openwrt-acphy/package/kernel/mac80211/patches/brcm/`, rebuild and reflash.
Cost: one build + one flash; the driver API is the same, so the rest of the image is untouched.

**Do not** rebase onto OpenWrt PR #25922 (the N-PHY/HT-PHY series): the PR author measured
**316–347 Mbit/s** there versus **397–421 Mbit/s** for #26349 on the same RT-AC56U, because the
AC header no longer fits the TX headroom and frames get reallocated (`ieee80211_skb_resize`).
We want the #26349 path.

## B. Driver features we can test now, no rebuild

| Knob | How | Notes |
|---|---|---|
| `txbf=1` | `echo options b43 txbf=1 >> /etc/modules.d/*b43*` or `insmod b43 txbf=1` | TX beamforming on an open BSS; measure before/after |
| DFS channels | set 5 GHz to ch52/100 with country PL | driver has ETSI/FCC radar detection, **not certified** |
| multi-BSS (guest SSID) | add a second `wifi-iface` on each radio | driver supports up to 4 SSIDs per radio; needs a firewall zone |
| 2.4 GHz HT40 | `htmode HT40` on ch1–11 | upstream says 2.4 GHz 40 MHz is **not characterised**; not recommended |

## C. Packages worth adding (all present in feeds)

| Package | Purpose | Size/risk |
|---|---|---|
| `aria2` + `luci-app-aria2` | download manager (Merlin "Download Master" equivalent) | small |
| `minidlna` + `luci-app-minidlna` | DLNA media server on the USB disk | small |
| `acme-acmesh` + `luci-app-acme` | Let's Encrypt certs for LuCI/AdGuard | small |
| `miniupnpd` + `luci-app-upnp` | UPnP/NAT-PMP for consoles and games | small, security trade-off |
| `tinyproxy` + `luci-app-tinyproxy` | HTTP proxy for the LAN | small |
| `zerotier` | SD-WAN VPN (CLI/UCI only, no LuCI app in this feed) | medium |
| `cloudflared` + `luci-app-cloudflared` | DoH proxy / tunnel | ~15–20 MB binary |

Not available in these feeds: `luci-app-diskman`, `luci-app-hdd`, `luci-app-nft-qos`,
`luci-app-zerotier`.

## D. ASUSWRT-Merlin / community features → OpenWrt equivalents

| Merlin / add-on | OpenWrt on this image |
|---|---|
| AiProtection (Trend Micro) | AdGuard Home + banip + adblock-fast (already) |
| Adaptive QoS | SQM/CAKE (already) |
| Traffic Analyzer | nlbwmon (already), vnstat2 (already) |
| VPN Fusion / multiple tunnels | WireGuard + ocserv + mwan3/pbr (already) |
| Download Master | **add aria2** |
| Media Server | **add minidlna** |
| Samba share | ksmbd (already) |
| Let's Encrypt | **add acme** |
| DDNS | ddns-scripts (already) |
| Guest network | **multi-BSS, doable** (driver supports it) |
| Beamforming | **txbf=1, doable** |
| Diversion (adblock) | AdGuard / adblock-fast (already) |
| Skynet (firewall) | banip (already) |
| spdMerlin (speed logging) | iperf3 cron / collectd; optionally `speedtest-go` |
| connmon (latency log) | collectd ping plugin / smokeping |
| scribe (remote syslog) | logd remote (already) |
| AiMesh / Smart Connect / roaming assistant | **not possible**: b43 AC-PHY has no 802.11k/v, no band steering |
| 160 MHz | **not possible**: driver exposes 80 MHz max |
| MU-MIMO | not on BCM4360 (Wave 1) |
| CPU overclock (Merlin NVRAM) | not applicable; clocks are fixed by the bootloader |

## E. What is deliberately not planned

- Proprietary Broadcom `wl` blob (licensing unclear, untested on this board) — open-source
  b43 works, so there is no reason.
- N-PHY/HT-PHY series (#25922) — costs throughput and is not needed here.
- 2.4 GHz HT40 — uncharacterised upstream and bad for a crowded band.
- DFS certification claim — the detector is experimental.

## F. Next steps, in order

1. Run `WiFiTest.ps1` on both bands (the user has the script); get real throughput numbers.
2. From those numbers decide: rebase to `c509fb83` (A) and/or `txbf=1` (B).
3. Add 2–4 packages (C) — aria2, minidlna, acme are the most useful.
4. Guest SSID + firewall zone (B/C).
5. Rebuild, validate, reflash; keep the wired 25.12 image as fallback.
