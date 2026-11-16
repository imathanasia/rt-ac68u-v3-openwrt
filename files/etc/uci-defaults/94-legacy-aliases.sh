#!/bin/sh
# Compatibility aliases for the pre-25.12 AC68U image names.  They are created
# only on the RT-AC68U V3; other boards get no AC68U-named files at all.

[ "$(cat /tmp/sysinfo/board_name 2>/dev/null)" = "asus,rt-ac68u-v3" ] || exit 0

ln -sf router-wifi /etc/init.d/ac68u-wifi
ln -sf router-irq /etc/init.d/ac68u-irq
ln -sf router-wifi-ap /usr/bin/ac68u-wifi-ap
ln -sf router-wifi-test /usr/bin/ac68u-wifi-test
ln -sf router.html /www/ac68u.html
ln -sf router-status /www/cgi-bin/ac68u-status
[ -f /etc/router-wifi.conf ] && ln -sf router-wifi.conf /etc/ac68u-wifi.conf
[ -f /etc/router-irq-affinity ] && ln -sf router-irq-affinity /etc/ac68u-irq-affinity

exit 0
