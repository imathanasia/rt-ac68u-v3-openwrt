#!/bin/sh
# AdGuard Home owns :53 when installed on the internal overlay.
[ -x /opt/adguard/AdGuardHome ] || exit 0
uci -q set dhcp.@dnsmasq[0].port='0'
uci -q commit dhcp
exit 0
