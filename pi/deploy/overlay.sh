#!/usr/bin/env bash

## Logging
# http://mostlyunixish.franzoni.eu/blog/2013/10/08/quick-log-for-bash-scripts/

LOGFILE=/var/log/piwinifi_overlay.log
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
log "PiWiNiFi overlay script invoked at $(date)"

log "Deploying overlay into paths"
cp -rf /tmp/overlayunpack/nifi/conf/* /opt/nifi/conf/
cp -rf /tmp/overlayunpack/nifi/custom/* /opt/nifi/custom/

unzip -joq /tmp/overlayunpack/jce/jce_policy-8.zip -d ${JAVA_HOME}/jre/lib/security/
mkdir -p /opt/pi && cp -R /tmp/overlayunpack/pi/* /opt/pi
mkdir -p /opt/manuf && cp /tmp/overlayunpack/manuf/* /opt/manuf

log "Setting executables"
chmod +x /opt/pi/deploy/launcher.sh
chmod +x /opt/pi/deploy/bootstrap.sh
chmod +x /opt/pi/deploy/overlay.sh
chmod +x /opt/pi/dnsUpdater/update.sh

ln -s /opt/pi/dnsUpdater/update.sh /etc/network/if-up.d/updatedns

log "Adding aws credentials"
cp -rf /tmp/overlayunpack/root/.aws /root/.aws
chmod 600 /root/.aws

# set rc.local to run launcher on boot
log "Ensuring launcher set to run on boot"
if ! grep -q 'launcher.sh' /etc/rc.local ; then
 sed -i '/^exit 0/i /opt/pi/deploy/launcher.sh' /etc/rc.local
fi

# Checking Python dependencies
log "Ensuring python packages are available"
pip install --upgrade pip
# Note that numpy will take absolutely ages to update if --upgrade included, so don't use it or just be patient
pip install -r /opt/pi/py/requirements.txt

log "Update DNS"
/opt/pi/dnsUpdater/update.sh

log "Overlay download, unpack, and deploy completed."
