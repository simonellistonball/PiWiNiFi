#!/bin/bash

# Build and install the custom modules as required

for a in *
do
  if [ -d $a ]
  then
    cd $a
    mvn clean package
    cd ..
  fi
done

for dest in secloud cloud booth
do
  for nar in */*-nar/target/*.nar
  do
    echo "$nar -> $dest"
    cp $nar ../$dest/nifi/custom/
  done
done
