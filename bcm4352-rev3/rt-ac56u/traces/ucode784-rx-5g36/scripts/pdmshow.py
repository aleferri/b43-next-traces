import sys, collections
names = {"0x041A": "RXSTATUS(00D)", "0x0490": "BRC(048)", "0x0454": "MARK(02A)", "0x07C0": "WEP_CTL(1E0)", "0x08CA": "SPR265", "0x08C6": "SPR263", "0x07C6": "CRYPTLEN(1E3)"}
blocks = open(sys.argv[1]).read().split("== reg ")[1:]
per = collections.defaultdict(list)
for b in blocks:
    L = b.splitlines(); reg = L[0].split()[0]
    rows = [(int(f[0]), int(f[4], 16), f[3]) for f in (ln.split() for ln in L[2:]) if len(f) >= 5]
    if not rows or max(r[1] for r in rows) < 0x300: continue
    out = []; prev = None
    for i, fl, v in rows:
        if v != prev: out.append(f"{fl:#x}:{v}"); prev = v
    per[reg].append(" ".join(out[:14]))
for reg in names:
    print(f"{names[reg]}:")
    for s in per.get(reg, [])[:2]: print("   ", s)
