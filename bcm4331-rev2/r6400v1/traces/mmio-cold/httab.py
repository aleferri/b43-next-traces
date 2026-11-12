#!/usr/bin/env python3
"""Count HT-PHY table writes per mark segment in mmio2ops output (BCM4331, b43 phy_ht.h):
PHY 0x072 = table address (id << 10 | offset), 0x074 = data high (written first for 32-bit), 0x073 = data low;
the offset auto-increments on each 0x073 access. Reads of 0x073 are counted as reads.
usage: httab.py X-ops.txt"""
import sys, re, collections
ln = re.compile(r'(PHY\.WR|PHY\.RD|MARK)\s+(?:addr=0x([0-9a-f]+)(?:\s+val=0x([0-9a-f]+))?|\'(.*)\')')
seg = 'start'; addr = None; hi = False
W = collections.OrderedDict()
def tab(): return W.setdefault(seg, collections.OrderedDict())
for line in open(sys.argv[1]):
    m = ln.search(line)
    if not m: continue
    op, a, v, mark = m.groups()
    if op == 'MARK': seg = mark; continue
    a = int(a, 16)
    if op == 'PHY.WR' and a == 0x72: addr = int(v, 16); hi = False; continue
    if addr is None: continue
    tid, off = addr >> 10, addr & 0x3ff
    if op == 'PHY.WR' and a == 0x74: hi = True; continue
    if a == 0x73:
        t = tab().setdefault(tid, {'w': 0, 'r': 0, 'offs': set(), 'w32': False, 'vals': collections.Counter()})
        if op == 'PHY.WR':
            t['w'] += 1; t['offs'].add(off); t['w32'] |= hi; t['vals'][int(v, 16)] += 1
        else:
            t['r'] += 1; t['offs'].add(off)
        hi = False; addr = (addr & ~0x3ff) | ((off + 1) & 0x3ff)
for s, ts in W.items():
    if not ts: continue
    print(f"[{s}]")
    for tid, t in sorted(ts.items()):
        o = sorted(t['offs'])
        print(f"  0x{tid:02x}  wr {t['w']:5d}  rd {t['r']:4d}  offs {o[0]}-{o[-1]} ({len(o)})  {'32' if t['w32'] else '16'}-bit  distinct {len(t['vals'])}")
