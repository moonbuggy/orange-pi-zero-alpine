#
# Build U-Boot, kernel and Alpine initramfs/modloop for Orange Pi Zero
#
#	https://github.com/moonbuggy/orange-pi-zero-alpine/
#
# Although the configs included from the GitHub repo are for the Orange Pi Zero it's
# possible to adapt for other devices without a lot of trouble. The variables defined
# below can be adjusted to suit alternative devices, if you have appropraite DTBs
# available and spend some time in menuconfig then Bob's your uncle.
#

# These can be modified as necessary:
#
UBOOT_SOURCE		?= github.com/u-boot/u-boot
#UBOOT_SOURCE		?= github.com/linux-sunxi/u-boot-sunxi
LINUX_SOURCE		?= github.com/linux-sunxi/linux-sunxi -b sunxi-next
XRADIO_SOURCE		?= github.com/fifteenhex/xradio
#XRADIO_SOURCE		?= github.com/moonbuggy/xradio
ALPINE_VERSION		?= 3.9.3
ALPINE_SERVER		?= dl-cdn.alpinelinux.org

UBOOT_DEFCONFIG		?= orangepi_zero_defconfig
LINUX_DEFCONFIG		?= sunxi_defconfig

CROSS_COMPILE		?= arm-linux-gnueabihf-
ARCH			?= arm
MENUCONFIG		?= menuconfig

#INITRAMFS_COMPRESSION	?= gzip -9
INITRAMFS_COMPRESSION	?= xz --check=crc32
MODLOOP_COMPRESSION	?= xz


# These shouldn't need to be modified (although many of them can be if you want):
#
THIS_FILE		:= $(lastword $(MAKEFILE_LIST))
ROOT_DIR		:= $(shell pwd)

CONFIG_DIR		?= configs
SOURCE_DIR		?= source
OUTPUT_DIR		?= files
UBOOT_DIR		?= $(SOURCE_DIR)/u-boot
UBOOT_CONFIG		?= $(UBOOT_DIR)/.config
UBOOT_FILE		?= $(UBOOT_DIR)/u-boot-sunxi-with-spl.bin
LINUX_DIR		?= $(SOURCE_DIR)/linux-sunxi
LINUX_CONFIG		?= $(LINUX_DIR)/.config
LINUX_MOD_PATH		?= $(ROOT_DIR)/$(LINUX_DIR)/output
ZIMAGE_FILE		?= $(LINUX_DIR)/arch/arm/boot/zImage
XRADIO_DIR		?= $(SOURCE_DIR)/xradio
ALPINE_NAME		?= alpine-uboot-$(ALPINE_VERSION)-armv7
ALPINE_DIR		?= $(SOURCE_DIR)/$(ALPINE_NAME)
ALPINE_ARCHIVE		?= $(SOURCE_DIR)/$(ALPINE_NAME).tar.gz

modules_dir		= $(shell find $(LINUX_DIR)/output/lib/modules -maxdepth 1 -type d -regex '.*/[0-9]+.*')
initramfs_temp		?= $(ROOT_DIR)/$(OUTPUT_DIR)/initramfs-temp
initramfs_tempfile	?= $(ROOT_DIR)/$(OUTPUT_DIR)/initramfs-sunxi-temp
modloop_temp		?= $(OUTPUT_DIR)/modloop-temp


.PHONY: help info list-configs all get-all clean mrproper distclean \
	uboot-clean uboot-mrproper uboot uboot-defconfig uboot-% get-uboot \
	linux-clean linux-mrproper linux linux-defconfig linux-% .build-linux .build-modules get-linux \
	xradio get-xradio \
	install-clean install initramfs modloop get-alpine

.DEFAULT_TARGET: help

##@ Information

help:		## display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_%-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo
	@echo "There's no need to manually download source or build individual components (unless you want to modify"
	@echo "them before they're incorporated into the rest of the build), all targets will prepare prerequisites as"
	@echo "necessary (i.e. 'make all' alone is sufficient for a complete build)."
	@echo
	@echo "Files ready for installation will be put in the output folder, other generated files remain within their"
	@echo "individual project folder. The output folder is:"
	@echo
	@echo "	$(ROOT_DIR)/$(OUTPUT_DIR)"
	@echo

