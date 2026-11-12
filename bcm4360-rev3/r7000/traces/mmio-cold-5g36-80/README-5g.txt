Same setup as README.txt, 5 GHz radio: eth2 = BCM4360 0002:01:00.0, BAR0 0x40000000 (window 16 KiB at 88860000)
  insmod wl_mmio_trap.ko autoarm=0 win_phys=0x40000000 win_phys_len=0x8000 fsr_info_fn7=0x8055de04 init_mm_addr=0x80564928 fifo_recs=2097152 poll_secs=10
rmmod wl; insmod wl (attach not traced); nas killed; then under the trap (run5.log):
  mark cold-5g36 | on | wl ap 1 | mark chanspec | wl chanspec 36/80 (0xe02a) | mark up | wl up | sleep 10 | mark ssid | wl ssid test-ap5 | mark bss-up | wl bss up | sleep 10 | mark beaconing | off | mark done
cold-5g36-80.bin  141986 records (141979 emulated + 7 marks), seq contiguous, drops 0, mismatch 0; read with dd bs=28
cold-5g36-80-ops.txt  reverse-tools/mmio2ops.py --format wl-mmio-trap-arm output
