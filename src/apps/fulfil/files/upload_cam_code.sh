#!/bin/bash

echo 'WARNING: this will only work for the last usb mass storage device'
echo
DEV=$(ls -l /dev/disk/by-id/usb*)
DEV=${DEV:(-4)} # this needs to be able to handle multiple devices eventually.
                # should probably be parsing and looking for MicroPy but
                # this will work for now
DEV=/dev/$DEV
echo $DEV
mkdir -p /media/usb/
mount $DEV /media/usb/

if [ $? -eq 0 ]; then
    echo "$DEV Mounted"
    cp main.py /media/usb/
    umount /media/usb/
    echo "files sent"
    exit 0
else
    echo " $DEV not Mounted"
    exit 1
fi

