#! /bin/sh

DEVICE=$1
FILES_PATH='.'

usage() { echo "usage: $0 <device> [<path>]"; }

if [ -d "$2" ]; then
	FILES_PATH=$2
else
	echo "Error: $2 is not a valid path."
	usage
	exit 2
fi

if [ -z "$DEVICE" ]; then
	echo "Error: No device specified."
	usage
	exit 2
fi

if [ ! -b "$DEVICE" ]; then
	echo "Error: $DEVICE is not a valid device."
	usage
	exit 2
fi

cleanup() {
	mountpoint -q $TEMP_MOUNT && umount "$TEMP_MOUNT"
	[ -d $TEMP_MOUNT ] && rm -rf $TEMP_MOUNT
}

TEMP_MOUNT=$(mktemp -d -t opizero-alpine-XXXXXXXX)

trap 'cleanup' EXIT

echo "Mounting device.."
mount "$DEVICE"1 $TEMP_MOUNT \
	|| { echo "Error: failed to mount ${DEVICE}1"; exit 1; }

echo "Copying files.."
{ cp -r $FILES_PATH/apks "$TEMP_MOUNT"/; cp -r $FILES_PATH/boot "$TEMP_MOUNT"/; } \
	|| { echo "Error: failed to copy from $FILES_PATH"; exit 1; }

echo "Ejecting device.."
eject $DEVICE || true

echo "Done!"
