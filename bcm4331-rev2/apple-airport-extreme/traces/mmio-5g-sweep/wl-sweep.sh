#!/bin/bash
# wl-sweep.sh <ifname>: set each chanspec on wl (11ac encoding), each marked in the mmiotrace.
# wlq is a minimal wl ioctl tool: "wlq <if> set <iovar> <int>" / "wlq <if> get <iovar>".
IF=$1; W=${WLQ:-wlq}; T=/sys/kernel/tracing
$W $IF set mpc 0; sleep 2
mk() { echo "MARK $*" > $T/trace_marker; }
cs() { # cs <label> <hex>
	mk "cs $1 $2"; $W $IF set chanspec $2; echo "rc=$? $1 $2 -> $($W $IF get chanspec | cut -d' ' -f3)"; sleep 1.5; mk "end $1"
}
# 20 MHz references, already in b43's radio_2059.c
cs 36 0xd024; cs 64 0xd040; cs 100 0xd064; cs 149 0xd095; cs 165 0xd0a5
# 40 MHz, lower and upper control channel per centre
for c in 38 46 54 62 102 110 118 126 134 142 151 159; do
	cs ${c}L $(printf 0x%04x $((0xd800 | c))); cs ${c}U $(printf 0x%04x $((0xd900 | c)))
done
cs 36b 0xd024; cs 2g3L 0x1803
mk sweep-done
