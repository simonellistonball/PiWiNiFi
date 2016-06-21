#!/usr/bin/env bash

log "PiWiNiFi overlay script invoked at $(date)"

log "Deploying overlay into paths"
cp -rf /tmp/overlayunpack/nifi/conf/* /opt/nifi/conf/
cp -rf /tmp/overlayunpack/opt/nifi/conf/* /opt/nifi/conf/
cp -rf /tmp/overlayunpack/opt/nifi/custom /opt/nifi/

unzip -joq /tmp/overlayunpack/jce_policy-8.zip -d ${JAVA_HOME}/jre/lib/security/
mkdir -p /opt/pi && cp -R /tmp/overlayunpack/pi/* /opt/pi
mkdir -p /opt/manuf && cp /tmp/overlayunpack/manuf/* /opt/manuf

log "Setting executables"
chmod +x /opt/pi/deploy/launcher.sh
chmod +x /opt/pi/deploy/bootstrap.sh
chmod +x /opt/pi/deploy/overlay.sh
chmod +x /opt/pi/dnsUpdater/updatedns.sh

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
