#!/bin/sh
# AC68U V3 - radios stay OFF unless asked.
#
# This box lives in a room where nobody should be sitting in a Wi-Fi field,
# so the APs are not started at boot.  The b43 AC-PHY driver still loads and
# both phys still register; only the AP interfaces are left down, so nothing
# is transmitted.
#
#   wifi-radio on      start the APs (SSID/KEY from /etc/ac68u-wifi.conf)
#   wifi-radio off     stop them again
#   wifi-radio status  show phy/interfaces
#
# The setting survives reboots: /etc/init.d/ac68u-wifi stays disabled until
# "wifi-radio on" runs once.

for dev in $(uci show wireless 2>/dev/null | sed -n "s/^wireless\.\([^.]*\)=wifi-device$/\1/p"); do
	uci -q set wireless.$dev.disabled='1'
done
uci -q commit wireless
/etc/init.d/ac68u-wifi disable 2>/dev/null
wifi down 2>/dev/null
exit 0
