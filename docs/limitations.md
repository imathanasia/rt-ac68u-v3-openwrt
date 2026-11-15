# Limitations

- **AP mode by default**: LAN 192.168.1.200, upstream 192.168.1.1, DHCP off. To make it a
  router: `uci set network.lan.proto=dhcp; uci delete network.lan.gateway;
  uci delete network.lan.dns; uci set dhcp.lan.ignore=0; uci commit; reboot`.
- **No sysupgrade image** for bcm53xx/ASUS: updates are flashed from the CFE recovery page
  (power off, hold reset, power on, `http://192.168.1.1/`).
- **Radios are off by default** and the image is 52 MB; a fresh flash plus the first boot
  takes about three minutes before LuCI answers.
- **AC-PHY Wi-Fi** is open-source b43 work, not the vendor driver: 2.4 GHz is HT20 only,
  5 GHz VHT80 on ch36; 160 MHz and some upper bands are not characterised.
- **LuCI requires a root password**; the image ships `changeme` so the built-in page can be
  reached immediately — change it with `passwd`.
- The page reads status through ubus (`system`, `service`) and only shows service state for
  AdGuard Home, never its credentials.