info:		## display build parameters
	@echo "U-Boot source:		$(UBOOT_SOURCE)"
	@echo "U-Boot defconfig:	$(UBOOT_DEFCONFIG)"
	@echo "Linux source:		$(LINUX_SOURCE)"
	@echo "Linux defconfig:	$(LINUX_DEFCONFIG)"
	@echo "Xradio source:		$(XRADIO_SOURCE)"
	@echo "Alpine version:		$(ALPINE_VERSION)"
	@echo "Alpine server:		$(ALPINE_SERVER)"
	@echo "make defaults:		ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) MENUCONFIG=$(MENUCONFIG)"
	@echo "Output folder:		$(OUTPUT_DIR)"

list-configs:	## display a list of configs available for custom builds
	@echo "U-Boot configs:		$(shell cd $(CONFIG_DIR); ls u-boot.*.config | awk -F. '{printf "%s ", $$2}'; echo)"
	@echo "Linux configs:		$(shell cd $(CONFIG_DIR); ls kernel.*.config | awk -F. '{printf "%s ", $$2}'; echo)"
	@echo
	@echo "These can be used with 'make-uboot-%' or 'make linux-%' by substituting the '%' with the config option"
	@echo "you want to use. Additional options can be added by placing a configs file named 'u-boot.%.config' or"
	@echo "'kernel.%.config' in '$(CONFIG_DIR)'."
	@echo

##@ Global

all: uboot linux xradio install       ## build U-Boot, linux (including xradio), Alpine RAM filesystem and prepare files for install

get-all: 						## get latest source for U-Boot, linux and xradio and the specified Alpine version
	@$(MAKE) -f $(THIS_FILE) --no-print-directory get-uboot
	@$(MAKE) -f $(THIS_FILE) --no-print-directory get-linux
	@$(MAKE) -f $(THIS_FILE) --no-print-directory get-xradio
	@$(MAKE) -f $(THIS_FILE) --no-print-directory $(ALPINE_DIR)

clean: uboot-clean linux-clean				## remove most generated files in source folders

mrproper: uboot-mrproper linux-mrproper			## remove all generated files in source folders

distclean:						## remove all source files, leave only files in the output folder
	@test ! -d $(SOURCE_DIR) || rm -rf $(SOURCE_DIR)

##@ U-Boot

uboot: $(UBOOT_DIR)		## build U-Boot using existing .config if it exists, otherwise using default
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-uboot

uboot-%: $(UBOOT_DIR)		## build U-Boot with custom config, see 'make list-configs' (discards any existing .config)
	@if [ -f $(CONFIG_DIR)/u-boot.$*.config ]; then \
		cp $(CONFIG_DIR)/u-boot.$*.config $(UBOOT_CONFIG); \
		$(MAKE) -f $(THIS_FILE) --no-print-directory .build-uboot; \
	else \
		echo $(CONFIG_DIR)/u-boot.$*.config does not exist, cannot build.; \
		exit; \
	fi

uboot-defconfig: $(UBOOT_DIR)	## build U-Boot with the defconfig (discards any existing .config)
	$(MAKE) -C $(UBOOT_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(UBOOT_DEFCONFIG)
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-uboot

uboot-clean:                   ## remove most generated files in U-Boot folder
	@test ! -d $(UBOOT_DIR) || $(MAKE) -C $(UBOOT_DIR) clean

uboot-mrproper:                ## remove all generated files in U-Boot folder
	@test ! -d $(UBOOT_DIR) || $(MAKE) -C $(UBOOT_DIR) mrproper

.build-uboot: $(UBOOT_DIR) $(UBOOT_CONFIG)
	$(MAKE) -C $(UBOOT_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MENUCONFIG)
	$(MAKE) -C $(UBOOT_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)


##@ Linux

linux: $(LINUX_DIR)		## build linux using existing .config if present, otherwise using default
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-linux

linux-%: $(LINUX_DIR)		## build linux with custom config, see 'make list-configs' (discards any existing .config)
	@if [ -f $(CONFIG_DIR)/kernel.$*.config ]; then \
		cp $(CONFIG_DIR)/kernel.$*.config $(LINUX_DIR)/.config; \
		$(MAKE) -f $(THIS_FILE) --no-print-directory .build-linux; \
	else \
		echo $(CONFIG_DIR)/kernel.$*.config does not exist, cannot build.; \
	fi

linux-defconfig: $(LINUX_DIR)	## build linux with the defconfig (discards any existing .config)
	$(MAKE) -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(LINUX_DEFCONFIG)
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-linux

linux-clean:                    ## remove most generated files in linux folder
	@test ! -d $(LINUX_DIR) || $(MAKE) -C $(LINUX_DIR) clean

linux-mrproper:                 ## remove all generated files in linux folder
	@test ! -d $(LINUX_DIR) || $(MAKE) -C $(LINUX_DIR) mrproper

.build-linux: $(LINUX_DIR) $(LINUX_CONFIG)
	$(MAKE) -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MENUCONFIG)
	$(MAKE) -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) zImage dtbs
