#!/bin/bash
set -x

bash /root/upload_cam_code.sh
# if the upload script worked, remove this service file and reload systemd
if [ $? -eq 0 ]; then
    rm -f /etc/systemd/system/multi-user.target.wants/fulfil-camera-install.service \
        /etc/systemd/system/fulfil-camera-install.service
    systemctl daemon-reload
fi