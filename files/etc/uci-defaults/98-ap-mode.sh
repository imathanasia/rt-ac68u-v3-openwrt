#!/bin/sh
# Default network layout (RT-AC68U V3 / R7000).
#
# The box is meant to sit behind the main router / cable modem, so it runs in
# AP mode with its own address:
#
#   LAN        : 192.168.1.28/24 on the R7000, 192.168.1.200/24 on the
#                RT-AC68U V3 (SSH lives here)
#   gateway/DNS: 192.168.1.1        (the upstream router)
#   DHCP server: OFF - the upstream router hands out addresses
#   DNS        : clients -> dnsmasq(:53); when AdGuard Home is installed it
#                takes over :53 (UI :3000) and dnsmasq moves to port 0
#
# To turn it into a standalone router later:
#   uci set network.lan.proto='dhcp'
#   uci delete network.lan.gateway
#   uci delete network.lan.dns
#   uci set dhcp.lan.ignore='0'
#   uci commit network; uci commit dhcp; /etc/init.d/network restart
#
# To move it to a different upstream: change the addresses below and the
# upstream_dns / bootstrap_dns in /opt/adguard/AdGuardHome.yaml.

B=$(cat /tmp/sysinfo/board_name 2>/dev/null)
case "$B" in
  *r7000*) LAN_IP="192.168.1.28"; HOST="r7000"; DEFSSID="R7000" ;;
  *)       LAN_IP="192.168.1.200"; HOST="ac68u"; DEFSSID="AC68U-V3" ;;
esac

# Per-board Wi-Fi settings.  /etc/router-wifi.conf is what router-wifi reads;
# it is seeded here with the right SSID for this board.
if [ ! -f /etc/router-wifi.conf ]; then
cat > /etc/router-wifi.conf <<EOC
# Wi-Fi settings for this board.  Edit and run: /etc/init.d/router-wifi restart
SSID="$DEFSSID"
KEY="change-me-now"
COUNTRY="PL"
CH_2G="1"
CH_5G="36"
HTMODE_5G="VHT80"
EOC
fi
uci -q set system.@system[0].hostname="$HOST"
LAN_CIDR="$LAN_IP/24"
UPSTREAM="192.168.1.1"

uci -q set network.lan.proto='static'
uci -q set network.lan.ipaddr="$LAN_IP"
uci -q set network.lan.netmask='255.255.255.0'
uci -q set network.lan.gateway="$UPSTREAM"
uci -q set network.lan.dns="$UPSTREAM"

# the upstream router owns the address space
uci -q set dhcp.lan.ignore='1'

uci commit network
uci commit dhcp

logger -t router-image "AP mode: LAN $LAN_IP, gateway/DNS $UPSTREAM, DHCP server off"
