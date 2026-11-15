# Report: ASUS RT-AC68U V3 works with the b43 AC-PHY driver — a femctrl 6 board

**Where to file it** (in order of usefulness):

1. `https://github.com/aleferri/b43-ac-wip/issues` — the driver's own issue
   tracker. This is where board data, FEM tables and driver gaps are tracked.
2. `https://github.com/openwrt/openwrt/pull/26349` — the OpenWrt PR that carries
   the generated snapshot; add a comment with the test result.
3. `https://forum.openwrt.org/` — for the general "it works" announcement.
4. `https://www.snbforums.com/` — the ASUSWRT community (they run this hardware
   and would want to know OpenWrt now has working AC on it).

Suggested title: *"ASUS RT-AC68U V3 (BCM47094 / BCM53011, BCM4360 x2, femctrl 6): both bands work with the b43 AC-PHY driver"*

---

## Why this is new

`phy_ac.c` in the b43 AC-PHY port documents the FEM control tables it knows:

| femctrl | sub | boards with a capture |
|---|---|---|
| 6 | 0 | D6220, DSL-3580L, agcombo, TG789vac |
| 3 | 0 | 5 GHz radio of the R7000, EA6900, R6400 |
| 3 | 3 | 2.4 GHz radio of the R7000, EA6900 |
| 2 | 1 | MacBookAir6,1 |
| 1 | 0 | archer-t5e |

The **ASUS RT-AC68U V3** is a **femctrl 6** board, so it uses the same
`b43_phy_ac_fem_femctrl6` table as the D6220/DSL-3580L/TG789vac set. Until now
no ASUS board has been reported with this radio configuration; the ASUS
BCM4360 boards in the tree (RT-AC66U B1, RT-AC56U) are femctrl 3.

Two further points of interest for the port:

* This board is **BCM47094** (bcma chip `53030`, package `0x02`) with a
  **BCM53011** switch — a different die from the RT-AC68U V1/V2
  (BCM4708A0 / BCM53012). The upstream `asus,rt-ac68u` device tree targets the
  older die, so it leaves the USB 3.0 PHY on the "Ax" init, where a
  SuperSpeed device is never detected. The BCM47094 overrides are the same two
  upstream uses for the Netgear R6400 v2: `brcm,bcm4709-pinmux` and
  `brcm,ns-bx-usb3-phy`.
* The **radio calibration comes from NVRAM**, not from an SROM on the chip:
  `devpath0=pci/1/1` (2.4 GHz), `devpath1=pci/2/1` (5 GHz), with
  `0:`/`1:` prefixes holding the SROM rev 11 fields.

## Hardware

| | |
|---|---|
| Model | ASUS RT-AC68U **V3** (`productid=RT-AC68U`, `boardrev=0x1103`) |
| SoC | BCM47094 family: bcma chip `53030`, package `0x02`, 2× Cortex-A9 |
| Switch | BCM53011 rev 0, integrated 5-port GbE (1 WAN + 4 LAN) |
| RAM / NAND | 256 MiB / 128 MiB Macronix MX30LF1G18AC, SLC, BCH-8 |
| Radios | 2× BCM4360, d11 core rev 42, AC-PHY rev 1, radio `0x2069` rev 4 |
| FEM | `0:boardflags3=0x04000000` (femctrl_sub 0), `1:femctrl=6` |
| Kernel | OpenWrt main, 6.18, mac80211/backports 7.2, PR #26349 snapshot |
| Build | `CONFIG_PACKAGE_kmod-b43=y`, `CONFIG_PACKAGE_B43_PHY_AC=y`, `CONFIG_B43_FW_6_30=y`, squash core revs `29,42`, PHY types `HT,AC`, `CONFIG_PACKAGE_B43_DFS=y` |

## Result

Both radios come up on the first boot, with the FEM tables selected
correctly for femctrl 6:

```
[   16.662726] b43-phy0: Broadcom 4360 WLAN found (core revision 42)
[   16.669247] b43-phy0: Found PHY: Analog 12, Type 11 (AC), Revision 1
[   16.675578] b43-phy0: Found Radio: Manuf 0x17F, ID 0x2069, Revision 4, Version 0
[   16.684858] b43-phy1: Broadcom 4360 WLAN found (core revision 42)
[   16.694596] b43-phy1: Found PHY: Analog 12, Type 11 (AC), Revision 1
[   16.701066] b43-phy1: Found Radio: Manuf 0x17F, ID 0x2069, Revision 4, Version 0
```

Both bands then come up as access points (no probe errors, no
`FOUND UNSUPPORTED PHY`, unlike stock OpenWrt):

```
phy#1   Interface phy1-ap0   type AP  channel 36 (5180 MHz), width: 80 MHz, center1: 5210 MHz
phy#0   Interface phy0-ap0   type AP  channel 1  (2412 MHz), width: 20 MHz
```

## NVRAM excerpts

```
1:femctrl=6
0:boardflags3=0x04000000
1:boardflags3=0x0
devpath0=pci/1/1
devpath1=pci/2/1
```

## Interrupt layout (relevant to the EA6900 write-up)

```
 34:      15920          0 GIC-0 179 Level     eth0
 44:      18086          0 GIC-0 163 Level     b43
 45:      14674          0 GIC-0 169 Level     b43
```

Ethernet and both radios are on CPU0, CPU1 gets nothing — the same layout as
the EA6900, so the irqbalance + pinning recipe from the build-kit README
applies unchanged:

```
eth0 -> CPU1, 2.4 GHz radio (first b43 IRQ) -> CPU1, 5 GHz radio (second b43 IRQ) -> CPU0
```

## Questions for the port author

1. Is the femctrl 6 table correct for a **BCM47094** board (SoC family not
   covered by the captures so far — D6220/DSL-3580L/TG789vac are other
   platforms)? The FEM table is the same, but a capture/read-back on this board
   would confirm it.
2. `boardflags3=0x04000000` on the 2.4 GHz radio sets femctrl_sub 0, so the
   `b43_phy_ac_fem_femctrl6` table is used for both radios here. Worth a note
   in the femctrl comment, since the ASUS boards known so far use femctrl 3.
3. Anyone with an RT-AC68U V3 who can run the `wl-diag`/`wl-mmio-trap`
   harness from `docs/northstar-guide.md` could add an `rt-ac68u-v3` entry to
   `router-data/`, which would make this board a first-class reference.
4. The device tree for the V3 (BCM47094 + BCM53011 + Bx USB 3.0 PHY) is
   available if it is useful as a second 53030 board reference; it is three
   overrides on top of the existing `asus,rt-ac68u` tree.

## Extra notes

* The stock firmware of this model is end-of-life (last ASUS build
  3.0.0.4.386_52102, 2026-05-12) and its web UI has an unpatched
  auth-bypass/RCE (D-Link advisory SAP10294 applies to the same vendor
  generation), which makes a current OpenWrt with working open Wi-Fi a
  meaningful upgrade for these boxes.
* The build with the AC-PHY driver boots and serves both APs with the
  BCM47094 tree; Wi-Fi throughput has not been measured yet (the 2.4 GHz radio
  under 5 GHz load is exactly the case the interrupt pinning addresses).
