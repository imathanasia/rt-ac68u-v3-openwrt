# Wi-Fi test status and remaining checks

## Already verified on the unit (2026‑11‑14, clean flash)

- Both radios probe: `b43-phy0/phy1: Broadcom 4360 WLAN found (core revision 42)`,
  AC‑PHY rev 1, radio `0x2069` rev 4, **no `-95`**.
- The image configures the APs itself on first boot:
  `AC68U-V3-2G` channel 1 / HT20 / 20 dBm, `AC68U-V3-5G` channel 36 / VHT80 / 23 dBm.
- LuCI: login + overview HTTP 200. Dashboard `http://192.168.1.200/router.html` HTTP 200 (legacy `/ac68u.html` redirects).
- Interrupt pinning active: eth0 + 2.4 GHz radio on CPU1, 5 GHz radio on CPU0.
- DNS: dnsmasq → AdGuard Home (191k filter rules) → Quad9 DoH.

## Remaining: client throughput and contention

From a laptop/phone joined to `<SSID>-2G` and `<SSID>-5G` (default key `change-me-now`,
change it first in `/etc/router-wifi.conf`):

```sh
iperf3 -c 192.168.1.200 -P 4      # client -> router
iperf3 -c 192.168.1.200 -P 4 -R   # router -> client
```

Reference from the same driver on other boards: 2.4 GHz HT20 ≈ 140/160, 5 GHz VHT80
≈ 360/380 Mbit/s (EA6900 soak); up to 414/414 on an RT‑AC56U. This board is an 800 MHz
class SoC, so expect somewhat less.

**The important test**: keep a sustained 5 GHz download running and, at the same time, check
that a 2.4 GHz client stays associated and still passes traffic. Without the pinning the
2.4 GHz receive ring overflows under that load, the radio stops acknowledging for 30–90 s and
the client drops while beacons keep going out.

```sh
router-wifi-test            # radios, IRQ spread, driver health, overflow/restart counters
router-wifi-test --watch    # follow the radio interrupts live
router-wifi-test --iperf    # start an iperf3 server on the router
```

## Still open

- USB 3.0 with a real SuperSpeed device (`lsusb -t` should show 5000M; the controller
  already reports `Host supports USB 3.0 SuperSpeed`).
- Long soak (look for `Controller restarted`, ucode fatal, TX queue stall).
- Known upstream issue: an A‑MPDU TX-queue stall (association stays up, downlink stops).
  If seen, it is a driver bug — report at `https://github.com/aleferri/b43-ac-wip/issues`
  with `dmesg`.
- CPU temperature sits around 63–66 °C with all services running; fine, but worth watching
  under load.

## Reporting this board upstream

`docs/upstream-report-ac68u-v3.md` has the full text (first femctrl‑6 ASUS board, first
BCM47094 report). `docs/upstream-report-uhttpd-luci.md` covers the two image/web-UI
findings: `luci-light` missing `uhttpd-mod-ucode`, and uhttpd 2026.11 requiring CGI headers.
