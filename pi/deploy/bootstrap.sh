#!/usr/bin/env bash

## Logging
# http://mostlyunixish.franzoni.eu/blog/2013/10/08/quick-log-for-bash-scripts/

LOGFILE=/var/log/piwinifi_bootstrap.log
MAX_LOG_LINES=200

function logsetup {
    TMP=$(tail -n $MAX_LOG_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > ${LOGFILE}
    exec > >(tee -a ${LOGFILE})
    exec 2>&1
}

function log {
    echo "[$(date)]:[PiWiNiFi] $*"
}

logsetup
log "PiWiNiFi Bootstrap script invoked at $(date)"

source deploy.cfg

# Set Timezone
log "Setting Timezone..."
echo "$TIMEZONE" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# We need this for initial installs
apt-get -y install ethtool

## Detecting environment state ######################

log "Determining WLAN monitoring adapter"
# Determining which adapter is the USB RT5370, and setting it as monitoring adapter
DRV="$(ethtool -i wlan0 | grep -i driver | awk '{ print $2; }')"
log "wlan0 is $DRV"
# Checking for the known RPI3b broadcom chip, as the USB monitoring dongle could vary
if [ "$DRV" == "brcmfmac" ]
then
    MONDEV='wlan1'
    CONDEV='wlan0'
else
    MONDEV='wlan0'
    CONDEV='wlan1'
fi
log "Using hardware device $MONDEV for monitoring, and probably $CONDEV for network connectivity"


### Position bootstrap files
# Copy template interfaces file
cp ./interfaces.txt /etc/network/interfaces
# Modify parameters
sed -i -- "s/CONDEV/$CONDEV/g" /etc/network/interfaces
sed -i -- "s/MONDEV/$MONDEV/g" /etc/network/interfaces
sed -i -- "s/MYSSID/$MYSSID/g" /etc/network/interfaces
sed -i -- "s/MYPSK/$MYPSK/g" /etc/network/interfaces
service networking restart

# Set certs location
rm -rf /home/pi/certs
mkdir -p /home/pi/certs && cp ./*passwd ./*.crt ./*.key /home/pi/certs

# Preload HDF
cp ./nifi.tar.gz /media/nifi.tar.gz
# set the HDF gz to readonly so we don't scp it if it's already there
chmod 0444 ./nifi.tar.gz
###

### OS Update if not run recently
if [ $(stat -c %Y /var/cache/apt/) -lt $(date +%s -d "2 days ago") ]; then
    log "Running OS update/upgrade/firmware update..."
    apt-key update
    apt-get update -y
#    apt-get upgrade -y
#    rpi-update
    apt-get autoremove -y
else 
    log "OS update run recently, skipping..."
fi

# Install dependencies
log "Checking software dependencies..."
apt-get -y --fix-missing install ipython libssl-dev python-dev tcpdump python-scapy ethtool python-netaddr libffi-dev libjpeg8-dev ca-certificates bluez bluetooth blueman

# Set environment variables
if [ ! -s /etc/profile.d/piwinifi.sh ]; then
    log "Environment Variables not set, fixing..."
    # generate hostname from last 3 octets of mac address
    MAC="$(cat /sys/class/net/wlan0/address)"
    IFS=':' read -ra ADDR <<< "$MAC"
    HOST="rpi${ADDR[03]}${ADDR[04]}${ADDR[05]}"
    IFS=''
    # Since we're designed to work on wifi networks, using the ssid to generate a unique-ish location id
    echo "export JAVA_HOME=/usr/lib/jvm/jdk-8-oracle-arm32-vfp-hflt" > /etc/profile.d/piwinifi.sh
    echo "export MAC=${MAC}" >> /etc/profile.d/piwinifi.sh
    echo "export HOST=${HOST}" >> /etc/profile.d/piwinifi.sh
    echo "export PATH=${JAVA_HOME}/bin:$PATH" >> /etc/profile.d/piwinifi.sh
else
    log "Environment Variables already scripted, continuing..."
fi

log "Sourcing environment variables..."
. /etc/profile.d/piwinifi.sh

# Install HDF
if [ ! -d /opt/nifi/ ] || [ ! $(du -s /opt/nifi/ | awk '{print $1}') -gt 300000 ]; then
    log "HDF install missing or undersized, silently unpacking into /opt (will take a couple of mins)..."
    tar -xf /media/nifi.tar.gz -C /opt/
else
    log "HDF install present, skipping unpack..."
fi   

# Getting launcher and overlay for first run after boot
# Getting Overlay
OVERLAY_URL="${OVERLAY}/${MAC}"
log "Found Nifi install, now testing Bastion access"
log "Using Overlay URL constructed from Config and Mac of: ${OVERLAY_URL}"
# testing if Pi is not registered with bastion
if ! curl -fIsS --pass $(cat /home/pi/certs/prov-client-passwd) --cacert /home/pi/certs/ca.crt --key /home/pi/certs/client.key --cert /home/pi/certs/client.crt ${OVERLAY_URL} ; then
    # Registering with Overlay
    curl -v "${OVERLAY}/" --cert client.crt --key client.key --pass $(cat ./prov-client-passwd ) --cacert ./ca.crt --data "mac=${MAC}&submit=Share"
fi

log "Downloading latest overlay from ${OVERLAY_URL}"
curl -fsS --pass $(cat /home/pi/certs/prov-client-passwd) --cacert /home/pi/certs/ca.crt --key /home/pi/certs/client.key --cert /home/pi/certs/client.crt ${OVERLAY_URL} > /tmp/overlay
log "Checking overlay package"
if ! file /tmp/overlay | grep -iq "gzip"; then
    log "Overlay download failed from Bastion, check the URL is correct and Bastion is available."
else
    log "Unpacking latest overlay"
    # Forcing unpack to specific dir incase overlay contains odd dir structure
    mkdir -p /tmp/overlayunpack && tar -zxvf /tmp/overlay -C /tmp/overlayunpack/ --warning=no-timestamp
    log "Running overlay deployment script"
    . /tmp/overlayunpack/rpiCode/overlay.sh
fi

log "Setting hostname ..."
# raspberrypi is the Raspbian default hostname, change it if you have a different OS
sed -i "s/raspberrypi/${HOST}/g" /etc/hosts
sed -i "s/raspberrypi/${HOST}/g" /etc/hostname

if [ -s /tmp/overlay ]; then
    log "PiWiNiFi Bootstrap excution completed, please check /var/log/piwinifi_bootstrap.log for errors and reboot if ready to launch."
    log "Bootstrap completed, automatically rebooting in 10 seconds"
    sleep 10
    reboot now
else
    log "Overlay didn't download as expected, please check /var/log/piwinifi_* for details and retry."
fi
log "PiWiNiFi Bootstrap script finished at $(date)"
