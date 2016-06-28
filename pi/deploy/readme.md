Fresh Raspbian lite image on pi
Connect via Ethernet Thunderbolt, share internet connection
Power up Pi
Wait 30s
Start iTerm2
    arp -a | 192.168.2
    ssh pi@192.168.2.<pi>
Password will be raspberry for default install
    sudo raspi-config
Select option 1 to expand filesystem
Select option 2 to set new password to BadPass#1
    sudo reboot now
