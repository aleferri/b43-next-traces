# RT-AC56U (BCM4352, 5 GHz): 784.2 receiving with hardware CCMP

Full matrices of the core's MMIO registers (0x400-0x7FE and 0x800-0x9FE, 757 registers, ten addresses with read side effects left out) under 784.2's
`ucode42`, a WPA2 (CCMP) VHT80 AP on channel 52 (b43-next debug module, kernel 6.18.64) while a PC station uploads UDP at 60 Mbit/s and pings the AP.
Taken for aleferri/b43-next#18 (the open ucode): under it the frames come up marked decrypted, but the crypto engine faults right after the start
(WEP_CTL bit 15 set, bit 7 never), so the payload stays encrypted.

Three captures, pdtrace in history mode (1200 rows a register, 600 before the trigger and 600 from it on), each register from its own window:

- `decrypting`: hardware CCMP (`nohwcrypt=0`), the trigger WEP_CTL (SPR 0x1E0, MMIO 0x7C0) reading 0x0055 while the engine decrypts. 60.0 Mbit/s.
- `hw-start`: hardware CCMP, the trigger WEP_CTL reading 0x0000 at a frame's start. 60.0 Mbit/s.
- `sw-start`: software CCMP (`nohwcrypt=1`), the same trigger. 44.6 Mbit/s, 13% lost.

`registers.csv` has one row per register with its distinct values (up to four, else their number) before the trigger and from it on, per capture.
Registers that hold addresses (0x5D0-0x5DE, 0x880-0x8AF), and any word of a known address, are written `xxxx`; the raw captures hold packet
addresses and are not published.

Read off it (names other than WEP_CTL not claimed): with hardware keys 784.2 holds SPR 0x20D (0x81A) at 0x0008 (0 with software CCMP), 0x1E4 (0x7C8)
at 0x0108 (0), 0x261 (0x8C2) at 0x05CC (0x05D4), 0x263 (0x8C6) at 0x1600; 0x1E2 (0x7C4) is 0x0020 and 0x1E3 (0x7C6) the MPDU length 0x05FA in both
modes. Per frame WEP_CTL goes 0x0050 -> 0x0000 at the start -> 0x0155 (reads 0x0055) after the header -> 0x00D5 -> 0x0040 -> 0x0050, while SPR 0x1E1
(0x7C2) steps through values such as 0x0A0B / 0x080C / 0x060B (0 with software CCMP).
