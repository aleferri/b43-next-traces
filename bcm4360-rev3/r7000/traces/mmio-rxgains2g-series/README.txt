rxgains2g series, 2026-11-02 ~11:50 (#20)

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

NVRAM: pci/1/1/rxgains2g{elnagain,triso,trelnabyp}a0-2 set to the same values on all three cores (shipped: 3 / 7 / 1)

| capture | radio, channel | NVRAM / result | raw records | decoded ops |
|---|---|---|---|---|
| rxg-r0-3-7-1 | eth1 2g6/20 (0x1006) | elna 3, triso 7, byp 1 (as shipped) | 113826 | 75055 |
| rxg-a-6-13-1 | eth1 2g6/20 (0x1006) | elna 6, triso 13, byp 1 (the RT-AC66U B1) | 113408 | 74775 |
| rxg-c-6-7-1 | eth1 2g6/20 (0x1006) | elna 6, triso 7, byp 1 | 340437 | 235277 |
| rxg-b-4-7-1 | eth1 2g6/20 (0x1006) | elna 4, triso 7, byp 1 (the EA6900) | 114005 | 75277 |
