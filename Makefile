
# Target Board
board_list = zc702 zc706 zcu102 zcu106

BOARD ?= zc702
#BOARD ?= zc706
#BOARD ?= zcu102
#BOARD ?= zcu106

ETHADDR ?=

# Environment checks
ifeq ("$(XILINX_VIVADO)","")
$(error XILINX_VIVADO path not specified)
endif

ifeq ($(findstring 2018.2, $(XILINX_VIVADO)),)
$(error Vivado version must be 2018.2)
endif

ifeq ($(filter $(BOARD),$(board_list)),)
$(error Supported boards are $(board_list))
endif

# Configuration
ZYNQ_ROOT=$(PWD)
SCRIPTS=$(ZYNQ_ROOT)/scripts
OUT=$(ZYNQ_ROOT)/out
IMAGES=$(OUT)/$(BOARD)/images
SD-CARD=$(OUT)/$(BOARD)/sd-card
LINUX_BUILD=$(OUT)/$(BOARD)/linux
UBOOT_BUILD=$(OUT)/$(BOARD)/u-boot
VIVADO_BUILD=$(OUT)/$(BOARD)/vivado
SDK_BUILD=$(OUT)/$(BOARD)/sdk

# ZYNQ 7-series
ifneq ($(findstring zc7, $(BOARD)),)
ARCH=arm
UBOOT_ARCH=arm
CROSS_COMPILE=arm-linux-gnueabihf-
UBOOT_DEFCONFIG=zynq_$(BOARD)_config
LINUX_DEFCONFIG=xilinx_zynq_defconfig
LINUX_OPT=UIMAGE_LOADADDR=0x8000
LINUX_TARGET=uImage
LINUX_IMAGE=uImage
ROOTFS_NAME=zynq
DEVTREE=devicetree.dtb
CMA_SIZE=256MB
endif

# ZYNQ MP SoC Ultrascale+
ifneq ($(findstring zcu102, $(BOARD)),)
REVISION=rev1_0
endif

ifneq ($(findstring zcu106, $(BOARD)),)
REVISION=revA
endif

ifneq ($(findstring zcu, $(BOARD)),)
ARCH=arm64
UBOOT_ARCH=arm
CROSS_COMPILE=aarch64-linux-gnu-
UBOOT_DEFCONFIG=xilinx_zynqmp_$(BOARD)_$(REVISION)_config
LINUX_DEFCONFIG=xilinx_zynqmp_defconfig
LINUX_OPT=
LINUX_TARGET=
LINUX_IMAGE=Image
ROOTFS_NAME=zynqmp
DEVTREE=system.dtb
CMA_SIZE=512MB
endif


all: sd-card


