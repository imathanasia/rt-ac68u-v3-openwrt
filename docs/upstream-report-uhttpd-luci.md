# Upstream report: two LuCI/uhttpd problems found while building a custom image

These broke the web UI in a from-source image on OpenWrt main (2026‑11). Both were
reproduced on a real device (ASUS RT-AC68U V3, kernel 6.18.60, uhttpd
`2026.11.05~93b05e0b-r1`, LuCI `26.316.56866`).

## 1. `luci-light` does not pull `uhttpd-mod-ucode`

`feeds/luci/collections/luci-light/Makefile` depends on `uhttpd` and `uhttpd-mod-ubus`
only. In this LuCI version the dispatcher `/www/cgi-bin/luci` is a **ucode** script
(`#!/usr/bin/env ucode`, `import dispatch from 'luci.dispatcher'`), which uhttpd can only
run through the `uhttpd-mod-ucode` plugin. Without it every LuCI request answers:

```
HTTP/1.1 403 Forbidden
x-luci-login-required: yes
```

(It looks like an auth problem; it is not — the login form is never reached.)

A second trap: the stock `/etc/config/uhttpd` still ships

```
list lua_prefix "/cgi-bin/luci=/usr/lib/lua/luci/sgi/uhttpd.lua"
```

but the Lua SGI dispatcher is gone from this LuCI. If `uhttpd-mod-lua` is installed, that
stale mapping shadows the ucode handler and LuCI keeps returning 403 even with the ucode
plugin present.

`luci-base`'s postinst *does* add the right mapping:

```
uci add_list uhttpd.main.ucode_prefix='/cgi-bin/luci=/usr/share/ucode/luci/uhttpd.uc'
```

but for packages baked into an image that postinst does not run on first boot — at least in
an apk-based main image written with `sysupgrade -n`, the option was absent after boot.

**Suggested fixes**
- add `+uhttpd-mod-ucode` to `luci-light`'s `LUCI_DEPENDS`;
- drop the dead `lua_prefix` line from `package/network/services/uhttpd/files/uhttpd.config`
  (or only emit it when `uhttpd-mod-lua` is installed);
- make the ucode_prefix setup idempotent at first boot (uci-defaults) instead of relying on
  the package postinst.

## 2. uhttpd 2026.11 requires CGI-style headers, otherwise 502

With uhttpd `2026.11.05`, a CGI script that writes a raw body (no `Status:`/`Content-Type:`
header block) gets

```
HTTP/1.1 502 Bad Gateway
The process did not produce any response
```

because the new dispatch/relay path (`proc.c: proc_handle_close()`) only forwards a response
once the child produced a header block. A script that prints
`Status: 200 OK\r\nContent-Type: …\r\n\r\n…` works. This is a behaviour change from older
uhttpd, where a raw body was relayed as-is, and it silently broke a small status CGI used by
this build.

**Suggested fix**: either document it (CGI must emit headers) or keep relaying a body when
the child exits without headers, as older versions did.
