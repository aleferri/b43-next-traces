#!/usr/bin/env python3
"""ntab.py OPS.txt: N-PHY table accesses per MARK from an mmio2ops.py decode.

B43_NPHY_TABLE_ADDR (PHY 0x072) = table id << 10 | offset; a 32-bit entry is written high half first
(0x074, DATAHI), then low half (0x073, DATALO); the offset advances by one per DATALO access, read or write.
Prints, per mark, every table touched: writes, reads, and the offset range written.
"""
import re, sys
from collections import OrderedDict

rx = re.compile(r'\b(PHY\.WR|PHY\.RD|MARK)\b\s*(?:addr=0x([0-9a-f]+))?(?:\s+val=0x([0-9a-f]+))?(?:\s*\'(.*)\')?')
marks = OrderedDict()
cur = '(start)'
marks[cur] = {}
tid = off = None
for line in open(sys.argv[1]):
    m = rx.search(line)
    if not m:
        continue
    kind, addr, val, label = m.groups()
    if kind == 'MARK':
        cur = label
        marks.setdefault(cur, {})
        continue
    a = int(addr, 16)
    if a not in (0x072, 0x073, 0x074):
        continue
    if kind == 'PHY.WR' and a == 0x072:
        v = int(val, 16)
        tid, off = v >> 10, v & 0x3ff
        continue
    if tid is None or a != 0x073:
        continue
    t = marks[cur].setdefault(tid, {'w': 0, 'r': 0, 'lo': None, 'hi': None})
    if kind == 'PHY.WR':
        t['w'] += 1
        t['lo'] = off if t['lo'] is None else min(t['lo'], off)
        t['hi'] = off if t['hi'] is None else max(t['hi'], off)
    else:
        t['r'] += 1
    off += 1

for mk, tabs in marks.items():
    if not tabs:
        continue
    print(f'== {mk}')
    for tid in sorted(tabs):
        t = tabs[tid]
        rng = f'0x{t["lo"]:03x}-0x{t["hi"]:03x}' if t['lo'] is not None else '-'
        print(f'  table 0x{tid:02x} ({tid:2d}): {t["w"]:6d} writes {rng:13s} {t["r"]:6d} reads')
