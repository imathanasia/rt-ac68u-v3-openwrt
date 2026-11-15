# femctrl 6 on the RT-AC68U V3 — what the capture actually shows

Hardware: BCM47094 + 2× BCM4360 (d11 rev 42, AC-PHY rev 1, radio 0x2069 rev 4); nvram reports
`0:femctrl=6` and `1:femctrl=6`. DD-WRT r66631 (`4.4.302-rt232-st80`), vendor `wl` 7.14.164.18.

We captured `wl -i eth1 down/up` and `wl -i eth2 down/up` with `wl-mmio-trap/4-4-arm`
(raw traces in `traces/`). **Correction (flatstik, b43-ac-wip#50):** the earlier decode was wrong.
`0x3fc`/`0x3fe` are the PHY register address/data pair (`B43_MMIO_PHY_CONTROL`/`PHY_DATA`), and
`0x160`/`0x164`/`0x166` are shared-memory control/data, not PHY registers. So:

- values like `0x0a40` are **PHY register 0x0a40**, not "table 0x0a, offset 0x40";
- the `0x040a`/`0x0414`/`0x0418` words seen at `0x164` are **SHM** traffic, not PHY registers;
- re-decoding the traces for AC-PHY table writes (PHY `0x00d` = `0x000a`, then `0x00e` offset and
  `0x00f`..`0x011` data) finds only three clearing writes and no FEM table content.

**Why:** the FEM table is written at **driver attach**, and our capture starts at interface
up. An attach capture (`rmmod wl`; `insmod wl` with the trap armed, `autoarm=1 poll_ms=0`) is what
is needed to read table 0x0a and PHY 0x040a/0x0414/0x0418. The ifup traces are still useful: they
carry the PHY register stream (0xa40 range) and the SHM mailbox traffic.

Status: attach capture not yet taken (would need one more DD-WRT session); the question is open in
aleferri/b43-ac-wip#50.
