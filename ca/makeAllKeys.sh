#!/bin/bash

[ ! -d CA ] && ./makeCA.sh

for server in secloud cloud booth piwinifi piwinifi1 piwinifi2 piwinifi3
do
  [ ! -d certs/$server ] && ./makeServerKey.sh $server
done

for user in sball dchaffey jdyer jwitt klerch
do
  [ ! -d users/$user ] && ./makeUserKey.sh $user
done

security add-trusted-cert CA/cacert.pem -k /Users/sball/Library/Keychains/login.keychain
security import users/$USER/$USER.p12 -P $(cat users/$USER/$USER-client-passwd)
