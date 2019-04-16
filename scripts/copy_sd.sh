#! /bin/sh

DEVICE=$1
TEMP_MOUNT='.mount.tmp'

if [ -z "$DEVICE" ]; then
        echo "No device specified."
        echo "usage: $0 <device>"
        exit 1
fi

if [ -b "$DEVICE" ]; then
        true
else
        echo "Error: $DEVICE is not a valid device."
        exit 1
fi

echo "Copying files.."
[ -d "$TEMP_MOUNT" ] && rm -rf "$TEMP_MOUNT"
mkdir $TEMP_MOUNT; mount "$DEVICE"1 $TEMP_MOUNT
#cp -r apks "$TEMP_MOUNT"/
cp -r boot "$TEMP_MOUNT"/
umount "$TEMP_MOUNT"; rm -rf "$TEMP_MOUNT"

echo "Ejecting device.."
eject $DEVICE

echo "Done!"