# u-boot
$(UBOOT_BUILD)/.config:
	@echo "=== $(BOARD): configuring u-boot ==="
	@mkdir -p $(UBOOT_BUILD)
	@KBUILD_OUTPUT=$(UBOOT_BUILD) ARCH=$(UBOOT_ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C u-boot-xlnx $(UBOOT_DEFCONFIG)
	@sed -i 's/run distro_bootcmd/run sdboot/g' $@

$(UBOOT_BUILD)/u-boot: $(UBOOT_BUILD)/.config
	@echo "=== $(BOARD): building u-boot ==="
	@KBUILD_OUTPUT=$(UBOOT_BUILD) ARCH=$(UBOOT_ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C u-boot-xlnx


u-boot: $(UBOOT_BUILD)/u-boot

clean-u-boot:
	rm -rf $(UBOOT_BUILD)

.PHONY: u-boot clean-u-boot


# Linux
$(LINUX_BUILD)/.config:
	@echo "=== $(BOARD): configuring Linux ==="
	@mkdir -p $(LINUX_BUILD)
	@KSRC=linux-xlnx ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) O=$(LINUX_BUILD) -C linux-xlnx $(LINUX_DEFCONFIG)


$(LINUX_BUILD)/arch/$(ARCH)/boot/$(LINUX_IMAGE): $(LINUX_BUILD)/.config $(UBOOT_BUILD)/u-boot
	@echo "=== $(BOARD): building Linux ==="
	@rm -f $@
	@PATH=$(UBOOT_BUILD)/tools:$(PATH) KSRC=linux-xlnx ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C $(LINUX_BUILD) $(LINUX_OPT) $(LINUX_TARGET)


linux: $(LINUX_BUILD)/arch/$(ARCH)/boot/$(LINUX_IMAGE)

clean-linux:
	rm -rf $(LINUX_BUILD)

.PHONY: linux clean-linux


# Built images
$(IMAGES)/u-boot.elf: $(UBOOT_BUILD)/u-boot
	@mkdir -p $(IMAGES)
	@cp $< $@

$(IMAGES)/$(LINUX_IMAGE): $(LINUX_BUILD)/arch/$(ARCH)/boot/$(LINUX_IMAGE)
	@mkdir -p $(IMAGES)
	@cp $< $@

$(IMAGES)/system_wrapper.bit: $(VIVADO_BUILD)/$(BOARD).runs/impl_1/system_wrapper.bit
	@mkdir -p $(IMAGES)
	@cp $< $@

$(IMAGES)/system.dtb: $(SDK_BUILD)/dt/system.dtb
	@mkdir -p $(IMAGES)
	@cp $< $@

$(IMAGES)/fsbl.elf: $(SDK_BUILD)/fsbl/executable.elf
	@mkdir -p $(IMAGES)
	@cp $< $@

ifneq ($(findstring zcu, $(BOARD)),)
$(IMAGES)/pmufw.elf: $(SDK_BUILD)/pmufw/executable.elf
	@mkdir -p $(IMAGES)
	@cp $< $@

$(IMAGES)/bl31.elf: arm-trusted-firmware/build/zynqmp/release/bl31/bl31.elf
	@mkdir -p $(IMAGES)
	@cp $< $@


$(IMAGES)/BOOT.bin: 			\
	$(SCRIPTS)/zynqmp.bif		\
	$(IMAGES)/fsbl.elf		\
	$(IMAGES)/pmufw.elf		\
	$(IMAGES)/system_wrapper.bit 	\
	$(IMAGES)/bl31.elf		\
	$(IMAGES)/u-boot.elf
	@echo "=== $(BOARD): generating bootstrap ==="
	@cd $(IMAGES); \
	bootgen -arch zynqmp -image $< -o i BOOT.bin -w on;

else

$(IMAGES)/BOOT.bin: 			\
	$(SCRIPTS)/zynq.bif		\
	$(IMAGES)/fsbl.elf		\
	$(IMAGES)/system_wrapper.bit 	\
	$(IMAGES)/u-boot.elf
	@echo "=== $(BOARD): generating bootstrap ==="
	@cd $(IMAGES); \
	bootgen -arch zynq -image $< -o i BOOT.bin -w on;


endif

$(IMAGES)/$(ROOTFS_NAME)_rootfs.tar:
	@echo "=== $(BOARD): downloading template rootfs ==="
	@mkdir -p $(IMAGES)
	@wget http://espdev.cs.columbia.edu/zynq/$(ROOTFS_NAME)_rootfs.tar -O $@

images:						\
	$(IMAGES)/BOOT.bin 			\
	$(IMAGES)/$(LINUX_IMAGE)		\
	$(IMAGES)/system.dtb			\
	$(IMAGES)/$(ROOTFS_NAME)_rootfs.tar


clean-images:
	rm -rf $(IMAGES)

.PHONY: images clean-images



# SD card
$(SD-CARD)/root: $(IMAGES)/$(ROOTFS_NAME)_rootfs.tar
	@echo "=== $(BOARD): extracting template rootfs ==="
	@mkdir -p $(SD-CARD)
	@cd $(SD-CARD); tar xf $<; touch $@

$(SD-CARD)/boot/BOOT.bin: $(IMAGES)/BOOT.bin
	@mkdir -p $(SD-CARD)/boot
	@cp $< $@

$(SD-CARD)/boot/$(LINUX_IMAGE): $(IMAGES)/$(LINUX_IMAGE)
	@mkdir -p $(SD-CARD)/boot
	@cp $< $@

$(SD-CARD)/boot/$(DEVTREE): $(IMAGES)/system.dtb
	@mkdir -p $(SD-CARD)/boot
	@cp $< $@


ifneq ($(findstring zcu, $(BOARD)),)

$(SD-CARD)/boot/uEnv.txt:
	@echo "=== $(BOARD): generating uEnv.txt ==="
	@mkdir -p $(SD-CARD)/boot
	@echo "bootargs=earlycon clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait cma=$(CMA_SIZE) uio_pdrv_genirq.of_id=generic-uio" > $@
	@if [ "$(ETHADDR)" != "" ]; then \
		echo "ethaddr=$(ETHADDR)" >> $@; \
	fi;
	@touch $@
else

$(SD-CARD)/boot/uEnv.txt:
	@echo "=== $(BOARD): generating uEnv.txt ==="
	@mkdir -p $(SD-CARD)/boot
	@echo -n "ethaddr=" > $@
	@if [ "$(ETHADDR)" == "" ]; then \
		echo 00:0a:$$(dd if=/dev/urandom count=1 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\).*$$/\1:\2:\3:\4/') >> $@; \
	else \
		echo "$(ETHADDR)" >> $@; \
	fi;
	@echo "bootargs=console=ttyPS0,115200 earlycon clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait earlyprintk cma=$(CMA_SIZE) uio_pdrv_genirq.of_id=generic-uio" >> $@
	@echo "uenvcmd=echo Copying Linux from SD to RAM... && fatload mmc 0 0x2080000 uImage && fatload mmc 0 0x2000000 devicetree.dtb && bootm 0x2080000 - 0x2000000" >> $@
endif


sd-card:				\
	$(SD-CARD)/boot/BOOT.bin 	\
	$(SD-CARD)/boot/$(LINUX_IMAGE) 	\
	$(SD-CARD)/boot/$(DEVTREE)	\
	$(SD-CARD)/boot/uEnv.txt	\
	$(SD-CARD)/root


clean-sd-card:
	rm -rf $(SD-CARD)

.PHONY: sd-card clean-sd-card


# Vivado
$(VIVADO_BUILD)/$(BOARD).runs/impl_1/system_wrapper.bit:
	@echo "=== $(BOARD): generating bitstream ==="
	@mkdir -p $(VIVADO_BUILD)
	@cd $(VIVADO_BUILD); \
	if test -r $(BOARD).xpr; then \
		echo -n $(SPACES)"WARNING: overwrite existing Vivado project \"$(BOARD)\"? [y|n]"; \
		while true; do \
			read -p " " yn; \
			case $$yn in \
				[Yy] ) \
					$(RM) $(BOARD); \
					vivado -mode batch -quiet -notrace -source $(SCRIPTS)/vivado.tcl -tclargs $(BOARD) | tee $(VIVADO_BUILD)/$(BOARD).log; \
					break;; \
				[Nn] ) \
					echo $(SPACES)"INFO: aborting $@"; \
					break;; \
				* ) echo -n $(SPACES)"WARNING: Please answer yes or no [y|n].";; \
			esac; \
		done; \
	else \
		vivado -mode batch -quiet -notrace -source $(SCRIPTS)/vivado.tcl -tclargs $(BOARD) | tee $(VIVADO_BUILD)/$(BOARD).log; \
	fi; \


