# RT-AC68U V3 — femctrl-6 read-back plan and discoveries

Date: 2026-11-15. Context: egc112 (openwrt/openwrt#26717) asked for a
read-back of the FEM/switch registers with stock `wl` running on the V3
(aleferri/b43-ac-wip#50, question 2) to confirm the `b43_phy_ac_fem_femctrl6`
table is correct for a Northstar board. Until then, watch per-chain RSSI and
TX power.

## What we compared against (b43 side)

From `patches/816-03-acphy-bringup.patch`:

- FEM control table is PHY table `0x0a`, element width 8 bits, offset
  `0x20 * core`, 32 entries per core, written at bring-up on every channel
  (`b43_phy_ac_set_regtbl_on_femctrl()`); nothing rewrites it later.
- For femctrl 6 sub 0 the same table is used on every core
  (`b43_phy_ac_fem_femctrl6`):

      00 00 06 02 00 00 06 02   00 01 00 00 00 00 00 00
      00 00 06 02 00 00 06 02   00 01 00 00 00 00 00 00

- femctrl 6 has no `pre`/`setup` hooks: no PHY 0x040a bit 8, no PMU
  regctl/chipcommon writes around the table.
- Tables only verified on AC-PHY rev 1 (our V3: AC-PHY rev 1, radio 2069
  rev 4 — matches).

## Discovery 1 — DD-WRT can't run the kprobe harness

Checked both builds for `asus_rt-ac68u` (extracted, inspected kernel and
rootfs):

| build | kernel | wl.ko module | kprobes |
|---|---|---|---|
| 2022-11-21 r50927 | 4.4.302-st25 | yes (`/lib/modules/4.4.302-st25/wl.ko`) | **no** |
| 2026-11-13 r66631 (latest) | 4.4.302-rt232-st80 | yes | **no** |

- `register_kprobe`, `kprobe_events` absent from the kallsyms in both
  kernels → CONFIG_KPROBES disabled; egc112's "wl_diag kprobes" harness
  cannot run on DD-WRT as shipped.
- DD-WRT's `wl` userspace is a reduced build: only channel/txpwr/assoc-level
  ioctls, **no `phyreg`/`phytable`** — so even without kprobes, stock DD-WRT
  can't read PHY registers with its own `wl`.
- kallsyms *is* enabled in both kernels (a custom-module escape hatch
  exists, but needs the DD-WRT kernel source/toolchain — kept as plan C).

## Discovery 2 — ASUS stock firmware's `wl` can do the read-back directly

The RT-AC68U 386.49703 stock firmware (downloaded and inspected,
SHA-256 `4e9bcf1d38a1658ba1530c984783cb79f85b98e5c2a90c200b888466e4731adf`)
carries the full Broadcom `wl` utility:

- `wl phyreg <offset> [value]` — get/set a PHY register
- `wl phytable <table_id> <offset> <width> [element]` — read table elements
  (width 8/16/32)

So the read-back needs **no kprobes and no DD-WRT**: flash ASUS stock,
enable SSH, and read table 0x0a on each radio with the stock driver up.

## Read-back procedure (harness: serve/ac68u-femctrl6-readback.sh)

1. Flash `serve/asus-rt-ac68u-386.49703.trx` (via ASUS web UI from OpenWrt
   or mtd write), boot, enable SSH.
2. SSH in, run the harness. It captures:
   - nvram `boardflags*`, `femctrl`, `devpath`, `boardtype`, `regrev`
     (SPROM cross-check against what our OpenWrt image declares);
   - per radio (eth1 = 2.4 GHz, eth2 = 5 GHz): `wl rev`/`ver` identity,
     current channel, table 0x0a elements at offsets 0x00–0x5f
     (3 cores × 32 bytes), and PHY 0x040a.
3. Compare:
   - table 0x0a values vs `b43_phy_ac_fem_femctrl6` (above);
   - 0x040a bit 8: stock sets it? b43 leaves it clear for femctrl 6 — if
     stock sets it, that is a real divergence to investigate;
   - nvram femctrl/boardflags3 vs our DTS/devpaths (`1:femctrl=6`,
     `0:boardflags3=0x04000000`).
4. Then flash back to OpenWrt (`b39dd6a8...` feature image or the b43-next
   image) — the user already has both.

## Throughput test — what went wrong before and the real numbers

- `iperf3 -i` is the report interval, not an interface selector — the
  earlier `-i wlo1` "fix" was wrong.
- `iw dev wlo1 connect` cannot complete a WPA2-PSK association ("Not
  connected."), so the earlier ~296/~595 Mbit/s numbers ran over the wired
  default route, not Wi-Fi (595 Mbit/s on HT20 2.4 GHz is impossible).
  If those numbers were posted anywhere, correct them.
- Correct method (now in `serve/ac68u-wifi-throughput.sh`): wpa_supplicant
  for the WPA2 association, hard-fail unless `iw dev wlo1 link` shows
  Connected, `/32` route to 192.168.1.200 via wlo1 + `-B <wlo1-ip>` bind.
- Real numbers (Proxmox host M.2 Wi-Fi card as STA, iperf3 TCP 30 s vs
  router, 2026-11-15):

| band | upload (host→router) | download (router→host) |
|---|---|---|
| 5 GHz | 391.7 Mbit/s (retrans 24) | 258.9 Mbit/s (retrans 129) |
| 2.4 GHz | 86.2 Mbit/s (retrans 0) | 44.3 Mbit/s (retrans 137) |

- Note the download-direction retransmits on both bands and the 5 GHz
  asymmetry (391 up vs 259 down) — capture per-chain RSSI/bitrate with
  `serve/ac68u-wifi-linkinfo.sh` (run while OpenWrt is still on the router)
  before reflashing to stock.

## Return channel

`serve/upload-server.py` runs on the agent container (192.168.1.22:8000):
GET serves `serve/` artifacts (e.g. the stock trx) and `GET /inbox/` lists
received reports; `POST /upload/<name>` stores them in `serve/inbox/`.
All three scripts (`ac68u-wifi-linkinfo.sh`, `ac68u-wifi-throughput.sh`,
`ac68u-femctrl6-readback.sh`) print locally and then auto-POST their output
there (`curl`, busybox `wget --post-file` as fallback on ASUS stock), so the
agent reads the report from disk without the user pasting anything.

## Order of operations

1. `ssh root@192.168.1.4 'bash -s' < /root/projects/serve/ac68u-wifi-linkinfo.sh`
   — capture per-chain RSSI/bitrate on OpenWrt (also run `iw dev wlan0/wlan1
   station dump` on the router when it prompts).
2. Post the real throughput numbers to flatstik/egc112 (draft:
   `serve/pr-26717-throughput-post.md`), including the correction of the
   earlier wired-path numbers.
3. Flash ASUS stock, run the read-back harness, capture output.
4. Restore OpenWrt, compare, and reply in aleferri/b43-ac-wip#50.

## Bricking incident and root cause (2026-11-15)

The unit bootlooped after the ASUS stock flash attempts. Root cause: **the CFE
bootloader's firmware ("linux") partition is only 62 MiB** (0x200000–0x4000000),
per the stock RT-AC68U boot log (boot 512K / nvram 1.5M / linux 62M / rootfs).
Anything larger gets truncated by CFE and never boots:

| image | size | result |
|---|---|---|
| OpenWrt b43-next `.trx` | 42,729,472 B (40.8 MiB) | boots |
| Merlin 386.14_2 `.trx` | 98,553,876 B (94.0 MiB) | bootloop |
| ASUS stock 386.49703 `.trx` | 102,625,300 B (97.9 MiB) | bootloop |

Merlin's AC68U image size jumped from ~35 MB (386.4_0) to ~91 MB (386.5_0), so
**386.4_0 (33.6 MiB trx) is the newest Merlin build that fits the CFE
partition**. ASUS/Merlin firmware installed from *within* asuswrt can use the
larger layout; only CFE rescue is limited to 62 MiB.

Flash path that works: **CFE miniWeb HTTP upload** (`POST /f2.htm`,
multipart field `files=`); it reports "Receive file size=" and reboots.
TFTP into CFE (`tftp -m binary ... put`) is flaky (timeouts, rc=69) — use the
HTTP upload. `serve/scripts/webflash <name>` does this from the runner.

Recovery to b43 confirmed: upload `openwrt-b43.trx`, wait ~2 min, OpenWrt comes
back at 192.168.1.200; re-enable radios with
`uci set wireless.radio0.disabled=0; uci set wireless.radio1.disabled=0;
uci commit wireless; wifi up` (the baked wireless config ships disabled=1).
