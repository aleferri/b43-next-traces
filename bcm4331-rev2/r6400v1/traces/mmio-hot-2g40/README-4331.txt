BCM4331 MMIO traces - Netgear R6400 v1, DD-WRT r66097M (own build, 128K nvram variant), 2026-11-12

Board / radio
  SoC BCM4708 (Northstar), kernel 4.4.302-rt232-st78 (ARM Cortex-A9, SMP)
  2.4 GHz radio = eth1, PCIe 0001:01:00.0, BAR0 0x08000000 (16 KiB)
  wl revinfo: vendorid 0x14e4 deviceid 0x4332 chipnum 0x4331 chiprev 0x2 corerev 0x1d (29)
              radiorev 0x2059000 boardid 0x646 boardvendor 0x14e4 boardrev 0x1601
              driverrev 0x70ea412 (wl 7.14.164.18) ucoderev 0x3a02716
  HT-PHY rev 1, radio 2059, sromrev 9 data from the CFE nvram, external PA/LNA
  Locale SU: 20 MHz ch 1-11, 40 MHz 1l-7l + 5u-11u

Tool
  wl-mmio-trap/4-4-arm from aleferri/b43-ac-wip main c6ecb0c, built against this kernel tree with the GCC that
  built it (OpenWrt GCC 13.1.0), KBUILD_CFLAGS_MODULE=-DMODULE.
  insmod wl_mmio_trap.ko autoarm=0 win_phys=0x08000000 win_phys_len=0x4000 fsr_info_fn7=0x8055de0c
         init_mm_addr=0x80564968 fifo_recs=2097152 poll_secs=10
  -> "selftest passed: trapped, decoded, resumed", window 4/4 pages contiguous.
  Reader: dd if=/proc/wl_mmio_trap bs=28 over ssh. Decoded with reverse-tools/mmio2ops.py (main 7bc6476),
  --format wl-mmio-trap. Every run: drops 0, and emulated + marks = file size / 28.

Procedure (cold.sh / hot.sh in this zip have the exact command lines; run-*.log = what each step returned)
  Before all runs: DD-WRT's check_ps (cron, every 2 min) re-runs wlconf + nas from nvram as soon as it sees nas
  missing, which re-initialises the radio mid-capture. Disabled for the captures (/tmp/.startmon renamed).
  nas/wland killed, eth1/eth2 out of the bridge. One 5 GHz nas (eth2) survived the killall; it only talks to eth2,
  which is down and outside the traced BAR.

  COLD (one file per chanspec): rmmod wl; insmod wl (the attach is NOT in the trace); trap loaded; then traced:
    mark <label> | on | wl ap 1 | [mark bwcap: wl bw_cap 2g 3] | mark chanspec: wl chanspec X |
    mark up: wl up, 10 s | mark ssid: wl ssid test-ap | mark bss-up: wl bss up, 10 s beaconing |
    mark beaconing | off | mark done
  A fresh insmod allows only 20 MHz on 2.4 GHz (bw_cap 2g = 0x1; DD-WRT's wlconf normally raises it), so the
  40 MHz runs set bw_cap 2g 3 first, under the trap (4 status reads on the bus).
  Chanspecs: 6, 1, 11 (20 MHz) and 6l, 1l, 11u (40 MHz). Labels are cut to 12 characters by the trap
  ('cold-2g11u-4' = cold-2g11u-40).

  HOT (one file per width): one rmmod/insmod, an UNTRACED warm-up (ap 1, [bw_cap 2g 3], chanspec 6, up 10 s,
  down), then the trap and per chanspec:
    mark ch-X: wl chanspec X | mark up-X: wl up, 10 s | mark ssid-X: wl ssid test-ap + wl bss up, 5 s |
    mark down-X: wl bss down + wl down
  hot-2g-20: ch 1..11.   hot-2g-40: 1l 2l 3l 4l 5l 6l 7l 5u 6u 7u 8u 9u 10u 11u.
  After each cycle the run log shows the chanspec the radio was really on ("on: ..."): all as requested.

Results
  file              accesses  ops (decoded)  up     ssid    bss-up
  cold-2g6-20         62480     39863       8728   26826    4302
  cold-2g1-20         71543     48985       8607   26949   13422
  cold-2g11-20        67321     44841       8607   26816    9411
  cold-2g6l-40        71229     48263       8843   35235    4177
  cold-2g1l-40        80733     57775       8635   36019   13113
  cold-2g11u-40       74723     51822       8637   35295    7882
  hot-2g-20          440828    338821   (per channel: up-X ~21 ops, ssid-X ~29-34k)
  hot-2g-40          683321    548183

  As on the R7000's 2.4 GHz radio, the bulk of the PHY init runs at the BSS start (ssid / bss up), not at `up`.
  In the hot sweeps `wl up` alone does ~21 accesses; the whole per-channel init comes with ssid + bss up.

  HT-PHY table writes (*-tables.txt, from httab.py: PHY 0x072 = id << 10 | offset, 0x074 = high half first,
  0x073 = low half, offset +1 per 0x073 access - my parse, check it against your own decoding):
    up:      0x00 0x01 0x02 0x03 0x04(reads) 0x07 0x08 0x0d 0x12 0x1a 0x1b 0x1c 0x1f-0x24 0x25 0x26 0x27 0x28 0x29 0x2f
    ssid:    0x00 0x01 0x02 0x03 0x04(reads) 0x07 0x08 0x0d 0x11 0x1a 0x1b 0x1c 0x25 0x28 0x29
    bss-up:  0x08
  The same set in all six cold runs. The one 20/40 difference: table 0x11 (sample-play / tone table) is written
  4160x over 160 entries at 20 MHz and 8320x over 320 entries at 40 MHz.

Files
  cold-*.bin, hot-*.bin       raw wl-mmio-trap records (28 bytes each)
  *-ops.txt                   mmio2ops.py output
  *-tables.txt                HT-PHY table writes per mark (httab.py)
  run-*.log                   the steps and their return codes, the "on:" chanspec check, the trap's unload line
  cold.sh, hot.sh, httab.py   the scripts
