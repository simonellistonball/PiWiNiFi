#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Lightweight monitoring of minimal details of observed wifi devices for pickup by HDF"""

import sys
# Inserting paths to other python projects we are using
sys.path.insert(0, '/opt/manuf/')

from scapy.all import *
from os import environ
import hashlib
from multiprocessing import Process
import signal
import logging
from logging.handlers import SysLogHandler
from netaddr import *
from os import system as run_command
from json import dumps
from time import time, sleep
from socket import gethostname
# Nifi ListenSyslog requires RFC5424 messages, which python doesn't do well natively
from syslog_rfc5424_formatter import RFC5424Formatter
import manuf


__author__ = 'Daniel Chaffey'
__email__ = "dchaffey@hortonworks.com"
__status__ = "DodgyHack"

# Re-implementation of https://bitbucket.org/edkeeble/wifi-scan
# and http://www.thesprawl.org/projects/airoscapy/

# Control Variables
# Number of seconds between channel hops, also controls delay before re-logging the same device
channel_hopper_scan_rate = 3
channel_hopper_scan_list = random.randrange(1, 15)
log_level = logging.INFO
myname = gethostname()

# Configure Logging
log = logging.getLogger('wifiMon')
log.propagate = False
log.setLevel(log_level)
log_handler = SysLogHandler(address=('localhost', 1514))
log_handler.setFormatter(RFC5424Formatter())
log.addHandler(log_handler)
# Uncomment these two lines to echo sniffed packets to the console for debugging
# con_handler = logging.StreamHandler()
# log.addHandler(con_handler)

# Get wirelss ssid and generate a network location from it to distinguish datasets
# First 4 chars of an md5 hexdigest
my_netloc = "0000"
with open('/etc/network/interfaces') as f:
    for l in f:
        if "ssid" in l:
            my_netloc = hashlib.md5(l).hexdigest()[-4:]

# Define our sniffer function for passing to Scapy
# Pkt types below from https://pen-testing.sans.org/blog/2011/10/13/special-request-wireless-client-sniffing-with-scapy
# Further Scapy information can be gleaned from http://www.secdev.org/projects/scapy/demo.html

# Index of MACs from found devices for windowing
mac_index = {}
oui_lookup = manuf.MacParser('/opt/manuf/manuf')

# You can do an interactive session with scapy from the command line on the pi to investigate anomalous devices
# sudo scapy
# conf.oface = "wlan1mon"
# p = sniff(filter="wlan host 64-BC-0C-64-2E-45", count=1)
# p[0].show()


def packet_sniffer(pkt):
    # print(pkt.show())
    ts_now = int(time())
    log_now = False
    # Determine if pkt is of an useful type - we only collect management packets! No data or security info.
    if pkt.haslayer(Dot11):
        if pkt.haslayer(Dot11Beacon) or pkt.haslayer(Dot11ProbeResp):
            mac = EUI(pkt[Dot11].addr3)
            pkt_type = "AP"
        elif pkt.type == 0 and pkt.subtype in [0, 2, 4]:
            mac = EUI(pkt[Dot11].addr2)
            pkt_type = "CLIENT"
        else:
            pkt_type = "SKIP"

        # Take action based on known MACs and observation timings
        if pkt_type in ["AP", "CLIENT"]:
            if mac not in mac_index:
                mac_index[mac] = {
                    "sensor": myname,
                    "ts_firstseen": ts_now,
                    "ts_lastseen": ts_now,
                    "ts_lastlog": ts_now,
                    "service": pkt_type,
                    "mac": str(mac),
                    "session": "new",
                    "netloc": my_netloc
                }
                log_now = True
            elif mac in mac_index and mac_index[mac]["ts_lastseen"] >= (ts_now - 300):
                # Only update if we haven't in the past scan interval
                if mac_index[mac]["ts_lastseen"] <= (ts_now - channel_hopper_scan_rate):
                    mac_index[mac]["ts_lastseen"] = ts_now
                    mac_index[mac]["session"] = "keep_alive"
                    # refresh log presence if not logged this scan interval
                    if mac_index[mac]["ts_lastlog"] <= (ts_now - channel_hopper_scan_rate):
                        log_now = True
                        mac_index[mac]["ts_lastlog"] = ts_now
            # Refresh information about observed device
            # SSID
            if pkt_type == "AP":
                # Adding a null character filter to ssid strings due to output issues in scapy
                ssid = str(pkt[Dot11Elt].info).replace('\x00', '')
                if len(ssid) == 0:
                    ssid = None
                mac_index[mac]["ssid"] = ssid
                try:
                    mac_index[mac]["channel"] = int(ord(pkt[Dot11Elt:3].info))
                except TypeError:
                    mac_index[mac]["channel"] = 0
            else:
                mac_index[mac]["ssid"] = None
                mac_index[mac]["channel"] = None
            # Signal Strength
            if pkt.haslayer(RadioTap):
                mac_index[mac]["signalDbm"] = -(256-ord(pkt[RadioTap].notdecoded[-4:-3]))
            else:
                mac_index[mac]["signalDbm"] = None
            # Manufacturer
            try:
                mac_index[mac]["manufacturer"] = str(oui_lookup.get_comment(str(mac)))
            except ValueError:
                mac_index[mac]["manufacturer"] = "NotRecognised"

            if log_now is True:
                log.info(dumps(mac_index[mac]))


# Define our channel hopper
def channel_hopper():
    while True:
        try:
            log.debug("Setting [{0}] channel to [{1}]".format(monitoring_interface, channel_hopper_scan_list))
            # Note that this next command occasionally throws '-22' errors to STDERR which can be ignored
            run_command("iw dev {0} set channel {1}".format(monitoring_interface, channel_hopper_scan_list))
            sleep(channel_hopper_scan_rate)
        except KeyboardInterrupt:
            break


# Tidily handle exit commands when running in test console
def signal_handler(signal, frame):
    log.debug("Kill signal received, shutting down gracefully")
    p.terminate()
    p.join()

    sys.exit(0)


if __name__ == "__main__":
    log.info("Launched as main at {0}".format(int(time())))
    # Check we have been supplied with the Monitoring adapter
    monitoring_interface = None
    try:
        assert len(sys.argv) is 2
        monitoring_interface = sys.argv[1]
        log.info("Using monitoring interface {0}".format(monitoring_interface))
    except:
        log.info("Launched without adapter supplied, printing usage information")
        print("Usage: 'wifiMon <Adapter>' e.g wifiMon wlan1mon")
        exit(1)

    # Start the channel hopper in separate process
    log.info("Starting channel_hopper")
    p = Process(target=channel_hopper)
    p.start()

    # Capture CTRL-C
    signal.signal(signal.SIGINT, signal_handler)

    log.info("Starting packet_sniffer")
    sniff(iface=monitoring_interface, prn=packet_sniffer, store=0)
