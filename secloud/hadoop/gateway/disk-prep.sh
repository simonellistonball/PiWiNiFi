#!/bin/sh -

## setup disks
BLANK_DISKS=$(parted -l 2>&1 | grep "unrecognised" | sed 's/Error: \/dev\/\(sd[a-z]\).*/\1/' | xargs)
BLANK_DISKS="sdc sdd"
for a in $BLANK_DISKS
do
  parted -s /dev/$a mklabel gpt mkpart P1 xfs 0 512GB
  mkfs.xfs /dev/${a}1
done

sleep 10

for disk in /dev/disk/by-uuid/*
do
  DISK=$(basename "$(readlink $disk)")
  for a in $BLANK_DISKS
  do
    if [ $DISK == "${a}1" ]
    then
      VOL_ID=$(basename $disk)
      echo "Adding $VOL_ID to fstab as data${a:2:1}"
      if [ ! -d /mnt/data${a:2:1} ]
      then
        mkdir /mnt/data${a:2:1}
        echo "UUID=$VOL_ID /mnt/data${a:2:1}/ xfs noatime,nodev,nobarrier 1 1" >> /etc/fstab
      fi
    fi
  done
done

mount -a
