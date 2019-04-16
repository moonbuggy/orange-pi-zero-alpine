setenv fdt_high ffffffff
setenv machid 1029 
setenv bootargs earlyprintk /boot/zImage modules=loop,squashfs,sd-mod,usb-storage modloop=/boot/modloop-sunxi console=${console} 
load mmc 0:1 0x43000000 boot/dtbs/sun8i-h2-plus-orangepi-zero.dtb 
load mmc 0:1 0x41000000 boot/zImage 
load mmc 0:1 0x45000000 boot/initramfs-sunxi
bootz 0x41000000 0x45000000 0x43000000
