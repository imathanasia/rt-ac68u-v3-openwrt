#!/bin/sh
# Tailscale is opt-in: the binary ships (or is staged in /opt/tailscale) but
# does not start until it has a node key.  After copying it in:
#   touch /opt/tailscale/enabled && /etc/init.d/tailscale-hl start
#   tailscale --socket=/tmp/tailscaled.sock up
/etc/init.d/tailscale-hl disable 2>/dev/null
/etc/init.d/tailscale-hl stop 2>/dev/null
exit 0
