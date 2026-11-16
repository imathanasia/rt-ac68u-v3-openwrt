#!/bin/sh
# Project branding: version string shown by LuCI, SSH banner and ubus.
B=$(cat /tmp/sysinfo/board_name 2>/dev/null)
case "$B" in
  *r7000*) DESC="OpenWrt 25.12 (r0-25058cf) · Netgear R7000 mod by ImAthanasia" ;;
  *)       DESC="OpenWrt 25.12 (r0-25058cf) · RT-AC68U V3 mod by ImAthanasia" ;;
esac
for f in /etc/openwrt_release /usr/lib/os-release; do
	[ -f "$f" ] || continue
	if grep -q '^DISTRIB_DESCRIPTION=' "$f"; then
		sed -i "s#^DISTRIB_DESCRIPTION=.*#DISTRIB_DESCRIPTION='$DESC'#" "$f"
	elif grep -q '^PRETTY_NAME=' "$f"; then
		sed -i "s#^PRETTY_NAME=.*#PRETTY_NAME=\"$DESC\"#" "$f"
	fi
done
exit 0
