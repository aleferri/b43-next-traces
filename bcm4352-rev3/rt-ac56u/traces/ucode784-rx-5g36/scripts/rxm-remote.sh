# rxm-remote.sh: for every RXE SPR 0x000-0x03F (MMIO 0x400-0x47E, data ports skipped) a pdtrace capture of that
# address (RA) and FRAMELEN (RB, 0x418), triggered when FRAMELEN reaches 6 (the mark); up to 5 tries for a frame
# over 0x300 bytes (else the longest); each kept capture printed as "addr <hex> <max>" then its rows
P=$(iw dev | awk '/^phy#/ {p=$1} /ssid AC56U-5open/ {print p}' | tr -d '#'); D=/sys/kernel/debug/b43_next/$P
for a in $(seq $((0x400)) 2 $((0x47E))); do
	h=$(printf 0x%03X $a)
	case $h in 0x422|0x432) continue;; esac
	best=0
	for t in 1 2 3 4 5; do
		echo "1500 0x40000006 $h 0x0418" > $D/pdtrace 2>/dev/null
		cat $D/pdtrace > /tmp/rxm-cur.txt
		m=0
		while read n x p f b; do case "$n" in trig) continue;; esac; v=$((0x$b)); [ $v -gt $m ] && m=$v; done < /tmp/rxm-cur.txt
		if [ $m -gt $best ]; then best=$m; cp /tmp/rxm-cur.txt /tmp/rxm-best.txt; fi
		[ $best -gt 768 ] && break
	done
	echo "addr $h $best"; grep -v trig /tmp/rxm-best.txt
done
