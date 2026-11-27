#!/bin/bash
# wl-start.sh <pci-addr> <wl.ko>: start mmiotrace, bind the card to wl, bring its netdev up.
# Writes the trace to ./wl.mmio. Stop with: echo nop > /sys/kernel/tracing/current_tracer
PCI=$1; KO=$2; T=/sys/kernel/tracing; D=/sys/bus/pci/devices/$PCI
[ -e $D/driver ] && echo $PCI > $D/driver/unbind
rmmod wl 2>/dev/null
echo mmiotrace > $T/current_tracer
# Only once mmiotrace has taken the other CPUs offline is there memory for this
echo 131072 > $T/buffer_size_kb
nohup cat $T/trace_pipe > wl.mmio 2>/dev/null &
sleep 1
echo "MARK insmod" > $T/trace_marker
insmod $KO || exit 1
echo wl > $D/driver_override
echo $PCI > /sys/bus/pci/drivers_probe
for n in $(seq 20); do IF=$(ls $D/net 2>/dev/null | head -1); [ -n "$IF" ] && break; sleep 0.5; done
nmcli dev set $IF managed no 2>/dev/null; sleep 1
echo "MARK up" > $T/trace_marker
ip link set $IF up
echo "IF=$IF"
