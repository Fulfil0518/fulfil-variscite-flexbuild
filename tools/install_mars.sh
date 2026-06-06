#!/bin/bash
set -euo pipefail

install_debian.sh

MOUNT_DIR=/run/media/mmcblk2p1

# remove the lfp specific files from the filesystem
mkdir -p "$MOUNT_DIR"
mount /dev/mmcblk2p1 "$MOUNT_DIR"

rm -rf "$MOUNT_DIR/opt/fulfil/lfp"

umount "$MOUNT_DIR"
