# Build

## Source

- Repo: `https://github.com/flatstik/AC66U_B1` branch `b43-ac-phy`
- Commit: `25058cf725f1994e5d5b4f012d321ecec5ef413d` (2026-11-10)
- This is OpenWrt main + PR #26349 (3 commits):
  1. `target/linux/bcm53xx/patches-6.18/880-bcma-ssb-support-the-BCM4352-BCM4360-family.patch`
  2. mac80211: b43 firmware 784.2 (B43_FW_6_30)
  3. mac80211: b43 AC-PHY support (`816-02`, `816-03`, `817`)
- Kernel 6.18, mac80211/backports 7.2.

## Host

Debian/Ubuntu build deps as usual; run as root with `FORCE_UNSAFE_CONFIGURE=1`.

## Steps

```sh
git clone --depth 1 --branch b43-ac-phy https://github.com/flatstik/AC66U_B1.git
cd AC66U_B1

./scripts/feeds update -a
./scripts/feeds install -a

# config/acphy.seed (or config/config.acphy from the built image)
cp ../ac68u-acphy-openwrt/config/config.acphy .config   # full built config
FORCE_UNSAFE_CONFIGURE=1 make defconfig

# b43 AC-PHY firmware tarball (lwfinger is gone; obtained from Wayback)
# sha256 a07c3b6b277833c7dbe61daa511f908cd66c5e2763eb7a0859abc36cd9335c2d
mkdir -p dl && cp broadcom-wl-6.30.163.46.tar.bz2 dl/

FORCE_UNSAFE_CONFIGURE=1 make -j"$(nproc)"
```

Config essentials:

- `CONFIG_TARGET_bcm53xx_generic_DEVICE_asus_rt-ac68u=y`
- `CONFIG_PACKAGE_kmod-b43=y`, `CONFIG_PACKAGE_B43_PHY_AC=y`
- `CONFIG_B43_FW_6_30=y`, `CONFIG_B43_FW_SQUASH=y`
- `CONFIG_B43_FW_SQUASH_COREREVS="29,42"`,
  `CONFIG_B43_FW_SQUASH_PHYTYPES="HT,AC"`
- `CONFIG_PACKAGE_wpad-basic-mbedtls=y`
- optional: LuCI, SQM, WireGuard, USB storage, ttyd

## Reproduced result

- First build (minimal): 2026-11-14 00:23 → 00:58 UTC (~35 min incl. toolchain).
- Second build (LuCI + apps, incremental): 01:04 → 01:13 UTC (~9 min).
- Output: `bin/targets/bcm53xx/generic/openwrt-bcm53xx-generic-asus_rt-ac68u-squashfs.trx`
- 12,713,984 B, sha256 `846a4e9c…407aef`.

## Notes

- The image is deliberately from an unmerged PR; upstream `openwrt-25.12` 6.12
  cannot take these patches cleanly (fuzz miscompiles b43).
- No kernel/bootloader modification is performed by the image; ASUS recovery
  can restore stock firmware.
