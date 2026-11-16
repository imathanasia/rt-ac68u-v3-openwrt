# Netgear R7000 — probe plan (not part of this build yet)

Same silicon family as the V3: BCM4709A0, 2× BCM4360 (AC-PHY), 256 MB RAM, 128 MB NAND.
The AC-PHY patches and this repo's page/branding port 1:1.

## Getting in (CFE over TFTP, no serial)
1. Power off. Hold **reset**, power on, keep holding ~8 s, release.
2. CFE answers at `192.168.1.1`; it serves TFTP for a short window.
3. From the Proxmox host: `tftp 192.168.1.1` → `binary` → `put <image>.chk`.
   (`serve/scripts/tftpflash` automates this.)
4. First bring-up preference: **RAM-boot an OpenWrt initramfs** (`openwrt-...-initramfs.trx`)
   and inspect before writing NAND.

## What to capture on the first boot
- `dmesg | grep -iE "b43|brcmfmac|pcie|nand"` — which driver claims the radios.
- `lspci -nn`, `/proc/bus/pci/devices` — BARs for both 4360s.
- `cat /proc/mtd`, `cat /proc/cmdline`, `ubus call system board`.
- `iw phy` (after `wifi-radio on`) — bands/channels the AC-PHY exposes.
- Thermal/load baseline: `uptime`, `free -m`, `/sys/class/thermal/*`.

## Build
`CFG=config/config.r7000 scripts/build.sh` with a R7000 device config; profile
`netgear_r7000` in bcm53xx. Image is a `.chk`.
