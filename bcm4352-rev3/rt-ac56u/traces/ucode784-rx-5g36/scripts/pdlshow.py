import sys
caps = open(sys.argv[1]).read().split("== cap ")[1:]
shown = 0
for c in caps:
    L = c.splitlines()
    if len(L) < 3 or "trig 1" not in L[1]: continue
    seq = []; mx = 0
    for ln in L[2:]:
        f = ln.split()
        if len(f) < 5: continue
        flen, fc = int(f[3], 16), f[4]
        mx = max(mx, flen)
        if not seq or seq[-1][2] != fc: seq.append((int(f[0]), flen, fc))
    if mx < 0x300: continue
    print(f"max FRAMELEN {mx:#06x}: " + " ".join(f"{i}:{fl:#x}/{fc}" for i, fl, fc in seq[:22]))
    shown += 1
    if shown >= 8: break
print("captures", len(caps))
