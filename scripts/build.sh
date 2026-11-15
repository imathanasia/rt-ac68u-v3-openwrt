#!/bin/sh
# Rebuild the experimental AC-PHY image.
# Source: flatstik/AC66U_B1 branch b43-ac-phy @ 25058cf725f1994e5d5b4f012d321ecec5ef413d
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TREE=${TREE:-$HERE/../openwrt-acphy}
COMMIT=25058cf725f1994e5d5b4f012d321ecec5ef413d

if [ ! -d "$TREE/.git" ]; then
	git clone --depth 1 --branch b43-ac-phy https://github.com/flatstik/AC66U_B1.git "$TREE"
fi
cd "$TREE"
git rev-parse --verify "$COMMIT" >/dev/null 2>&1 && git checkout -q "$COMMIT" || true

./scripts/feeds update -a
./scripts/feeds install -a

CFG=${CFG:-$HERE/config/config.acphy}
cp "$CFG" .config
FORCE_UNSAFE_CONFIGURE=1 make defconfig

# b43 AC-PHY firmware (Broadcom wl 6.30.163.46 via b43-fwcutter)
FW=broadcom-wl-6.30.163.46.tar.bz2
mkdir -p dl
if [ ! -s "dl/$FW" ]; then
	for d in "$HERE/../openwrt/dl" "$HERE/../openwrt-acphy/dl"; do
		[ -s "$d/$FW" ] && { cp "$d/$FW" dl/; break; }
	done
fi
[ -s "dl/$FW" ] || {
	echo "Missing dl/$FW (sha256 a07c3b6b277833c7dbe61daa511f908cd66c5e2763eb7a0859abc36cd9335c2d)." >&2
	echo "Obtain broadcom-wl-6.30.163.46 source and place it in dl/." >&2
	exit 1
}

FORCE_UNSAFE_CONFIGURE=1 make -j"$(nproc)"

ls -l bin/targets/bcm53xx/generic/openwrt-bcm53xx-generic-asus_rt-ac68u-squashfs.trx
sha256sum bin/targets/bcm53xx/generic/openwrt-bcm53xx-generic-asus_rt-ac68u-squashfs.trx
