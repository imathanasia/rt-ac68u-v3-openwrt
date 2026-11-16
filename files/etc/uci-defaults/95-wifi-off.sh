#!/bin/sh
# Radios stay OFF unless asked (all supported boards).
#
# This box lives in a room where nobody should be sitting in a Wi-Fi field,
# so the APs are not started at boot.  The b43 AC-PHY driver still loads and
# both phys still register; only the AP interfaces are left down, so nothing
# is transmitted.
#
#   wifi-radio on      start the APs (SSID/KEY from /etc/router-wifi.conf)
#   wifi-radio off     stop them again
#   wifi-radio status  show phy/interfaces
#
# The setting survives reboots: /etc/init.d/router-wifi stays disabled until
# "wifi-radio on" runs once.

# The b43 phys register ~15 s after boot, and OpenWrt only writes
# /etc/config/wireless then, so wait for the wifi-device sections.
n=0
while [ $n -lt 40 ]; do
	[ -n "$(uci -q show wireless | sed -n 's/^wireless\.\([^.]*\)=wifi-device$/\1/p')" ] && break
	sleep 2; n=$((n+1))
done
for dev in $(uci show wireless 2>/dev/null | sed -n "s/^wireless\.\([^.]*\)=wifi-device$/\1/p"); do
	uci -q set wireless.$dev.disabled='1'
	for ifc in $(uci show wireless | sed -n "s/^wireless\.\([^.]*\)=wifi-iface$/\1/p"); do
		[ "$(uci -q get wireless.$ifc.device)" = "$dev" ] && uci -q set wireless.$ifc.disabled='1'
	done
done
uci -q commit wireless
/etc/init.d/router-wifi disable 2>/dev/null
wifi down 2>/dev/null
exit 0
