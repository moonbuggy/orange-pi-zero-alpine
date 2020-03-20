#! /bin/sh

DEVICE=$1
TEMP_MOUNT='.mount.tmp'
FILES_PATH='.'

if [ ! -z "$2" ]; then
	FILES_PATH=$2
fi

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

echo "This script will destroy all data on the device you have selected ($DEVICE) and create"
echo "a bootable Alpine installation for the Orange Pi Zero. Running fdisk from a script is"
echo "generally not recommended, you will not have an opportunity to inspect changes to the"
echo "partition table before they are written. You need to be confident that the device you"
echo "have specified ($DEVICE) is the correct device."
echo
while true; do
        read -p "Are you sure you want to continue? " confirmation
        case $(echo "$confirmation" | tr '[:upper:]' '[:lower:]') in
                y|yes ) break;;
                n|no ) echo "Discretion is the better part of valour. Exiting."; exit;;
                * ) echo "Please answer yes or no.";;
        esac
done
echo

sudo parted --script "$DEVICE"1 > /dev/null 2>&1
retval=$?
if [ ! $retval -gt 0 ]; then
        echo "Wiping signatures.."
        sudo wipefs --all --force "$DEVICE"1 > /dev/null 2>&1
        retval=$?
        if [ $retval -gt 0 ]; then
                echo "Error: failed to remove signature, exiting"
                exit 1
        fi
fi

echo "Writing zeroes.."
dd if=/dev/zero of=$DEVICE bs=1M count=1 status=none
retval=$?
if [ $retval -gt 0 ]; then
        echo "Error: failed to write zeros, exiting"
        exit 1
fi

echo "Writing u-boot.."
dd if=$FILES_PATH/u-boot-sunxi-with-spl.bin of=$DEVICE bs=1024 seek=8 status=none
retval=$?
if [ $retval -gt 0 ]; then
        echo "Error: failed to write u-boot, exiting"
        exit 1
fi

echo "Creating partition.."
# from https://superuser.com/a/984637
# include comments so we can see what operations are taking place, but
# strip the comments with sed before sending arguments to fdisk
FDISK_OUTPUT=$(sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $DEVICE
        n       # add new
        p       # primary partition
        1       # numbered 1
        2048    # from sector 2048
                # to the last sector
        t       # of type
        c       # W95 FAT32 (LBA)
        a       # make it bootable
        w       # save changes
        q       # exit fdisk
EOF
)

echo "Formating partition.."
mkfs.vfat -n ALPINE "$DEVICE"1 >/dev/null

echo "Copying files.."
[ -d "$TEMP_MOUNT" ] && rm -rf "$TEMP_MOUNT"
mkdir $TEMP_MOUNT; mount "$DEVICE"1 $TEMP_MOUNT
cp -r $FILES_PATH/apks "$TEMP_MOUNT"/
cp -r $FILES_PATH/boot "$TEMP_MOUNT"/
umount "$TEMP_MOUNT"; rm -rf "$TEMP_MOUNT"

echo "Ejecting device.."
eject $DEVICE

echo "Done!"
