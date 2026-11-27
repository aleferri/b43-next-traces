# BCM4331 on 5 GHz: `wl` channel sweep, 20 and 40 MHz (mmiotrace)

The source of the radio 2059's 5 GHz 40 MHz channel entries in b43-next (aleferri/b43-next#56).

## Card

- Apple AirPort Extreme card (PCI 14e4:4331, subsystem 106b:00f4) on a PCIe adapter in an x86_64 desktop.
- BCM4331 chip rev 2, D11 core rev 29, HT-PHY rev 1, radio 2059 rev 0 (version 1), dual band.
- BAR0 at 0xfc900000, 16 KiB.

## Tool

- `wl` 6.30.223.271 (the Linux hybrid driver), built for kernel 7.3.6.
- The kernel's mmiotrace. `mmiodec.py` decodes it into PHY, radio and table operations (`PW`/`PR`, `RW`/`RR`,
  `TW`/`TR`, other BAR0 accesses `MW`/`MR`): `mmiodec.py sweep-5g.mmio fc900000`.
- `wlq.c` is a minimal `wl` ioctl tool, used for `mpc` and `chanspec`.

## Procedure

`wl-start.sh` binds the card to `wl` under mmiotrace and brings its interface up, with no association and no
scan. `wl-sweep.sh` then turns `mpc` off and sets one chanspec after another (11ac encoding: 5 GHz
`0xd000 | ch` at 20 MHz, `0xd800 | centre` for the lower sideband and `0xd900 | centre` for the upper one at 40 MHz).
Each one sits between `MARK cs <label> <chanspec>` and `MARK end <label>`, 1.5 s apart:

- 20 MHz: 36, 64, 100, 149, 165, and 36 again at the end (`36b`).
- 40 MHz, lower (`L`) and upper (`U`) sideband: centres 38, 46, 54, 62, 102, 110, 118, 126, 134, 142, 151, 159.

`wl` refused centre 142 (channels 140 and 144) and the 2.4 GHz `2g3L` (0x1803, 40 MHz is not enabled on 2.4 GHz
after a fresh load), so those segments have no channel change. Every other chanspec read back as set.

## Files

- `sweep-5g.mmio.gz`: the raw mmiotrace from the first sweep mark to the end. The attach is left out. Events were
  lost only during the attach, none inside any `cs`/`end` segment.
- `sweep-5g-ops.txt.gz`: the same, decoded with `mmiodec.py`.
- `radio2059-5g.txt`: per chanspec, the first channel setup's radio writes (`syn` 0x16 ... 0x47, `rxtx` 0x4a ... 0x98
  of core 0; cores 1 and 2 write the same) and the first writes of PHY registers 0x1ce-0x1d3 (BW1-6), in the order of
  b43's `b43_phy_ht_channeltab_e_radio2059`. Made with `extract-2059.py sweep-5g-ops.txt`.

The 20 MHz chanspecs write exactly b43's existing entries for 5180, 5320, 5500, 5745 and 5825. The lower and upper
sidebands of each 40 MHz centre write the same values.

The card's MAC address is replaced by 02:00:00:00:00:01 in the RXE address match writes (`MW 0x0422`), and one SHM
read that returned two of its bytes reads 0x0000.
