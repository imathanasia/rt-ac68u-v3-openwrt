# wl-mmio-trap captures

Two `wl -i <if> down; wl -i <if> up` captures from the RT-AC68U V3 (DD-WRT r66631,
4.4.302-rt232-st80) with `wl-mmio-trap/4-4-arm`. Record format: `wl-mmio-trap/README.md`.

`eth1` = 2.4 GHz (BAR 0x08000000), `eth2` = 5 GHz (BAR 0x20000000).

Note: this is an **ifup** trace, so it starts after the driver attach. It contains PHY register
traffic via 0x3fc/0x3fe and SHM words via 0x160/0x164/0x166, but not the attach-time AC-PHY FEM
table writes (PHY 0x00d = 0x000a followed by 0x00e/0x00f..0x011). See aleferri/b43-ac-wip#50.
