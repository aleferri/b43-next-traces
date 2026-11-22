#!/bin/bash
# ampdu5g.sh UCODE42 TAG: A-MPDU reception on the AC56U's 5 GHz BCM4352 (corerev 42): 784.2's ucode30 with the given
# ucode42, radio1 as an open AP on ch 36 HT20 (uncommitted), the PC associates on 5 GHz and uploads UDP at 40 Mbit/s;
# pdtrace of SPR 0x005 / FIFOCTL1 / the PLCP counter (SPR 0x293) against FRAMELEN 12 s in; iperf's result
cd "$(dirname "$0")"
A="ssh -p 2256 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o BatchMode=yes -o ConnectTimeout=10 root@192.168.2.1"
$A 'uci set wireless.radio1.channel=36; uci set wireless.radio1.htmode=HT20; uci set wireless.default_radio1.ssid=AC56U-5open; uci set wireless.default_radio1.encryption=none; dmesg -n 1; mkdir -p /tmp/fwopen/b43-open && cp /lib/firmware/b43/*initvals*.fw /lib/firmware/b43/ucode30_mimo.fw /tmp/fwopen/b43-open/ && echo -n /tmp/fwopen > /sys/module/firmware_class/parameters/path'
cat "$1" | $A 'cat > /tmp/fwopen/b43-open/ucode42.fw'
ARGS="fwpostfix=-open verbose=1 txcap=3000 txhcap=3000 noampdutx=1" timeout 150 ~/re/test/router-try-b43next.sh ~/re/build/b43-next-dbg/b43-next.ko 2256 > /dev/null 2>&1
$A 'touch /tmp/b43-keep; true'
nmcli con delete ac56o5 >/dev/null 2>&1
nmcli con add type wifi ifname wlp5s0 con-name ac56o5 autoconnect no ssid AC56U-5open wifi.band a ipv4.method manual ipv4.addresses 192.168.5.10/24 ipv4.never-default yes ipv6.method disabled >/dev/null
for t in 1 2 3; do timeout 15 sudo -n iw dev wlp5s0 scan freq 5180 >/dev/null 2>&1; sleep 2; timeout 15 nmcli dev wifi rescan ifname wlp5s0 >/dev/null 2>&1; sleep 3; nmcli -t -f SSID dev wifi list ifname wlp5s0 | grep -q AC56U-5open && break; done
timeout 60 nmcli --wait 45 con up ac56o5 >/dev/null || echo ASSOC-FAIL
$A 'I=$(iw dev | awk "/Interface/ {i=\$2} /ssid AC56U-5open/ {print i}"); iw dev $I set bitrates legacy-5 6 9 12 18 24 ht-mcs-5 vht-mcs-5 2>&1 | head -2; true'
(timeout 25 sudo -n tcpdump -i wlp5s0 -n -e -c 60 arp or icmp > pcarp.txt 2>/dev/null &)
sleep 1
cat rxm-remote.sh | $A 'cat > /tmp/rxm-remote.sh'
(ping -c 20000 -i 0.03 -W 1 -s 1000 -I wlp5s0 192.168.5.1 > /dev/null 2>&1 &)
sleep 2
$A 'sh /tmp/rxm-remote.sh' > rxm-$2.txt
pkill -f '^ping -c 20000' 2>/dev/null
sleep 1
ping -c 5 -i 0.2 -W 1 -s 1000 -I wlp5s0 192.168.5.1 2>&1 | grep -E "transmitted|rtt"
timeout 20 iperf3 -c 192.168.5.1 -B 192.168.5.10 -u -b 5M -t 8 2>&1 | grep -E "receiver" &
$A 'killall iperf3 2>/dev/null; (iperf3 -s -D >/dev/null 2>&1 &); true'
sleep 12
$A 'iw dev | awk "/Interface/ {i=\$2} /ssid AC56U-5open/ {print i}" | while read i; do iw dev $i station dump | grep -E "rx packets|tx packets|tx failed|tx retries|rx bitrate|tx bitrate"; done; P=$(iw dev | awk "/^phy#/ {p=\$1} /ssid AC56U-5open/ {print p}" | tr -d "#"); echo "faults $(dmesg | grep -c "PHY transmission error")"; killall iperf3'
echo "PC side: $(iw dev wlp5s0 station dump | grep -E 'rx packets|rx drop misc|rx bytes' | tr -s '\t ' ' ' | tr '\n' ';')"; ip -s link show wlp5s0 | sed -n 3,4p | tr '\n' ' '; echo
$A 'ip neigh show | grep 192.168.5'; sleep 3; head -12 pcarp.txt | cut -c1-150
$A 'dmesg' > txd-$2.txt
nmcli --wait 40 con up "Auto PonyWorld 5G" >/dev/null 2>&1; nmcli con delete ac56o5 >/dev/null 2>&1; nmcli --wait 20 con up "Ethernet connection 1" >/dev/null 2>&1
