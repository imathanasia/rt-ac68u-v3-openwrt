#!/bin/sh
# AdGuard Home is opt-in: the image ships without the binary.  The image build
# auto-enables every rc.common init script, so disable ours again until a
# binary is actually installed in /opt/adguard.
if [ ! -x /opt/adguard/AdGuardHome ]; then
	/etc/init.d/adguard-hl disable 2>/dev/null
	/etc/init.d/adguard-hl stop 2>/dev/null
fi
exit 0
