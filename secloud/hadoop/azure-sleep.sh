#!/bin/sh

machines=$(azure vm list sballHadoopMachinesWest | grep running | awk '{ print $3 }' | xargs)

for m in $machines
do
  azure vm deallocate sballHadoopMachinesWest $m
done
