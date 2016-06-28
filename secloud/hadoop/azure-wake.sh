#!/bin/sh

machines=$(azure vm list sballHadoopMachinesWest | grep deallocated | awk '{ print $3 }' | xargs)

for m in $machines
do
  azure vm start sballHadoopMachinesWest $m &
done
