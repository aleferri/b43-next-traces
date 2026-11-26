import sys, re
SYN = [0x16,0x17,0x22,0x25,0x27,0x28,0x29,0x2c,0x2d,0x37,0x41,0x43,0x47]
RXTX = [0x4a,0x58,0x5a,0x6a,0x6d,0x6e,0x92,0x98]
BW = [0x1ce,0x1cf,0x1d0,0x1d1,0x1d2,0x1d3]
segs = {}; cur = None
for l in open(sys.argv[1]):
    f = l.split()
    if f[0] == "MARK":
        if len(f) > 2 and f[2] == "cs": cur = f[3]; segs[cur] = []
        elif len(f) > 2 and f[2] == "end": cur = None
        continue
    if cur: segs[cur].append(f)
out = {}
for name, ops in segs.items():
    # start at the first write of syn 0x16
    try: i = next(k for k, o in enumerate(ops) if o[0] == "RW" and int(o[1], 16) == 0x16)
    except StopIteration: print(name, "no channel setup"); continue
    rw = {}; first = {}
    for o in ops[i:i+200]:
        if o[0] == "RW":
            r = int(o[1], 16)
            rw.setdefault(r, int(o[2], 16))
    pw = {}
    for o in ops:
        if o[0] == "PW" and int(o[1], 16) in BW: pw.setdefault(int(o[1], 16), int(o[2], 16))
    syn = [rw.get(r) for r in SYN]
    rx = [[rw.get(c | r) for r in RXTX] for c in (0, 0x400, 0x800)]
    ok = rx[0] == rx[1] == rx[2]
    bw = [pw.get(r) for r in BW]
    print(f"{name:5s} syn={' '.join('%02x'%v if v is not None else '--' for v in syn)} rxtx={' '.join('%02x'%v if v is not None else '--' for v in rx[0])} cores_eq={ok} bw={' '.join('%04x'%v if v is not None else '----' for v in bw)}")
