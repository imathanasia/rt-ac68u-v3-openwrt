#!/bin/sh
# Phone as a backup WAN over USB tethering (RNDIS/NCM).
# The interface only comes up when a tethering phone appears as usb0; the LAN
# gateway stays the preferred default route (metric 20 here).
uci -q set network.tether=interface
uci -q set network.tether.device='usb0'
uci -q set network.tether.proto='dhcp'
uci -q set network.tether.metric='20'
uci -q set network.tether.defaultroute='1'
uci -q commit network
