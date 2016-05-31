#!/bin/bash

[ ! -d CA ] && ./makeCA.sh

for server in secloud cloud booth
do
  [ ! -d certs/$server ] && ./makeServerKey.sh $server
done

for user in sball dchaffey
do
  [ ! -d users/$user ] && ./makeUserKey.sh $user
done
