#!/bin/bash
# rx42probe.sh UCODE42 TAG: corerev 42 reception: the 5 GHz AP (open, ch 36 HT20, uncommitted) with the given
# ucode42; SHM MAC counters (words 0x70-0x9F) and the AP's rx_packets before and after the PC scans ch 36 (probe
# requests) and tries to associate (auth); dmesg of that phy
cd "$(dirname "$0")"
A="ssh -p 2256 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o BatchMode=yes -o ConnectTimeout=10 root@192.168.2.1"
$A 'uci set wireless.radio1.channel=36; uci set wireless.radio1.htmode=HT20; uci set wireless.default_radio1.ssid=AC56U-5open; uci set wireless.default_radio1.encryption=none; dmesg -n 1; mkdir -p /tmp/fwopen/b43-open && cp /lib/firmware/b43/*initvals*.fw /lib/firmware/b43/ucode30_mimo.fw /tmp/fwopen/b43-open/ && echo -n /tmp/fwopen > /sys/module/firmware_class/parameters/path'
cat "$1" | $A 'cat > /tmp/fwopen/b43-open/ucode42.fw'
ARGS="fwpostfix=-open verbose=1 noampdutx=1" timeout 150 ~/re/test/router-try-b43next.sh ~/re/build/b43-next-dbg/b43-next.ko 2256 > /dev/null 2>&1
for k in 1 2 3; do timeout 15 sudo -n iw dev wlp5s0 scan freq 5180 >/dev/null 2>&1; sleep 1; done
nmcli con delete ac56o5 >/dev/null 2>&1
nmcli con add type wifi ifname wlp5s0 con-name ac56o5 autoconnect no ssid AC56U-5open wifi.band a ipv4.method manual ipv4.addresses 192.168.5.10/24 ipv4.never-default yes ipv6.method disabled >/dev/null
timeout 40 nmcli --wait 25 con up ac56o5 >/dev/null 2>&1 && echo ASSOC-OK || echo ASSOC-FAIL
$A 'killall iperf3 2>/dev/null; (iperf3 -s -D >/dev/null 2>&1 &); sleep 1'
(timeout 120 iperf3 -c 192.168.5.1 -B 192.168.5.10 -u -b 40M -t 100 > /dev/null 2>&1 &)
sleep 8
$A 'P=$(iw dev | awk "/^phy#/ {p=\$1} /ssid AC56U-5open/ {print p}" | tr -d "#"); D=/sys/kernel/debug/b43_next/$P; i=0; while [ $i -lt 4096 ]; do echo "0x0001 $(printf 0x%04X $((i*2)))" > $D/shm16read; read v < $D/shm16read; echo "S $i $v"; i=$((i+1)); done' > shm42-$2.txt
$A 'killall iperf3'
nmcli --wait 40 con up "Auto PonyWorld 5G" >/dev/null 2>&1; nmcli con delete ac56o5 >/dev/null 2>&1; nmcli --wait 20 con up "Ethernet connection 1" >/dev/null 2>&1
