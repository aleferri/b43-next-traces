5 GHz rx gains per sub-band, 2026-11-02 ~14:00-14:30 (#20)

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

NVRAM: shipped: rxgains5g* elna 4/4/4 triso 7/6/5; 5gm 3/4/4, 5/4/4; 5gh 3/3/4, 5/4/4; trelnabyp 1; subband5gver 0x4

| capture | radio, channel | NVRAM / result | raw records | decoded ops |
|---|---|---|---|---|
| s5-a-149-80 | eth2 5g149/80 (0xe09b) | as shipped. `wl ssid` failed ("Not up", rc 211), so no BSS came up; the bring-up to `up` is complete and its AGC block equals s5-b | 40737 | 21686 |
| s5-b-100-80 | eth2 5g100/80 (0xe06a) | as shipped | 143247 | 95363 |
| s5-c-36-80 | eth2 5g36/80 (0xe02a) | as shipped | 145841 | 97998 |
| s5-d-149-80-gh-as-g | eth2 5g149/80 (0xe09b) | rxgains5gh* set to the 5g values: elnagaina0-2 4/4/4, trisoa0-2 7/6/5 | 145876 | 97977 |
| s5-e-100-80-gh-as-g | eth2 5g100/80 (0xe06a) | as s5-d | 143331 | 95430 |
| s5-f-52-80 | eth2 5g52/80 (0xe03a) | as shipped (5gh restored before this run) | 143226 | 95369 |
| s5-g-116-80 | eth2 5g116/80 (0xe07a) | as shipped | 145059 | 97202 |
| s5-h-132-80 | eth2 5g132/80 (0xe08a) | as shipped | 143056 | 95160 |
