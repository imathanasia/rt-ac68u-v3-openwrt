#!/bin/sh
# Enable irqbalance.  The three hot interrupts (Ethernet and both radios) are
# banned from it and pinned by hand in /etc/init.d/router-irq, because the
# radio interrupts only exist once the AP interfaces are up.

uci -q set irqbalance.irqbalance.enabled='1'
uci commit irqbalance
[ -x /etc/init.d/irqbalance ] && /etc/init.d/irqbalance enable
