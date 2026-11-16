#!/bin/sh
# flash-ml only mounts an already-created "flash" volume. AdGuard and
# Tailscale stay disabled until their binaries are installed; 96-tailscale-off
# is the later opt-in gate and must not be undone here.
/etc/init.d/flash-ml enable 2>/dev/null
exit 0
