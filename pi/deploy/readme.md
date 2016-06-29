Fresh Raspbian lite image on RPi

Navigate to /pi/deploy within the project
Copy your nifi.tar.gz to this directory
Copy your ca.crt/client.crt/client.key/prov-client-passwd to this directory from your deployment certificates in the /ca output
Connect to RPi via Ethernet Thunderbolt, share internet connection
Power up Pi
Wait 30s
Start iTerm2
    arp -a | 192.168.2
    ssh pi@192.168.2.<pi>
Password will be raspberry for default install
    sudo raspi-config
Select option 1 to expand filesystem
logout back to /pi/deploy
    scp /pi/deploy/* pi@192.168.2.<pi>:~/
    ssh pi@192.168.2.<pi>
    sudo ./bootstrap.sh
Have a cup of tea
