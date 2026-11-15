#!/bin/sh
# Tailscale stays off until it has a node key: an unauthenticated tailscaled
# just retries in the background.  After "tailscale up" once:
#   /etc/init.d/tailscale enable && /etc/init.d/tailscale start
/etc/init.d/tailscale disable 2>/dev/null
/etc/init.d/tailscale stop 2>/dev/null
exit 0
