# Orange Pi Zero Alpine
Alpine for the Orange Pi Zero

Running in RAM, using an SD card only for initial loading of the filesystem and configuration storage.

Pre-built files, ready to go, can be found in `builds/`. There is also a Makefile which allows easy customization and building using either files in `configs/` or defconfigs as a base to work from.

## Versions
```
U-Boot 2020.04-rc3_opizero-00161-g14eb12a3c8

# uname -r
5.6.0-rc4_opizero_default-g6a8c531e7

# cat /etc/alpine-release
3.11.3
```

## Current status
This is a work in progress. Not everything necessarily functions, not everything will necessarily be made to function. (Although if you want to make something function that doesn't feel free to fork and pull request.)

## Install on SD card

### Automatic 
The script `scripts/write_sd.sh` will automatically configure an SD card with a bootable Alpine from a build folder (it expects to see `apks/`, `boot/` and `u-boot-sunxi-with-spl.bin`). If no `<path>` argument is specified it default to the directory it was run from. Be careful about specifying the correct device because the script will happily rewrite the partition table of any device you point it at.

Usage: `sudo ./write_sd.sh <device> <path>`

Example: `sudo ./write_sd.sh /dev/sda builds/default/`

The script `scripts/copy_sd.sh` will copy kernel files to an already-prepared SD card (with U-Boot already written and the `apks/` folder already present), useful for testing new builds without losing Alpine configuration that is already done. As with the `write_sd.sh` script, it wants to be executed inside a build folder or with the path of a build folder specified as the `<path>` argument.

Usage: `sudo ./copy_sd.sh <device> <path>`

Example: `sudo ./copy_sd.sh /dev/sda builds/default/`

### Manual
A manual approach is safer, with less risk of accidentally aiming `dd` and `fdisk` at the wrong device.

1. zero the start of the SD card
	- `dd if=/dev/zero of=<device> bs=1M count=1`
2. write u-boot
	- `dd if=u-boot-sunxi-with-spl.bin of=<device> bs=1024 seek=8`
3. create a FAT32 partition with fdisk (although u-boot will handle other partition types if you prefer)
	- `fdisk <device>`
	- `n`       # add new
	- `p`       # primary partition
	- `1`       # numbered 1
	- `2048`    # from sector 2048
	- `<enter>` # to the last sector
	- `t`       # of type
	- `c`       # W95 FAT32 (LBA)
	- `a`       # make it bootable
	- `w`       # save changes
	- `q`       # exit fdisk
4. format and label partition
	- `mkfs.vfat -n ALPINE <partition>`
5. create folder (if necessary) and mount the SD card
	- `mkdir <mount_path>`
	- `sudo mount <partition> <mount_path>`
6. copy `apks` and `boot` folder
	- `cp -r apks <mount_path>`
	- `cp -r boot <mount_path>` 
7. unmount the SD card and remove the folder (if desired)
	- `sudo umount <partition>`  
	- `rm -rf <mount_path>`
8. eject the SD card before removing it
	- `eject <device>`

## Make
The Makefile will fetch all necessary source files and build whatever needs to be built. `make help` will give a list of options, `make info` will show build parameters (which can be changed by editing variables defined at the top of the Makefile). To build a complete set of files, ready to go onto an SD card, all you need to do is type `make install` and everything else should sort itself out.

This has been tested on Ubuntu Bionic, it should function just fine on other distros though. The prerequisites for building can be installed with `apt-get` on distros that use it:

```
sudo apt-get -y --no-install-recommends --fix-missing install \
	gcc-arm-linux-gnueabihf gcc automake make bison flex swig python-dev musl \
	u-boot-tools dosfstools device-tree-compiler \
	git wget pv
```

Menuconfig will pop up for builds of U-Boot and the linux kernel but the build process is otherwise non-interactive. `make install` will output into `files/`, builds of individual components (e.g. `make uboot`, `make linux`) will output into the respective source folders.

It wouldn't be hard to adapt the Makefile to work with other devices, it's just a matter of providing appropriate config files and device trees.

## Alpine
At the moment the Alpine filesystem that loads is taken directly from the generic ARM distro and not modified.

The default login is `root` with no password.

Initial configuration on first boot can be done with `alpine-setup`. It's a good idea to `apk add haveged` and start it as a service as part of the initial setup (especially if you're using the [WiFi with WPS](#WiFi), but several services will load faster with more entropy available), once repos are configured. As we're running in RAM any config changes will need to be committed to the SD card with `lbu ci` or they'll be lost on reboot.

At some point I plan to customize the OS a bit more, integrating a rootfs builder that allows package selection into the build process in one way or another.

## What Works, What Doesn't
The comments in the sections below apply to the default build (`builds/default`, `configs/kernel.default.config`).

Any other `configs/*.config` files that may be present are works in progress and should be assumed to be entirely non-functional.

### Wired Ethernet
Seems to function just fine.

### WiFi
The xradio WiFi is functional. It can be started with `wpa_supplicant` directly from the command line, or as a service via OpenRC, adding the following to `/etc/conf.d/wpa_supplicant`:

```
wpa_supplicant_args="-B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf"
```

Starting wpa_supplicant at the boot runlevel will cause the boot process to pause for an annoying length of time as it tries to configure the WiFi, due to a lack on entropy at boot. Having haveged running before starting wpa_supplicant dramatically improves this, the easiest way to achieve this is to start haveged as a boot service and wpa_supplicant as a default service:

```
apk add haveged
rc-update add haveged boot
rc-update add wpa_supplicant default
```

In theory it should be possible to make haveged start before wpa_supplicant on the same runlevel by adding appropriate before/after/use/want parameters to the depends() block in the `/etc/init.d/` files, but this isn't working for me at the moment and I've so far not put the effort in to figure out why.

### Serial Console
The UART TX/RX/GND pins, next to the ethernet connector, work as advertised, allowing monitoring of the boot process and providing serial console access as you'd expect.

Make sure you're using a 3.3V serial adapter, the board won't like 5V RS-232 (and if you try +/-15V old-school RS-232 set up a video camera first because I'm curious which components will let the magic smoke out first).

The serial console runs at 115,200 baud (8N1).

### USB
The USB 2.0 port detects and can read/write USB flash drives, I've not yet tested it beyond that. 

### Everything Else
Untested. `dmesg` will have a few complaints about various bits and pieces of hardware.

It's not been a priority for me so far to plug things into the pin headers to see what happens, or to investigate these issues more generally. My intended application for the OPiZero only requires ethernet and a functional UART, although ideally I will get around to looking at other aspects at some point.

## To Do
- build a better initramfs with Alpine rootfs build tools, rather than cut and paste from the generic ARM release
- build a more complete kernel with a variety of modules for common hardware included so we have a device that has working header/GPIO pins and a USB port all sorts of things can be attached to
- see what an absolute minimal build looks like in terms of functionality, and how much of a size reduction it provides
- with a bit of luck, fit the whole thing on a 128Mb/16MB SPI NOR
- try not to get distracted and/or lose interest and actually implement the above

## References
  - [DIY Fully working Alpine Linux for Allwinner and Other ARM SOCs](https://wiki.alpinelinux.org/wiki/DIY_Fully_working_Alpine_Linux_for_Allwinner_and_Other_ARM_SOCs)
  - [armbian/build](https://github.com/armbian/build)
  - [How to compile Linux kernel for Orange Pi Zero](https://blog.brichacek.net/how-to-compile-linux-kernel-for-orange-pi-zero/)
  - [hyphop/miZy-uboot](https://github.com/hyphop/miZy-uboot)
  - [Building u-boot, script.bin and linux-kernel](http://www.orangepi.org/Docs/Building.html)
  - [https://github.com/asxtree/CompileKernelandAlpineLinuxforOrangePi](https://github.com/asxtree/CompileKernelandAlpineLinuxforOrangePi)
