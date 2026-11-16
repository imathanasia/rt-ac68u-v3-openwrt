#!/bin/sh
# LuCI's dispatcher is a ucode script and uhttpd needs a ucode_prefix that
# points at it.  luci-base's postinst normally adds this, but for packages
# baked into an image that postinst does not always run, and the legacy Lua
# prefix shipped in uhttpd.config then shadows it (/usr/lib/lua/luci/sgi/
# uhttpd.lua no longer exists), so LuCI answers 403.
#
# Make the ucode mapping deterministic and drop the dead Lua one.

uci -q get uhttpd.main.ucode_prefix | grep -sq /cgi-bin/luci || \
	uci add_list uhttpd.main.ucode_prefix='/cgi-bin/luci=/usr/share/ucode/luci/uhttpd.uc'
uci -q delete uhttpd.main.lua_prefix 2>/dev/null

uci commit uhttpd
/etc/init.d/uhttpd restart
