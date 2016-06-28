#!/bin/sh

for a in piwinifi piwinifi1 piwinifi2 piwinifi3
do
  echo "$a..."
  ssh -tt $a.things.simonellistonball.com sudo /opt/HDF-1.2.0.1-1/nifi/bin/nifi.sh restart
  echo "done"
done
