#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Logs Temp/Pressure/Humidity and Movement events with LED outputs indicating operational state."""

__author__ = 'Daniel Chaffey'
__email__ = "dchaffey@hortonworks.com"
__status__ = "DodgyHack"

from sense_hat import SenseHat
from PIL import Image
import PIL.ImageOps
import logging
from logging.handlers import SysLogHandler
import time
import socket
from json import dumps
from syslog_rfc5424_formatter import RFC5424Formatter


# Set control variables
log_level = logging.INFO
sh = SenseHat()
my_hostname = socket.getfqdn()

# Configure Logging
log = logging.getLogger('senseHat')
log.propagate = False
log.setLevel(log_level)
log_handler = SysLogHandler(address=('localhost', 1514))
log_handler.setFormatter(RFC5424Formatter())
log.addHandler(log_handler)


# Setup LED output
sh.set_rotation(90)

pos_img_base = Image.open('/opt/pi/py/ledStaticImg.png')
pos_img = pos_img_base.convert('RGB')
pos_img_pixels = list(pos_img.getdata())

neg_img_base = PIL.ImageOps.invert(pos_img)
neg_img = neg_img_base.convert('RGB')
neg_img_pixels = list(neg_img.getdata())

sh.set_pixels(pos_img_pixels)


def get_ts():
    return int(time.time())

# Init interval checking variables
env_last_logged = get_ts()
movement_last_logged = get_ts()
while True:
    ts = get_ts()

    x, y, z = sh.get_accelerometer_raw().values()
    if (abs(x) > 1.2 or abs(y) > 1.2 or abs(z) > 1.2) and ts > movement_last_logged + 1:
        info = {
            "sensor": my_hostname,
            "type": "MOVEMENT",
            "message": "sensor acceleration detected"
        }
        log.warning(dumps(info))
        sh.set_pixels(neg_img_pixels)
        movement_last_logged = ts
    elif ts > movement_last_logged + 1:
        sh.set_pixels(pos_img_pixels)

    if ts % 30 is 0 and ts > env_last_logged:
        info = {
            "sensor": my_hostname,
            "type": "ENVIRONMENT",
            "temp": round(sh.get_temperature(), 1),
            "pressure": round(sh.get_pressure(), 1),
            "humidity": round(sh.get_humidity(), 1)
        }
        log.info(dumps(info))
        env_last_logged = ts
