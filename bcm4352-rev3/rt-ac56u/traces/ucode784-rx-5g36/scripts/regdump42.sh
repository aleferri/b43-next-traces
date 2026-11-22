#!/bin/bash
# rx42probe.sh UCODE42 TAG: corerev 42 reception: the 5 GHz AP (open, ch 36 HT20, uncommitted) with the given
# ucode42; SHM MAC counters (words 0x70-0x9F) and the AP's rx_packets before and after the PC scans ch 36 (probe
# requests) and tries to associate (auth); dmesg of that phy
cd "$(dirname "$0")"
A="ssh -p 2256 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o BatchMode=yes -o ConnectTimeout=10 root@192.168.2.1"
$A 'uci set wireless.radio1.channel=36; uci set wireless.radio1.htmode=HT20; uci set wireless.default_radio1.ssid=AC56U-5open; uci set wireless.default_radio1.encryption=none; dmesg -n 1; mkdir -p /tmp/fwopen/b43-open && cp /lib/firmware/b43/*initvals*.fw /lib/firmware/b43/ucode30_mimo.fw /tmp/fwopen/b43-open/ && echo -n /tmp/fwopen > /sys/module/firmware_class/parameters/path'
cat "$1" | $A 'cat > /tmp/fwopen/b43-open/ucode42.fw'
ARGS="fwpostfix=-open verbose=1" timeout 150 ~/re/test/router-try-b43next.sh ~/re/build/b43-next-dbg/b43-next.ko 2256 > /dev/null 2>&1
sleep 15
$A 'P=$(iw dev | awk "/^phy#/ {p=\$1} /ssid AC56U-5open/ {print p}" | tr -d "#"); D=/sys/kernel/debug/b43_next/$P; for s in 1 2 3; do o="S$s"; a=1024; while [ $a -le 2046 ]; do case $a in 1304|1306|1308|1310) a=$((a+2)); continue;; esac; echo $(printf 0x%04X $a) > $D/mmio16read; read v < $D/mmio16read; o="$o $(printf %03x $(( (a-1024)/2 )))=$v"; a=$((a+2)); done; echo "$o"; sleep 1; done' > regs-$2.txt
