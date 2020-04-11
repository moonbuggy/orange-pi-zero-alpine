setenv fdt_high ffffffff
setenv load_addr "0x44000000"
setenv overlay_prefix "sun8i-h2-plus-"
setenv machid 1029

setenv bootargs earlyprintk /boot/zImage modules=loop,squashfs,sd-mod,usb-storage,xr819 modloop=/boot/modloop-sunxi console=${console}
load mmc 0:1 ${fdt_addr_r} /boot/dtbs/sun8i-h2-plus-orangepi-zero.dtb
load mmc 0:1 0x41000000 /boot/zImage

fdt addr ${fdt_addr_r}
fdt resize 65536

if test -e mmc 0:1 /boot/bootEnv.txt; then
    load mmc 0:1 ${load_addr} /boot/bootEnv.txt
    env import -t ${load_addr} ${filesize}
fi

for overlay_file in ${overlays}; do
    echo "Loading ${overlay_prefix}${overlay_file}.dtbo.."
    if load mmc 0:1 ${load_addr} /boot/dtbs/overlays/${overlay_prefix}${overlay_file}.dtbo; then
        echo "Applying user provided DT overlay ${overlay_prefix}${overlay_file}.dtbo.."
        fdt apply ${load_addr} && setenv overlay_applied "true" || setenv overlay_error "true"
    fi
done

if test "${overlay_error}" = "true"; then
	echo "Error applying DT overlays, restoring original DT"
	load mmc 0:1 ${fdt_addr_r} /boot/dtbs/sun8i-h2-plus-orangepi-zero.dtb
elif test "${overlay_applied}" = "true"; then
	if load mmc 0:1 ${load_addr} /boot/dtbs/overlays/sun8i-h2-plus-fixup.scr; then
		echo "Applying kernel provided DT fixup script sun8i-h2-plus-fixup.scr.."
		source ${load_addr}
	fi
fi

load mmc 0:1 0x45000000 /boot/initramfs-sunxi

bootz 0x41000000 0x45000000 0x43000000
