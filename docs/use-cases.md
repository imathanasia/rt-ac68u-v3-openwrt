# What this box does

OpenWrt homelab build for the ASUS RT-AC68U V3 (BCM47094, 2× BCM4360 AC-PHY).

- **Ad blocking** for the whole LAN: AdGuard Home on :53 → DoH upstream, per-device stats.
- **Remote access**: Tailscale (off until a node key exists), WireGuard, OpenVPN, ocserv.
- **Traffic shaping**: SQM/cake on the uplink.
- **Storage**: ksmbd SMB3 share, aria2 on a hot-plugged disk, smartmontools.
- **Visibility**: nlbwmon per device, vnstat2 totals, collectd graphs, speedtest-go.
- **Peripherals**: ser2net, p910nd print server, usbip, WoL/UPnP.
- **Guard rails**: banip, watchcat, mwan3 failover, wifischedule.
- **Wi-Fi on demand**: nothing is transmitted until `wifi-radio on`; `off` stops the APs
  again. The b43 AC-PHY driver stays loaded, the AP interfaces do not exist while off.
- **In-router page**: Services → ★ RT-AC68U — hardware, femctrl 6, service states, recovery
  steps, first-5-minutes checklist, and a Wi-Fi QR when a radio is on.
