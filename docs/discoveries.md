# What was repaired and discovered (2026-11-15)

## Flashing
- The V3 boots DD-WRT's `asus_rt-ac68u` image (same BCM47094 + 2× BCM4360 as the B1).
- **DD-WRT cannot flash this OpenWrt image**: its `linux` mtd partition is 30 MB and the
  image is 52 MB. DD-WRT's upgrade page answers "success" and reboots into the *old* firmware.
  The CFE recovery page (`http://192.168.1.1/`, POST to `/f2.htm`) writes the whole trx at
  0x1e0000 and works; it reports `Receive file size=` 48 bytes above the file size.
- The AC-PHY image is an ASUS `HDR0` trx; CFE accepts it directly.

## Build traps hit
- **Initramfs**: with the homelab packages the initramfs trx exceeds its 32 MiB cap
  (`trx -m 33554432`). Only the squashfs image is built now
  (`# CONFIG_TARGET_ROOTFS_INITRAMFS is not set`); the squashfs/asus-trx path is not capped.
- Package resolution is clean: `make defconfig` selected all added packages on the
  `b43-ac-phy` tree (feeds: base, packages, luci, routing, telephony).

## Runtime repairs
- **LuCI answered 403** (`x-luci-login-required: yes`) until `root` had a password: an
  OpenWrt image with an empty root password lets SSH in but LuCI refuses the session.
  Set it with `passwd`, then restart `rpcd` and `uhttpd`.
- **Radios off by default** is not enough to be silent: `router-wifi` is disabled and
  `/etc/uci-defaults/95-wifi-off.sh` forces every `wifi-device` to `disabled=1`.
  `wifi-radio on|off|status` is the only switch needed.
- **Tailscale** ran unauthenticated at every boot; now disabled until a node key exists
  (`/etc/uci-defaults/96-tailscale-off.sh`). AdGuard Home stays on.

## Hardware facts confirmed
- femctrl 6 on both radios; table 0x0a and `phyreg 0x040a = 0x0532` read-back captured with
  the wl-mmio-trap and posted to aleferri/b43-ac-wip#50 (see `femctrl6-readback.md`).

## Management path
- The router sits on a separate L2 segment from the LAN, so its UI is reached through a
  TCP forwarder on the Proxmox host: `8181 -> 192.168.1.200:80`, `2222 -> :22`.
