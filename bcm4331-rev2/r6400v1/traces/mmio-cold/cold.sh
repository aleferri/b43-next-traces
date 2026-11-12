#!/bin/sh
# R6400 v1 BCM4331 (eth1, 0001:01:00.0, BAR0 0x08000000, 16 KiB): one COLD MMIO capture = rmmod/insmod wl (attach not
# traced), then traced: ap 1 [bw_cap 2g 3] chanspec, up, 10 s, ssid, bss up, 10 s (beaconing).
# usage: cold.sh <chanspec>   e.g. 6, 1, 11, 6l, 1l, 11u
# BEFORE: mv /tmp/.startmon /tmp/.startmon.capture-off on the router - DD-WRT's check_ps (cron */2) otherwise runs
# wlconf + nas again from nvram once it sees nas missing (rc/check_ps.c checknas()), mid-capture.
# A fresh insmod caps 2.4 GHz at 20 MHz (bw_cap 2g 0x1), so 40 MHz chanspecs get bw_cap 2g 3 first (traced, own mark).
set -u
CS=$1; D=/home/egc/dev/r6400v1-wl-diag/mmio-20261112; R=$D/r6.sh; IF=eth1; WIN=0x08000000; SSID=test-ap
case "$CS" in *l|*u) LBL=cold-2g$CS-40; BWC="echo 'mark bwcap' > \$C; wl -i $IF bw_cap 2g 3; echo rc bwcap=\$?;";; *) LBL=cold-2g$CS-20; BWC=;; esac
date > $D/run-$LBL.log
$R "[ -f /tmp/.startmon ] && { echo startmon still ON - abort; exit 1; }; killall nas wland 2>/dev/null; sleep 1; ifconfig eth1 down; ifconfig eth2 down; brctl delif br0 eth1 2>/dev/null; brctl delif br0 eth2 2>/dev/null; rmmod wl; echo rc rmmod=\$?; sleep 2; insmod /lib/modules/4.4.302-rt232-st78/wl.ko; echo rc wl=\$?; sleep 3; insmod /tmp/wmt.ko autoarm=0 win_phys=$WIN win_phys_len=0x4000 fsr_info_fn7=0x8055de0c init_mm_addr=0x80564968 fifo_recs=2097152 poll_secs=10; echo rc trap=\$?" >> $D/run-$LBL.log 2>&1
grep -q 'rc trap=0' $D/run-$LBL.log || { echo "trap did not load, see run-$LBL.log"; exit 1; }
$R "dd if=/proc/wl_mmio_trap bs=28 2>/dev/null" > $D/$LBL.bin 2>> $D/reader-$LBL.err &
RD=$!
sleep 3
$R "export PATH=/tmp/wlbin:\$PATH; C=/proc/wl_mmio_trap; echo 'mark $LBL' > \$C; echo on > \$C; wl -i $IF ap 1; echo rc ap=\$?; $BWC echo 'mark chanspec' > \$C; wl -i $IF chanspec $CS; echo rc ch=\$?; echo 'mark up' > \$C; wl -i $IF up; echo rc up=\$?; sleep 10; echo 'mark ssid' > \$C; wl -i $IF ssid $SSID; echo rc ssid=\$?; echo 'mark bss-up' > \$C; wl -i $IF bss up; echo rc bss=\$?; sleep 10; echo \"on: \$(wl -i $IF chanspec)\"; echo 'mark beaconing' > \$C; echo off > \$C; echo 'mark done' > \$C; wl -i $IF bss down; wl -i $IF down; ifconfig $IF down; echo radio down; echo \"nas running: [\$(pidof nas)]\"" >> $D/run-$LBL.log 2>&1
sleep 8
$R "killall dd 2>/dev/null; sleep 2; rmmod wl_mmio_trap; echo rc rmmod=\$?; dmesg | grep 'wl_mmio_trap: unloaded' | tail -1" >> $D/run-$LBL.log 2>&1
wait $RD 2>/dev/null
date >> $D/run-$LBL.log; ls -l $D/$LBL.bin >> $D/run-$LBL.log
