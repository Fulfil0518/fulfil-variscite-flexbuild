#!/bin/bash
set -e

echo 'WARNING: this will only work for the default camera device dir on LFPs in their automounted state'

ls /run/media/

if [ $? -eq 0 ]; then
    cp main.py /run/media/*sda*
    echo "files sent"
    rm -f /etc/systemd/system/multi-user.target.wants/fulfil-camera-install.service \
        /etc/systemd/system/fulfil-camera-install.service
    systemctl daemon-reload
    exit 0
else
    echo "Device not Mounted"
    exit 1
fi
