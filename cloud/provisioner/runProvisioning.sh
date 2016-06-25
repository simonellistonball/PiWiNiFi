#!/bin/sh
BASE_PATH=${1:-$PWD}

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$BASE_PATH/${1#./}"
}

NIFI_HOME=/opt/nifi
docker run -d -it \
  -l provisioner \
  -p 443:443 \
  -v $(realpath ./data):/data \
  -v $(realpath ./certs):/etc/nginx/certs/:ro \
  simonellistonball/provisioner
