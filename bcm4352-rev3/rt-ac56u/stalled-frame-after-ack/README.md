# RT-AC56U (BCM4352, 5 GHz): the frame after an ACK stalls under the open ucode

Full matrices of the core's MMIO registers (0x400-0x7FE and 0x800-0x9FE, 758 registers, ten addresses with read side effects left out) around one
full-size frame at legacy 6 Mb/s, which a WPA2 client on a VHT80 AP (channel 52, b43-next 625d906, debug module, kernel 6.18.64, software crypto) sends in
the 28 us after the AP's ACK. The client repeats a whole A-MPDU as such single frames, so they come one after another.

- **release:** the open ucode of 2026-11-24 (before the fix; b43-next#18), `ucode42`: the frame stays at FRAMELEN 2 for up to 1.7 ms of its 2.0, comes up to
  0x1FA bytes at once and fails the FCS. 30 of 36 such frames in the traces before, 679 of 758 registers caught in this matrix.
- **784.2:** the same moment, a frame that goes on to its end: 712 of 758 registers caught.

`registers.csv` has one row per register with the distinct values (up to four, else their number) of each part of the window: `before`, `ack` (our
transmission), `wait` (FRAMELEN at most 8 after it), and `stall` (FRAMELEN 0x1FA) for the release or `run` for 784.2. The `ack` column is empty
where the kept window starts after the ACK. Each register comes from a separate capture of its own window, so rows come from different frames.
Registers that hold addresses (0x5D0-0x5DE, 0x880-0x8AF), and any word of a known address, are written `xxxx` (255 values); the raw captures hold
packet addresses and are not published.

Two of the status words differ in the wait (other names not claimed): 0x41A (SPR 0x00D) reads FA80 there, 3A80 at the start of a good frame, and 0x41C
(SPR 0x00E) 4400 against 0400 (784.2 0E80). The open ucode wrote FIFOCTL1 4 / 0 at the ACK's start with the frame still in the RXE and pushed it
during the ACK; the drop's FIFOCTL1 sequence at the ACK's TX_DONE removes the stall (in vchip: `push_hold`, aleferri/b43-tools#11).
