import sys
blocks = open(sys.argv[1]).read().split("addr ")[1:]
for b in blocks:
    L = b.splitlines(); h, mx = L[0].split()[:2]
    seq = []
    for ln in L[1:]:
        f = ln.split()
        if len(f) < 5: continue
        v, fl = f[3], int(f[4], 16)
        if not seq or seq[-1][1] != v: seq.append((fl, v))
    spr = (int(h, 16) - 0x400) // 2
    vals = {v for _, v in seq}
    tag = "const" if len(vals) == 1 else f"{len(seq)} changes"
    print(f"SPR {spr:03x} (max FRAMELEN {int(mx):#x}) {tag}: " + " ".join(f"{fl:#x}:{v}" for fl, v in seq[:12]))
