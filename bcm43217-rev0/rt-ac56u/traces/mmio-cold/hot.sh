#!/bin/bash
# This wl (DD-WRT r66477, 7.14.164.18) does not parse `bss up`/`bss down`: on an up AP `wl ssid` starts the BSS, and
# the bss-up mark only reads the state back (`wl bss`).
# RT-AC56U BCM43217 (eth1, BAR0 0x08000000, 16 KiB): HOT MMIO capture under DD-WRT r66477 = one insmod, an UNTRACED
# warm-up up/down on ch 6, then traced cycles {chanspec; up; 10 s; ssid + bss up; 5 s; bss down; down} per chanspec.
# Same layout and marks as egc112's R6400 v1 BCM4331 set (aleferri/b43-ac-wip#41).
# usage: hot.sh <label> <chanspec...>   e.g. hot.sh hot-2g-20 1 2 ... 11 ; hot.sh hot-2g-40 1l 2l ... 11u
# BEFORE: mv /tmp/.startmon /tmp/.startmon.capture-off (see cold.sh). 40 MHz runs get bw_cap 2g 3 in the untraced setup.
set -u
LBL=$1; shift; CHS="$*"; D=${OUT:-$HOME/re/rt-ac56u/mmio-43217-20261112}; IF=eth1; WIN=0x08000000; SSID=test-ap
export SSHPASS=admin
R="sshpass -e ssh -p 2256 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=8 -o PubkeyAuthentication=no root@192.168.2.1"
TRAP="insmod /tmp/wl_mmio_trap.ko autoarm=0 win_phys=$WIN win_phys_len=0x4000 fsr_info_fn7=0x805702cc init_mm_addr=0x80576c68 fifo_recs=2097152 poll_secs=10"
mkdir -p $D
case "$CHS" in *l*|*u*) BWC="wl -i $IF bw_cap 2g 3; echo rc bwcap=\$?;";; *) BWC=;; esac
date > $D/run-$LBL.log
$R "[ -f /tmp/.startmon ] && { echo startmon still ON - abort; exit 1; }; killall nas wland 2>/dev/null; sleep 1; ifconfig eth1 down; ifconfig eth2 down; brctl delif br0 eth1 2>/dev/null; brctl delif br0 eth2 2>/dev/null; rmmod wl; echo rc rmmod=\$?; sleep 2; insmod /lib/modules/4.4.302-rt232-st79/wl.ko; echo rc wl=\$?; sleep 3; wl -i $IF ap 1; $BWC wl -i $IF chanspec 6; wl -i $IF up; echo rc warmup-up=\$?; sleep 10; wl -i $IF down; echo warm-up done; $TRAP; echo rc trap=\$?" >> $D/run-$LBL.log 2>&1
grep -q 'rc trap=0' $D/run-$LBL.log || { echo "trap did not load, see run-$LBL.log"; exit 1; }
$R "dd if=/proc/wl_mmio_trap bs=28 2>/dev/null" > $D/$LBL.bin 2>> $D/reader-$LBL.err &
RD=$!
sleep 3
CMD="C=/proc/wl_mmio_trap; echo 'mark $LBL' > \$C; echo on > \$C;"
for c in $CHS; do
  CMD="$CMD echo 'mark ch-$c' > \$C; wl -i $IF chanspec $c; echo rc ch-$c=\$?; echo 'mark up-$c' > \$C; wl -i $IF up; echo rc up=\$?; sleep 10; echo 'mark ssid-$c' > \$C; wl -i $IF ssid $SSID; echo \"bss: \$(wl -i $IF bss)\"; sleep 5; echo \"on: \$(wl -i $IF chanspec)\"; echo 'mark down-$c' > \$C; wl -i $IF down; echo rc down=\$?;"
done
CMD="$CMD echo 'mark done' > \$C; echo off > \$C; ifconfig $IF down; echo radio down; echo \"nas running: [\$(pidof nas)]\""
$R "$CMD" >> $D/run-$LBL.log 2>&1
sleep 8
$R "killall dd 2>/dev/null; sleep 2; rmmod wl_mmio_trap; echo rc rmmod=\$?; dmesg | grep 'wl_mmio_trap: unloaded' | tail -1" >> $D/run-$LBL.log 2>&1
wait $RD 2>/dev/null
date >> $D/run-$LBL.log; ls -l $D/$LBL.bin >> $D/run-$LBL.log
