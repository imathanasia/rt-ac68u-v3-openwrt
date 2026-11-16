#!/bin/sh
# Baked default credentials for the homelab image; change with `passwd`.
printf 'changeme\nchangeme\n' | passwd root >/dev/null 2>&1
exit 0
