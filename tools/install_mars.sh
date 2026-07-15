#!/bin/bash
set -euo pipefail

install_debian.sh

MOUNT_DIR=/run/media/mmcblk2p1
ROOT_PASSWORD_HASH_FILE="$MOUNT_DIR/opt/fulfil/common/root-password.hash"

# remove the lfp specific files from the filesystem
mkdir -p "$MOUNT_DIR"
mount /dev/mmcblk2p1 "$MOUNT_DIR"

rm -rf "$MOUNT_DIR/opt/fulfil/lfp"

# set the root pw
printf 'root:%s\n' "$(cat "$ROOT_PASSWORD_HASH_FILE")" \
    | chpasswd \
        --root "$MOUNT_DIR" \
        --encrypted

rm "$ROOT_PASSWORD_HASH_FILE"

umount "$MOUNT_DIR"