$(VIVADO_BUILD)/$(BOARD).runs/impl_1/system_wrapper.sysdef: $(VIVADO_BUILD)/$(BOARD).runs/impl_1/system_wrapper.bit

vivado: $(VIVADO_BUILD)/$(BOARD).runs/impl_1/system_wrapper.sysdef

clean-vivado:
	rm -rf $(VIVADO_BUILD)

.PHONY: vivado clean-vivado


# SKD
$(SDK_BUILD)/system_wrapper.hdf: $(VIVADO_BUILD)/$(BOARD).runs/impl_1/system_wrapper.sysdef
	@mkdir -p $(SDK_BUILD)
	@cp $< $@

$(SDK_BUILD)/dt/system-top.dts:  $(SDK_BUILD)/system_wrapper.hdf
	@echo "=== $(BOARD): generating device tree ==="
	@cd $(SDK_BUILD); \
	hsi -mode batch -quiet -notrace -source $(SCRIPTS)/hsi_dt.tcl -tclargs $(BOARD) $(ZYNQ_ROOT) | tee $(SDK_BUILD)/$(BOARD).log;

$(SDK_BUILD)/dt/system.dtb: $(SDK_BUILD)/dt/system-top.dts
	@echo "=== $(BOARD): compiling device tree ==="
	@dtc -I dts -O dtb -o $@ $<

$(SDK_BUILD)/fsbl/executable.elf: $(SDK_BUILD)/system_wrapper.hdf $(SDK_BUILD)/dt/system-top.dts
	@echo "=== $(BOARD): generating first stage boot loader ==="
	@cd $(SDK_BUILD); \
	hsi -mode batch -quiet -notrace -source $(SCRIPTS)/hsi_fsbl.tcl -tclargs $(BOARD) $(ZYNQ_ROOT) | tee $(SDK_BUILD)/$(BOARD).log;

ifneq ($(findstring zcu, $(BOARD)),)

$(SDK_BUILD)/pmufw/executable.elf:  $(SDK_BUILD)/system_wrapper.hdf $(SDK_BUILD)/dt/system-top.dts
	@echo "=== $(BOARD): generating PMU firmware ==="
	@cd $(SDK_BUILD); \
	hsi -mode batch -quiet -notrace -source $(SCRIPTS)/hsi_pmufw.tcl -tclargs $(BOARD) $(ZYNQ_ROOT) | tee $(SDK_BUILD)/$(BOARD).log;

arm-trusted-firmware/build/zynqmp/release/bl31/bl31.elf:
	@echo "=== $(BOARD): compiling ARM trusted firmware ==="
	@ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) make PLAT=zynqmp RESET_TO_BL31=1 -C arm-trusted-firmware

clean-atf:
	@make PLAT=zynqmp RESET_TO_BL31=1 -C arm-trusted-firmware distclean

.PHONY: clean-atf

sdk: 						\
	$(SDK_BUILD)/dt/system.dtb		\
	$(SDK_BUILD)/fsbl/executable.elf	\
	$(SDK_BUILD)/pmufw/executable.elf	\
	arm-trusted-firmware/bl31.elf

clean-sdk: clean-atf
	rm -rf $(SDK_BUILD)


else

sdk: $(SDK_BUILD)/dt/system.dtb $(SDK_BUILD)/fsbl/executable.elf

clean-sdk:
	rm -rf $(SDK_BUILD)

endif


.PHONY: sdk clean-sdk


# Global targets

# Clean built files for $(BOARD) except for sd-card
clean: 			\
	clean-u-boot	\
	clean-linux	\
	clean-images 	\
	clean-vivado 	\
	clean-sdk

# Clean also sd-card
distclean: clean clean-sd-card

# Remove entire output folder
clean-all:
	rm -rf out


.PHONY: clean distclean clean-all

