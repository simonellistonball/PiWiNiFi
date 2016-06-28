#!/bin/bash

# Forcing environment variables
. /etc/profile.d/piwinifi.sh


## Logging
# http://mostlyunixish.franzoni.eu/blog/2013/10/08/quick-log-for-bash-scripts/
LOGFILE=/var/log/piwinifi_launcher.log
MAX_LOG_LINES=200

function logsetup {
    TMP=$(tail -n $MAX_LOG_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}

function log {
    echo "[$(date)]:[PiWiNiFi] $*"
}

logsetup

log "PiWiNiFi Launcher script invoked at $(date)"

NEED_REBOOT=false
source /opt/pi/deploy/deploy.cfg

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

## Setting hardware state ###############################

# Setting Adapter parameters
log "Setting up Wifi adapters"

# Copy template interfaces file
cp /opt/pi/deploy/interfaces.txt /etc/network/interfaces
# Modify parameters
sed -i -- "s/CONDEV/$CONDEV/g" /etc/network/interfaces
sed -i -- "s/MONDEV/$MONDEV/g" /etc/network/interfaces
sed -i -- "s/MYSSID/$MYSSID/g" /etc/network/interfaces
sed -i -- "s/MYPSK/$MYPSK/g" /etc/network/interfaces
service networking restart

if [ -d /sys/class/net/wlan1 ]; then
    log "Downing monitoring device ${MONDEV}"
    ifconfig ${MONDEV} down
    while ! grep -q "down" /sys/class/net/wlan1/operstate; do
        sleep 1
    done
    log "Enabling monitoring mode on ${MONDEV}"
    while ! $( iwconfig wlan1 | grep -q "Monitor" ); do 
        iwconfig ${MONDEV} mode monitor 
        sleep 5
    done
    log "Bringing up ${MONDEV}"
    ifconfig ${MONDEV} up
fi
# Disabling power management mode on connection wlan to avoid drop off
log "Settings power saving mode off on ${CONDEV}"
iwconfig ${CONDEV} power off

# waiting to ensure wifi is up and running to avoid boot race condition
log "Waiting to get an internet connection"
for i in {1..50}; do ping -c1 www.github.com &> /dev/null && break; done
sleep 10

# Check hostname - doing in launcher in case image copied from elsewhere with different hostname
if ! grep -q ${HOST} /etc/hosts; then
    log "Setting hostname ..."
    # TODO: This obviously won't work if it's some other random hostname
    sed -i "s/raspberrypi/$HOST/g" /etc/hosts
    sed -i "s/raspberrypi/$HOST/g" /etc/hostname
    NEED_REBOOT=true
else
    log "Hostname already set correctly"
fi

### Any environment setup needs to be done by this point before the overlay is deployed and services started. ###

# manuf module for OUI lookup in wifiMon
log "Checking manuf python module is available..."
# Networking should be up from earlier stages, so this shouldn't fail
if [ ! -s /opt/manuf/__init__.py ]; then
    rm -rf /opt/manuf
    git clone https://github.com/coolbho3k/manuf.py.git /opt/manuf
    touch /opt/manuf/__init__.py
fi


# Checking HDF available
if [ ! -s /opt/nifi/bin/nifi.sh ]; then
    log "Nifi Installation not available, please check the install preparation and re-run bootstrap"
else
    # Getting Overlay
    OVERLAY_URL="${OVERLAY}/${MAC}"
    log "Found Nifi install, now testing Bastion access"
    if curl -fIsS --pass $(cat /home/pi/certs/prov-client-passwd) --cacert /home/pi/certs/ca.crt --key /home/pi/certs/client.key --cert /home/pi/certs/client.crt ${OVERLAY_URL} ; then
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
            . /tmp/overlayunpack/pi/deploy/overlay.sh
            log "Overlay unpack complete, continuing with launcher script."
        fi
    else
        log "Connection to Bastion at ${OVERLAY_URL} returns an error, please check your certs, connectivity and that your device is registered for access."
        return 1
    fi
fi

### Overlay deployment completed, service test and start ###

if [ ${NEED_REBOOT} = true ] ; then
    log "This device needs to reboot before it can operate correctly, rebooting now"
    reboot now
fi

# Checking that the overlay worked, easiest test that script didn't fail
if [ -s /tmp/overlayunpack ]; then
    log "Looks like environment setup is good, starting hs16w services"
    # Start Nifi
    log "Starting nifi"
    /opt/nifi/bin/nifi.sh start
    
    # Running Python senseHat script
    if grep -q "Sense HAT" "/proc/device-tree/hat/product"
    then
     log "Sense Hat detected, starting Sensehat Script"
     nohup python /opt/pi/py/sensehat.py &
    else
     log "Sense Hat not detected, skipping sensehat.py"
    fi
    
    # Running Python wifiMon script
    # Needs to run as root to access raw packet information (easiest solution).
    # Much more efficient than Airodump, use if you can
    log "Launcher is starting the Wifimon script; the following entries will be stdout from wifimon."
    nohup python /opt/pi/py/wifiMon.py $MONDEV &
    log "PiWiNiFi Launcher script probably succeeded at $(date)"
else
    log "Looks like the Overlay update didn't work, check network connectivity and /var/log/piwinifi_*.log"
    log "PiWiNiFi Launcher script probably failed at $(date)"
fi