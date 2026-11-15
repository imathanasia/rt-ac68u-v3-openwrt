# Optional packages

Not in the image, safe to add with `apk add`:

| Package | Why |
|---|---|
| `luci-app-diskman` | partition/format disks from the UI |
| `luci-app-hddinfo`, `hddidle` | spin-down and SMART details for USB disks |
| `luci-app-wol` | wake-on-LAN (already present as `luci-app-wol`) |
| `nmap`, `tcpdump`, `iperf3` | diagnostics |
| `luci-app-openvpn` | server UI (openvpn itself is installed) |
| `mosquitto-ssl`, `nut` | MQTT and UPS monitoring |
| `collectd-mod-sensors/disk/processes` | extra graphs (feeds grow them on demand) |

Heavy options to avoid on 256 MB: `docker`, full `python3` stacks, `adblock` together with
AdGuard Home (redundant DNS filtering).
