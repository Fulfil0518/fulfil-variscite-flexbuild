#!/bin/bash
set -euo pipefail

install_debian.sh

MOUNT_DIR=/run/media/mmcblk2p1
LFP_DIR="$MOUNT_DIR/opt/fulfil/lfp"
ROOT_PASSWORD_HASH_FILE="$MOUNT_DIR/opt/fulfil/common/root-password.hash"

# set up LFP services
mkdir -p "$MOUNT_DIR"
mount /dev/mmcblk2p1 "$MOUNT_DIR"

# 0. Set the root pw
printf 'root:%s\n' "$(cat "$ROOT_PASSWORD_HASH_FILE")" \
    | chpasswd \
        --root "$MOUNT_DIR" \
        --encrypted

rm "$ROOT_PASSWORD_HASH_FILE"

# 1. Install the firstboot script with executable permissions
install -m 0755 "$LFP_DIR/firstboot.sh" \
    "$MOUNT_DIR/usr/local/sbin/firstboot.sh"

# 2. Install and enable the firstboot service
install -m 0644 "$LFP_DIR/fulfil-firstboot.service" \
    "$MOUNT_DIR/etc/systemd/system/fulfil-firstboot.service"

ln -sf "$MOUNT_DIR/etc/systemd/system/fulfil-firstboot.service" \
    "$MOUNT_DIR/etc/systemd/system/multi-user.target.wants/fulfil-firstboot.service"

# 3. Install and enable the camera service
chmod +x "$LFP_DIR/camera_install.sh"

install -m 0644 "$LFP_DIR/fulfil-camera-install.service" \
    "$MOUNT_DIR/etc/systemd/system/fulfil-camera-install.service"

ln -sf "$MOUNT_DIR/etc/systemd/system/fulfil-camera-install.service" \
    "$MOUNT_DIR/etc/systemd/system/multi-user.target.wants/fulfil-camera-install.service"

# 4. Install the lfp-core service
install -m 0644 "$LFP_DIR/lfp-core.service" \
    "$MOUNT_DIR/etc/systemd/system/lfp-core.service"
ln -sf "$MOUNT_DIR/etc/systemd/system/lfp-core.service" \
    "$MOUNT_DIR/etc/systemd/system/multi-user.target.wants/lfp-core.service"

umount "$MOUNT_DIR"
