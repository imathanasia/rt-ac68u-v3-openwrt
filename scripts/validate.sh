#!/bin/sh
# Static validation of the experimental AC-PHY image. No device access.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
IMG=${IMG:-$HERE/images/openwrt-AC68U-V3-homelab-v3.1.trx}
TREE=${TREE:-$HERE/../openwrt-acphy}

echo "== size / hash"
stat -c '%s bytes' "$IMG"; sha256sum "$IMG"
python3 - "$IMG" <<'EOF'
import os,sys
s=os.path.getsize(sys.argv[1]); print(f"{(32*1048576-s)/1048576:.2f} MiB headroom vs 32 MiB")
EOF

echo "== TRX / product id"
"$TREE/staging_dir/host/bin/otrx" check "$IMG"
grep -abo 'RT-AC68U' "$IMG" | tail -1

echo "== manifest"
M=$HERE/config/manifest.txt
for p in luci luci-ssl luci-app-firewall kmod-b43 wpad-basic-mbedtls kmod-usb3; do
	grep -q "^$p " "$M" && echo "present $p" || { echo "MISSING $p"; exit 1; }
done

echo "== firmware files"
R=$TREE/build_dir/target-arm_cortex-a9_musl_eabi/linux-bcm53xx_generic/root.squashfs
unsquashfs -l "$R" 2>/dev/null | grep -E 'firmware/b43/(ucode42|ac1initvals42|ac1bsinitvals42)\.fw'

echo "== AC-PHY symbols in b43.ko"
KO=$TREE/build_dir/target-arm_cortex-a9_musl_eabi/linux-bcm53xx_generic/mac80211-regular/backports-7.2/drivers/net/wireless/broadcom/b43/b43.ko
nm "$KO" 2>/dev/null | grep -q 'b43_5ghz_acphy_chantable' && echo "AC-PHY tables present" || { echo "AC-PHY missing"; exit 1; }

echo "OK (static only; boot/radios unverified)"
