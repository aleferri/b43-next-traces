# RT-AC56U BCM4352: 784.2 receiving long frames, register traces

The RT-AC56U's 5 GHz radio is a **BCM4352**, chip rev 3 (package 1, PCI 14e4:4360). It has an 802.11 core rev 42 and
an AC-PHY. It is PCIe 0001:01:00.0. These traces show the core receiving under the microcode of **784.2**
(`ucode42.fw`, cut with b43-fwcutter from wl 6.30.163.46). The host driver is b43-next, not `wl`.
They were taken for aleferri/b43-next#18 (the open ucode, item 24 of its queue): on corerev 42 the open ucode
loses every MPDU longer than ~1020 bytes, and 784.2 receives them.

## Setup

- OpenWrt on the router. The driver is a b43-next debug build: main plus test-only debugfs files (`pdtrace`, `shm16read`) and
  module parameters (`noampdutx`, `noampdurx`, `txcap`, `txhcap`). None of these is in b43-next.
- 784.2's ucode42 is loaded through `fwpostfix=-open`. The 2.4 GHz core runs 784.2's ucode30.
- The 5 GHz radio is an open AP on ch 36 HT20 at 192.168.5.1. A PC station at 192.168.5.10 associates with it.
- The scripts are in `scripts/`. `router-try-b43next.sh` loads the module and is not included.

## pdtrace

`echo "N MASK RA RB" > pdtrace` samples, N times back to back with interrupts off:

- PHYDEBUG (MMIO 0x158);
- MMIO RA;
- TSF low (0x632);
- MMIO RB.

With MASK bit 30 set, sampling starts when RB, after differing from MASK's low 16 bits, equals them again. After 2 s
without that, it samples anyway (`trig 0`). Each row is printed only when it changes:

    index  tsf-low  phydebug  RA-value  RB-value

SPR n is MMIO 0x400 + 2n.

## Files

- **`pdtrace-upload.txt`** (`scripts/pdupload.sh`):
  - The PC uploads UDP at 20 Mbit/s with 1400-byte payloads (MPDUs of ~1466 bytes). A-MPDU is off in both directions, so every frame is a single MPDU.
  - Command: `1200 0x40000040 REG 0x0418`. RB is FRAMELEN (SPR 0x00C), and sampling starts when a frame's received length reaches 0x40. RA is, in turn: SPR_BRC 0x048 (0x490), the RX mark 0x02A (0x454), WEP_CTL 0x1E0 (0x7C0), SPR 0x265 (0x8CA), SPR 0x263 (0x8C6), the crypto length 0x1E3 (0x7C6), and the RX status 0x00D (0x41A).
  - 8 captures for each register; `== reg X cap k` heads each capture.
- **`pdtrace-fifoctl1.txt`** (`scripts/pdlong.sh`):
  - Traffic: 1000-byte pings from the PC.
  - Command: `1500 0x40000040 0x0418 0x0408`. RA is FRAMELEN; RB is RXE FIFOCTL1 (SPR 0x004).
  - The trigger value (0x0040) never reads back, so every one of the 60 captures is untriggered (`trig 0`). The long frames are the captures where FRAMELEN goes past 0x300.
- **`shm-upload.txt`** (`scripts/shmdump42.sh`): all 4096 words of shared memory, 8 s into a 40 Mbit/s UDP upload.
- **`regs-idle.txt`** (`scripts/regdump42.sh`): SPR 0x000-0x1FF read from the host, 3 samples, AP up with no station.
- **`pdtrace-rxe-matrix.txt`** (`scripts/rxm.sh`, `scripts/rxm-remote.sh`):
  - Traffic: 1000-byte pings from the PC every 30 ms.
  - One capture per receive-engine register, SPR 0x000-0x03F (MMIO 0x400-0x47E; data ports 0x422 and 0x432 skipped).
  - Command: `1500 0x40000006 ADDR 0x0418`. RA is the register; RB is FRAMELEN, and sampling starts when FRAMELEN reaches 6 (the mark).
  - Of up to five tries per register, the capture with the longest frame is kept (53 of 62 have one over 0x300 bytes). `addr ADDR MAX` heads each capture.
  - `scripts/rxmshow.py` prints each register's changes against FRAMELEN.
- **`scripts/pdmshow.py`, `scripts/pdlshow.py`**: print the value changes of each capture against FRAMELEN.

MAC addresses are redacted as `xxxx`:

- shared memory 0x683-0x688 and 0x792-0x79A;
- SPR 0x0E8-0x0ED.

## What they show

These are read-backs; the microcode's writes are not observed directly. Through a ~1466-byte frame:

- **SPR_BRC:** 0x0140 at the mark, 0x0142 from ~38 bytes in, then 0x0300 / 0x0100.
- **The RX mark (0x02A):** 6 at the PLCP, 0 from the mark (6 bytes in) to the end.
- **WEP_CTL:** 0 at the start, 0x0050 from ~38 bytes while the frame streams, 0 when the frame ends.
- **RX status:** 0x3AA2 while the frame arrives, 0xBAA2 (bit 15) at FRAMELEN ~0x422, then 0x40A2 / 0x60A2 / 0x7080.
- **SPR 0x263:** 0x15C0.
- **SPR 0x265:** 0x0006 / 0x0002.
- **The crypto length (0x1E3):** the received frame's length from early in the frame (0x05BA for these frames).
- **FIFOCTL1:** 0x0800, then 0x0900 (~0x1D bytes), 0x0822 (~38 bytes), and 0x0804 / 0x0C22 while the frame streams past 1 KB.

FIFOCTL1's write-to-read mapping on this chip was measured at idle with a test build of the open ucode. Each value
was written and read back 1 µs later:

| bits | behaviour | examples (written → read back) |
|---|---|---|
| 1, 5, 8, 9, 12 | latch | 0x0002 → 0x0802, 0x0020 → 0x0820, 0x0100 → 0x0900, 0x0200 → 0x0A00, 0x1000 → 0x1800 |
| 2, 6, 7, 10, 13 | never read back | 0x0004, 0x0040, 0x0080, 0x0400, 0x2000, 0x20C0 → 0x0800 |
| 11 | always set | — |
