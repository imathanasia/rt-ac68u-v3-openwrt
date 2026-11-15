#!/bin/sh
# Enable a WPA2 AP on every radio detected by b43, on the router.
# Usage: sh wifi-ap.sh [SSID] [PASSWORD]
# Run after boot when `iw dev` shows the radios.
set -eu
SSID=${1:-OpenWrt}
KEY=${2:-change-me-now}

[ -f /etc/config/wireless ] || wifi config

# enable all radios
for d in $(uci show wireless | sed -n "s/^wireless\.\([^.]*\)=wifi-device$/\1/p"); do
	uci set wireless.$d.disabled='0'
done

# enable/configure every AP interface (the generated default_radioN ifaces)
n=0
for i in $(uci show wireless | sed -n "s/^wireless\.\([^.]*\)=wifi-iface$/\1/p"); do
	mode=$(uci -q get wireless.$i.mode || true)
	[ "$mode" = "ap" ] || continue
	n=$((n+1))
	uci set wireless.$i.disabled='0'
	uci set wireless.$i.ssid="$SSID-$n"
	uci set wireless.$i.encryption='psk2'
	uci set wireless.$i.key="$KEY"
done

[ "$n" -gt 0 ] || { echo "no AP ifaces generated; run: wifi config"; exit 1; }
uci commit wireless
wifi reload
echo "configured $n AP interface(s), SSID prefix $SSID-"