#	$(MAKE) -f $(THIS_FILE) --no-print-director $(ZIMAGE_FILE)
	$(MAKE) -f $(THIS_FILE) --no-print-director .build-modules

.build-modules: $(LINUX_DIR)
	@if [ -d $(LINUX_MOD_PATH) ]; then \
		rm -rf $(LINUX_MOD_PATH)/; \
	fi
	$(MAKE) -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules
	$(MAKE) -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) INSTALL_MOD_PATH=$(LINUX_MOD_PATH) modules_install
	@$(MAKE) -f $(THIS_FILE) --no-print-director xradio


xradio: $(LINUX_DIR) $(XRADIO_DIR)	## build xradio module
	$(MAKE) -C $(LINUX_DIR) M=$(ROOT_DIR)/$(XRADIO_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules
	$(MAKE) -C $(LINUX_DIR) M=$(ROOT_DIR)/$(XRADIO_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) INSTALL_MOD_PATH=$(LINUX_MOD_PATH) modules_install


##@ Installation Files

$(OUTPUT_DIR):
	@mkdir -p $(OUTPUT_DIR)/boot/dtbs

install: install-clean $(OUTPUT_DIR) $(UBOOT_FILE) $(ZIMAGE_FILE) $(ALPINE_DIR)		## prepare all files files for installation
	@echo Copying files..
	@cp -r $(ALPINE_DIR)/apks $(OUTPUT_DIR)
	@cp $(ZIMAGE_FILE) $(OUTPUT_DIR)/boot/
	@cp $(CONFIG_DIR)/boot.cmd $(OUTPUT_DIR)/boot/
	@cp $(UBOOT_FILE) $(OUTPUT_DIR)/
	@cp $(CONFIG_DIR)/sun8i-h2-plus-orangepi-zero.dt* $(OUTPUT_DIR)/boot/dtbs/

	@echo; echo Making boot.scr..
	@mkimage -C none -A $(ARCH) -T script -d $(OUTPUT_DIR)/boot/boot.cmd $(OUTPUT_DIR)/boot/boot.scr

	@$(MAKE) -f $(THIS_FILE) --no-print-directory initramfs
	@$(MAKE) -f $(THIS_FILE) --no-print-directory modloop
	@echo; echo Done.

initramfs: $(OUTPUT_DIR) $(ALPINE_DIR) $(LINUX_MOD_PATH)		## create Alpine initramfs file only
	@test -d $(modules_dir) || $(MAKE) -f $(THIS_FILE) --no-print-directory .build-modules
	@echo; echo Making initramfs..
	@mkdir -p $(initramfs_temp)
	@gunzip -c $(shell find $(ALPINE_DIR) -name 'initramfs*') | cpio -i --quiet -D $(initramfs_temp)
	@rm -rf $(initramfs_temp)/lib/modules/*
	@cp -rP $(modules_dir) $(initramfs_temp)/lib/modules/ && find $(initramfs_temp)/lib/modules/ -type l -delete
	@cp -rP firmware $(initramfs_temp)/lib/ 2>/dev/null
	@cd $(initramfs_temp)/; find . | cpio --quiet -H newc -o | $(INITRAMFS_COMPRESSION) $(INITRAMFS_COMPRESSION_ARGS) > $(initramfs_tempfile)
	@mkimage -n initramfs-sunxi -A $(ARCH) -O linux -T ramdisk -C none -d $(initramfs_tempfile) $(OUTPUT_DIR)/boot/initramfs-sunxi
	@rm -rf $(initramfs_temp) $(initramfs_tempfile)

modloop: $(OUTPUT_DIR) $(ALPINE_DIR) $(LINUX_MOD_PATH)			## create Alpine modloop file only
	@test -d $(modules_dir) || $(MAKE) -f $(THIS_FILE) --no-print-directory .build-modules
	@echo; echo Making modloop..
	@mkdir -p $(modloop_temp)/modules
	@cp -rP $(modules_dir) $(modloop_temp)/modules/ && find $(modloop_temp)/modules/ -type l -delete
	@cp -rP firmware $(modloop_temp)/modules/ 2>/dev/null
	@mksquashfs $(modloop_temp) $(OUTPUT_DIR)/boot/modloop-sunxi -b 1048576 -comp $(MODLOOP_COMPRESSION) -Xdict-size 100% -noappend
	@rm -rf $(modloop_temp)

install-clean:                          ## remove previously generated installation files
	@echo Cleaning old files..
	@test ! -d $(OUTPUT_DIR) || find $(OUTPUT_DIR)/ ! -type d -delete


##@	Source Files

get-uboot: $(SOURCE_DIR)		## clone or update U-Boot from repo
	$(call git,U-Boot,$(UBOOT_SOURCE),$(UBOOT_DIR))

get-linux: $(SOURCE_DIR)		## clone or update linux from repo
	$(call git,linux,$(LINUX_SOURCE),$(LINUX_DIR),--depth 1)

get-xradio: $(SOURCE_DIR)		## clone or update xradio from repo
	$(call git,xradio,$(XRADIO_SOURCE),$(XRADIO_DIR))

get-alpine: $(SOURCE_DIR)		## download Alpine from repo and untar (if necessary)
	@echo Checking Alpine..
	@$(MAKE) -f $(THIS_FILE) --no-print-directory $(ALPINE_DIR)

$(SOURCE_DIR):
	@mkdir -p $(SOURCE_DIR)

define git
	@echo Checking ${1}..
	@test ! -d ${3} \
	  && git clone git://${2} ${4} ${3} \
	  || git -C ${3} pull ${4}
	@echo
endef

$(UBOOT_DIR):
	@$(MAKE) -f $(THIS_FILE) --no-print-directory get-uboot

$(UBOOT_CONFIG): | $(UBOOT_DIR)
	@test -f $(UBOOT_CONFIG) || cp $(CONFIG_DIR)/u-boot.default.config $(UBOOT_CONFIG)

$(UBOOT_FILE): | $(UBOOT_DIR)
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-uboot

$(LINUX_DIR):
	@$(MAKE) -f $(THIS_FILE) --no-print-directory get-linux

$(LINUX_CONFIG): | $(LINUX_DIR)
	@test -f $(LINUX_CONFIG) || cp $(CONFIG_DIR)/kernel.default.config $(LINUX_CONFIG)

$(LINUX_MOD_PATH): | $(LINUX_DIR)
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-modules

$(XRADIO_DIR):
	@$(MAKE) -f $(THIS_FILE) --no-print-directory get-xradio

$(ZIMAGE_FILE): | $(LINUX_DIR)
	@$(MAKE) -f $(THIS_FILE) --no-print-directory .build-linux

$(ALPINE_DIR): | $(ALPINE_ARCHIVE)
	@echo;	echo Untarring Alpine..
	@mkdir -p $(ALPINE_DIR)
ifneq (, $(shell which pv))
	@pv $(ALPINE_ARCHIVE) | tar -C $(ALPINE_DIR) -zxf -
else
	@tar -C $(ALPINE_DIR) -zxf $(ALPINE_ARCHIVE)
endif
	@echo

$(ALPINE_ARCHIVE):
	@echo Downloading Alpine..
	@wget --show-progress --progress=bar:force -q -P $(SOURCE_DIR)/ http://$(ALPINE_SERVER)/alpine/v$(shell echo $(ALPINE_VERSION) | cut -f1,2 -d".")/releases/armv7/$(ALPINE_NAME).tar.gz
