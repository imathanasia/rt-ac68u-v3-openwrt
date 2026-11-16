#!/bin/sh
# Move the writable overlay onto a USB drive (extroot) so extra apps live on USB, not NAND.
# Usage:  ssh root@router  then  sh /root/usb-overlay.sh /dev/sda1
# Partition must be ext4 (mkfs.ext4 -L root /dev/sda1).
set -e
DEV="${1:-/dev/sda1}"
[ -b "$DEV" ] || { echo "device $DEV not found"; exit 1; }
grep -q "$DEV" /proc/mounts && { echo "$DEV is already mounted"; exit 1; }

mkdir -p /mnt/extroot
mount "$DEV" /mnt/extroot

echo "copying overlay -> $DEV ..."
tar -C /overlay -cvf - . | tar -C /mnt/extroot -xf -

echo "writing fstab entry ..."
uci -q delete fstab.overlay
uci set fstab.overlay=mount
uci set fstab.overlay.target='/overlay'
uci set fstab.overlay.device="$DEV"
uci set fstab.overlay.fstype='ext4'
uci set fstab.overlay.options='rw,sync'
uci set fstab.overlay.enabled='1'
uci commit fstab

umount /mnt/extroot
echo "Done. Reboot now:  reboot"
