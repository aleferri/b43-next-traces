R7000 (BCM4709, DD-WRT r66097M, kernel 4.4.302-rt232-st78), wl 7.14.164.18, eth1 = 2.4 GHz BCM4360 rev 3 (0001:01:00.0, BAR0 0x08000000)
wl-mmio-trap 4-4-arm at bb6a455a + wl-mmio-trap-arm-fixes.diff, loaded as:
  insmod wl_mmio_trap.ko autoarm=0 win_phys=0x08000000 win_phys_len=0x8000 fsr_info_fn7=0x8055de04 init_mm_addr=0x80564928 fifo_recs=2097152 poll_secs=10
(both addresses from System.map; window found = 4 pages / 16 KiB at 8b158000)
Sequence (run.log): nas/wland killed, eth1/eth2 out of the bridges, rmmod wl; insmod wl (attach NOT traced), trap loaded, then under the trap:
  mark cold-2g6 | on | wl ap 1 | mark chanspec | wl chanspec 6 | mark up | wl up | sleep 10 | mark ssid | wl ssid test-ap | mark bss-up | wl bss up | sleep 10 | mark beaconing | off | mark done
Mark labels decode byte-swapped per 32-bit word ('dloc6g2-' = 'cold-2g6', '' = 'up', 'diss' = 'ssid', '-ssb' = 'bss-', 'caebnino' = 'beaconin').
cold-2g6-full.bin  52628 records (52621 emulated + 7 marks), seq contiguous, drops 0, mismatch 0
cold-2g6-ops.txt   reverse-tools/mmio2ops.py --format wl-mmio-trap-arm output
