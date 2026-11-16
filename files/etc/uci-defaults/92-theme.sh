#!/bin/sh
# LuCI 25.12 only ships one compatible theme (the built-in JS one).
# The legacy themes (openwrt2020/material/bootstrap/footstrap) hijack
# luci.main.mediaurlbase and render a blank content area, so pin the default.
uci -q set luci.main.mediaurlbase='/luci-static/bootstrap'
uci -q commit luci
