#!/usr/bin/env python3
"""Decode an mmiotrace of a Broadcom D11 (HT-PHY) driver into PHY/radio/table operations.

Usage: mmiodec.py <trace> [bar0-phys-hex]   (default 0xfc300000)

Output, one op per line, in trace order:
  MARK <text>
  PW <reg> <val>     PHY register write      PR <reg> <val>   PHY register read
  RW <reg> <val>     radio register write    RR <reg> <val>   radio register read
  TW <id> <off> <val>   table write (16 or 32 bit, auto-increment tracked)
  TR <id> <off> <val>   table read
  MW/MR <off> <width> <val>   any other BAR0 access
Window switches happen in PCI config space and are not traced, so other
BAR0 offsets may belong to whichever core the window points at.
"""
import sys

PHY_CTL, PHY_DATA = 0x3FC, 0x3FE
RADIO_CTL, RADIO_DATA = 0x3D8, 0x3DA
TAB_ADDR, TAB_LO, TAB_HI = 0x072, 0x073, 0x074


class Dec:
    def __init__(self):
        self.phy_addr = 0
        self.radio_addr = 0
        self.tab_id = self.tab_off = 0
        self.tab_hi_w = None      # pending high half of a 32-bit table write
        self.tab_hi_pending_r = False
        self.out = []

    def emit(self, *a):
        self.out.append(" ".join(a))

    def phy_write(self, reg, val):
        reg &= 0xFFFF
        if reg == TAB_ADDR:
            self.tab_id, self.tab_off = val >> 10, val & 0x3FF
            self.tab_hi_w = None
            return
        if reg == TAB_HI:
            self.tab_hi_w = val
            return
        if reg == TAB_LO:
            v = val if self.tab_hi_w is None else (self.tab_hi_w << 16) | val
            self.emit("TW", f"{self.tab_id}", f"0x{self.tab_off:03x}",
                      f"0x{v:08x}" if self.tab_hi_w is not None else f"0x{v:04x}")
            self.tab_off += 1
            self.tab_hi_w = None
            return
        self.emit("PW", f"0x{reg:03x}", f"0x{val:04x}")

    def phy_read(self, reg, val):
        reg &= 0xFFFF
        if reg == TAB_LO:
            self.last_tr = (self.tab_id, self.tab_off, val)
            self.emit("TR", f"{self.tab_id}", f"0x{self.tab_off:03x}", f"0x{val:04x}")
            self.tab_off += 1
            return
        if reg == TAB_HI:
            # high half of the entry just read: fold into the previous TR line
            if self.out and self.out[-1].startswith("TR "):
                t = self.out[-1].split()
                self.out[-1] = f"TR {t[1]} {t[2]} 0x{(val << 16) | int(t[3], 16):08x}"
            return
        self.emit("PR", f"0x{reg:03x}", f"0x{val:04x}")

    def access(self, rw, width, off, val):
        if off == PHY_CTL:
            if rw == "W":
                if width == 4:          # address | data << 16 in one go
                    self.phy_addr = val & 0xFFFF
                    self.phy_write(self.phy_addr, val >> 16)
                else:
                    self.phy_addr = val
            elif width == 4:
                self.phy_read(self.phy_addr, val >> 16)
            return
        if off == PHY_DATA:
            (self.phy_write if rw == "W" else self.phy_read)(self.phy_addr, val & 0xFFFF)
            return
        if off == RADIO_CTL:
            if rw == "W":
                if width == 4:
                    self.radio_addr = val & 0xFFFF
                    self.emit("RW", f"0x{self.radio_addr & ~0x200 & 0xFFF:03x}", f"0x{val >> 16:04x}")
                else:
                    self.radio_addr = val
            return
        if off == RADIO_DATA:
            reg = self.radio_addr & 0xFFF
            if rw == "W":
                self.emit("RW", f"0x{reg:03x}", f"0x{val & 0xFFFF:04x}")
            else:
                self.emit("RR", f"0x{reg & ~0x200:03x}", f"0x{val & 0xFFFF:04x}")
            return
        self.emit("M" + rw, f"0x{off:04x}", str(width), f"0x{val:x}")


def main():
    bar = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0xFC300000
    d = Dec()
    for line in open(sys.argv[1], errors="replace"):
        f = line.split()
        if not f:
            continue
        if f[0] == "MARK":
            d.emit("MARK", " ".join(f[2:]))
            continue
        if f[0] not in ("R", "W") or len(f) < 6:
            continue
        width = int(f[1])
        phys = int(f[4], 16)
        off = phys - bar
        if not 0 <= off < 0x4000:
            continue
        d.access(f[0], width, off, int(f[5], 16))
    sys.stdout.write("\n".join(d.out) + "\n")


main()
