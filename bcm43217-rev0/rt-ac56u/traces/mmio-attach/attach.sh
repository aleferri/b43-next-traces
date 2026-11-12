#!/bin/bash
# RT-AC56U BCM43217 (eth1, BAR0 0x08000000, wl maps 16 KiB): ATTACH MMIO capture under DD-WRT r66477.
# The ARM trap cannot watch wl's ioremap: its insmod waits in init_mm for the BAR mapping and arms (autoarm=1) as
# soon as it appears. Use the poll_ms=0 build (b43-ac-wip e712453), which rescans without sleeping; poll_ms=1 sleeps
# a jiffy between scans and loses part of the probe. The chip id and core scan at the start of the probe are not
# trapped either way. Sequence: rmmod wl; trap insmod detached (blocks in its wait); mark attach; insmod wl;
# then the cold.sh bring-up on the same load: ap 1 [bw_cap 2g 3] chanspec, up, 10 s, ssid, 10 s beaconing.
# Console printk is muted (kernel.printk 1) while the trap waits: its "mapped" line at 115200 Bd costs ~7 ms before
# arming, and wl goes on without the trap in that time. dmesg still gets every line.
# The status line after each step shows `emulated` still rising (the trap holds wl's live mapping).
# usage: [KO=/tmp/wl_mmio_trap_spin.ko POLLMS=0 PFX=attach-spin] attach.sh <chanspec>   e.g. 6, 6l
# POLLMS=0 needs the spin build (poll_ms=0 rescans without sleeping).
# BEFORE: mv /tmp/.startmon /tmp/.startmon.capture-off on the router (see cold.sh).
set -u
CS=$1; D=${OUT:-$HOME/re/rt-ac56u/mmio-43217-attach-20261112}; IF=eth1; WIN=0x08000000; SSID=test-ap
export SSHPASS=admin
R="sshpass -e ssh -p 2256 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=8 -o PubkeyAuthentication=no root@192.168.2.1"
TRAP="insmod ${KO:-/tmp/wl_mmio_trap.ko} autoarm=1 win_phys=$WIN win_phys_len=0x4000 fsr_info_fn7=0x805702cc init_mm_addr=0x80576c68 fifo_recs=2097152 poll_ms=${POLLMS:-1} poll_secs=120"
ST="echo status > \$C; dmesg | grep 'wl_mmio_trap:' | tail -1;"
mkdir -p $D
case "$CS" in *l|*u) LBL=${PFX:-attach}-2g$CS-40; BWC="echo 'mark bwcap' > \$C; wl -i $IF bw_cap 2g 3; echo rc bwcap=\$?;";; *) LBL=${PFX:-attach}-2g$CS-20; BWC=;; esac
date > $D/run-$LBL.log
$R "[ -f /tmp/.startmon ] && { echo startmon still ON - abort; exit 1; }; lsmod | grep -q wl_mmio_trap && { echo trap still loaded - abort; exit 1; }; killall nas wland 2>/dev/null; sleep 1; ifconfig eth1 down; ifconfig eth2 down; brctl delif br0 eth1 2>/dev/null; brctl delif br0 eth2 2>/dev/null; rmmod wl; echo rc rmmod=\$?; sleep 2; dmesg -c > /dev/null; echo 1 > /proc/sys/kernel/printk; nohup sh -c '$TRAP; echo rc trap=\$?' > /tmp/trap.log 2>&1 < /dev/null & for i in 1 2 3 4 5 6 7 8 9 10; do dmesg | grep -q 'selftest passed' && break; sleep 1; done; dmesg | grep wl_mmio_trap; [ -e /proc/wl_mmio_trap ] && echo trap polling" >> $D/run-$LBL.log 2>&1
grep -q 'trap polling' $D/run-$LBL.log && grep -q 'selftest passed' $D/run-$LBL.log || { echo "trap not polling, see run-$LBL.log"; exit 1; }
$R "dd if=/proc/wl_mmio_trap bs=28 2>/dev/null" > $D/$LBL.bin 2>> $D/reader-$LBL.err &
RD=$!
sleep 3
$R "C=/proc/wl_mmio_trap; echo 'mark $LBL' > \$C; echo 'mark attach' > \$C; insmod /lib/modules/4.4.302-rt232-st79/wl.ko; echo rc wl=\$?; for i in 1 2 3 4 5; do grep -q 'rc trap=' /tmp/trap.log && break; sleep 1; done; cat /tmp/trap.log; dmesg | grep wl_mmio_trap; sleep 2; $ST echo 'mark attach-done' > \$C; wl -i $IF ap 1; echo rc ap=\$?; $BWC echo 'mark chanspec' > \$C; wl -i $IF chanspec $CS; echo rc ch=\$?; echo 'mark up' > \$C; wl -i $IF up; echo rc up=\$?; sleep 10; $ST echo 'mark ssid' > \$C; wl -i $IF ssid $SSID; echo rc ssid=\$?; echo 'mark bss-up' > \$C; echo \"bss: \$(wl -i $IF bss)\"; sleep 10; echo \"on: \$(wl -i $IF chanspec)\"; echo 'mark beaconing' > \$C; $ST echo off > \$C; echo 'mark done' > \$C; wl -i $IF down; ifconfig $IF down; echo 7 > /proc/sys/kernel/printk; echo radio down; echo \"nas running: [\$(pidof nas)]\"" >> $D/run-$LBL.log 2>&1
sleep 8
$R "killall dd 2>/dev/null; sleep 2; rmmod wl_mmio_trap; echo rc rmmod=\$?; dmesg | grep 'wl_mmio_trap: unloaded' | tail -1" >> $D/run-$LBL.log 2>&1
wait $RD 2>/dev/null
date >> $D/run-$LBL.log; ls -l $D/$LBL.bin >> $D/run-$LBL.log
