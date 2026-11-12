three checks of #11, 2026-11-02 08:03-08:07

R7000 (BCM4709, DD-WRT r66097M, kernel 4.4.302-rt232-st78), wl 7.14.164.18. eth1 = 2.4 GHz BCM4360 rev 3
(0001:01:00.0, BAR0 0x08000000), eth2 = 5 GHz (0002:01:00.0, BAR0 0x40000000).
wl-mmio-trap 4-4-arm at bb6a455a + the ARM fixes merged in #7, loaded as for mmio-cold-2g6.zip:
  insmod wl_mmio_trap.ko autoarm=0 win_phys=<BAR0> win_phys_len=0x8000 fsr_info_fn7=0x8055de04 init_mm_addr=0x80564928 fifo_recs=2097152 poll_secs=10
Per capture: nas/wland killed, eth1/eth2 out of the bridges, rmmod wl; insmod wl (attach NOT traced, but wl reads
its NVRAM there: that is why every NVRAM change below is followed by a reload), trap loaded, then under the trap:
  mark <label> | on | wl ap 1 | mark chanspec | wl chanspec <ch> | mark up | wl up | sleep 8 | mark ssid | wl ssid <ssid> |
  mark bss-up | wl bss up | sleep 8 | [channel change, a-2g-ch1to11 only] | mark beaconing | off | mark done
NVRAM changes are `nvram set` / `nvram unset` in RAM only, never committed; after each session the NVRAM was
compared with a backup taken before it: the only difference was DD-WRT's runtime `probe_blacklist` (+eth0).
Files per capture: <label>.bin (raw stream, read with dd bs=28), <label>-ops.txt (decoded; byte-identical to what
mmio2ops.py --format wl-mmio-trap-arm gives, checked on mmio-cold-2g6), <label>-run.log (the commands' output).
The decoder reported no dropped records for any capture. Mark labels decode byte-swapped per 32-bit word.

NVRAM: per capture, see the table (each restored before the next)

| capture | radio, channel | NVRAM / result | raw records | decoded ops |
|---|---|---|---|---|
| a-2g-ch1to11 | eth1 2g1/20 (0x1001), then under the trace bss down / down / chanspec 11 / up / ssid / bss up (0x100b) | as shipped: tbl 7 [0x80] = 0x0078 at #7746, #21988, #74064, #174655 | 301453 | 210392 |
| b-5g-bf2bit21off | eth2 5g36/80 (0xe02a) | pci/2/1/boardflags2 0x300002 -> 0x100002 (bit 21 cleared): no tbl 7 [0x80] write | 146246 | 98418 |
| c-2g-mvalid0 | eth1 2g1/20 (0x1001) | pci/1/1/pdoffset2g40mvalid 1 -> 0 (ma0-2 = 15): tbl 0x21 entry 5 = 0x00ffffff (#16615/#16616) | 117890 | 79233 |
