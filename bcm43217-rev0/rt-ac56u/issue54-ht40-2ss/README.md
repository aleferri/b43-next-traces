# RT-AC56U (BCM43217, 2.4 GHz): two-stream HT40 uploads stall (aleferri/b43-next#54)

Full matrices of the core's MMIO registers, 0x400-0x7FE and 0x800-0x9FE (758 registers, ten addresses with read side effects left out),
taken on OpenWrt with b43-next (a build from 21ed64a6, debug module) on kernel 6.18.64 with firmware 784.2. The client is
in every case associated with WPA2; the AP is on channel 7, HT40+ with noscan (or HT20).

`registers.csv` has one row per register: how many distinct values a capture saw, and the values where no capture saw more than four.
Any word that is part of a MAC address known to the rig or seen in a scan is written `xxxx` (54 values): the raw captures contain packet
addresses and are not published. The matrix is read register by register, each with about 1500 back-to-back samples, so different rows come from
different times (2 minutes for a matrix). Values in the failing column are from a radio that restarts about every 3 s.

| column | what |
|---|---|
| HT40 idle | phone (2 streams) associated, no traffic |
| HT40 phone upload (fails) | TCP upload, `iperf3 -P 4`: 2.5 Mbit/s at the start, 1.9 over the run, 1492 retransmits |
| HT40 after | upload stopped, the same association |
| HT20 idle / phone upload | the same on HT20; the upload 87.7 Mbit/s |
| HT40 PC upload | a one-stream client, UDP 40 Mbit/s offered: carries it |

Driver log of a 20 s HT40 upload (verbose): `PSM microcode watchdog fired`, `Controller RESET (PSM watchdog)` and `MAC suspend failed`
7 times each; none in the HT20 upload (90.3 Mbit/s). In the matrix of the failing upload the log has `Too many PHY TX errors, restarting the
controller` and `MAC suspend failed` as well.

Some registers that differ in the failing upload from all the others (no meaning claimed, the names are not in b43-next):

| register | idle / HT20 / PC | HT40 phone upload |
|---|---|---|
| 0x484 | 0x400A (0xC00A during traffic) | 0x0000 |
| 0x486 | 0x0410 | 0x0400 |
| 0x4CE, 0x4D0, 0x4D2 | 0x0000 (0x0160 PC) | 0x1BF6 |
| 0x4C4 | 0x040A idle, 0x03DE in the uploads that work | 0x070C |
| 0x50C | 0xE881 idle, 0x2441 / 0x24C1 in traffic | 0x2CC1 |
| 0x5EA | 0xE24E | 0xF236 |
