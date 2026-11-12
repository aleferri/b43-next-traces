#!/bin/bash
# all.sh: the full BCM43217 set, in egc112's order: cold 6 1 11 6l 1l 11u, hot 2g20 1-11, hot 2g40.
cd "$(dirname "$0")"
for c in 6 1 11 6l 1l 11u; do echo "== cold $c $(date +%T)"; ./cold.sh $c || echo "FAIL cold $c"; done
echo "== hot-2g-20 $(date +%T)"; ./hot.sh hot-2g-20 1 2 3 4 5 6 7 8 9 10 11 || echo "FAIL hot20"
echo "== hot-2g-40 $(date +%T)"; ./hot.sh hot-2g-40 1l 2l 3l 4l 5l 6l 7l 5u 6u 7u 8u 9u 10u 11u || echo "FAIL hot40"
echo "== ALL DONE $(date +%T)"
