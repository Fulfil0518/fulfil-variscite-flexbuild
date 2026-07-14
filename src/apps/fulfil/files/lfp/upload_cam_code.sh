#!/bin/bash
set -euo pipefail

SRC="/root/main.py"

echo 'WARNING: this will only work for the default camera device dir on LFPs in their automounted state'

# Prevent the automounter from re-mounting the camera filesystem after we upload.
# The udev mount.sh script skips devices listed in the ignorelist. Without this,
# a camera reset while the host has sda1 dirty-mounted causes FAT corruption and
# OpenMV resets the filesystem back to factory defaults, wiping main.py.
IGNORELIST_DIR=/etc/udev/mount.ignorelist.d
mkdir -p "$IGNORELIST_DIR"
echo "/dev/sda" > "$IGNORELIST_DIR/openmv-camera"

# Unmount any existing automount (it was mounted before the ignorelist took effect)
umount /run/media/OPENMV-sda1 2>/dev/null || true
rm -f /tmp/.automount-sda1

# Find the OpenMV partition directly
PART=$(ls /dev/disk/by-id/usb*-part1 2>/dev/null | head -1 || true)
if [ -n "$PART" ]; then
    DEV=$(readlink -f "$PART")
else
    DEV="/dev/sda1"
fi
if [ ! -b "$DEV" ]; then
    echo "ERROR: OpenMV mass storage not found" >&2
    echo "  Ensure the camera is in bootloader mode (USB mass storage visible)" >&2
    exit 1
fi

MOUNT=/tmp/openmv_upload
mkdir -p "$MOUNT"
mount "$DEV" "$MOUNT"

echo "Uploading main.py to $DEV..."
cp "$SRC" "$MOUNT/main.py"
sync

# Verify the copy before we're done
src_md5=$(md5sum "$SRC" | awk '{print $1}')
dst_md5=$(md5sum "$MOUNT/main.py" | awk '{print $1}')
if [ "$src_md5" != "$dst_md5" ]; then
    echo "ERROR: md5sum mismatch after copy — upload corrupted" >&2
    echo "  src: $src_md5" >&2
    echo "  dst: $dst_md5" >&2
    umount "$MOUNT"
    rmdir "$MOUNT"
    exit 1
fi

umount "$MOUNT"
rmdir "$MOUNT"
echo "Verified OK (md5: $src_md5)"
echo "files sent"

rm -f /etc/systemd/system/multi-user.target.wants/fulfil-camera-install.service \
    /etc/systemd/system/fulfil-camera-install.service
systemctl daemon-reload
