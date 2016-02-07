
BOARD ?= zc702
#BOARD ?= zc706

all: sysroot linux u-boot system bootstrap


sysroot:
	BOARD=$(BOARD) $(MAKE) initramfs && BOARD=$(BOARD) $(MAKE) sd_card_$(BOARD)/uramdisk.image.gz

linux:
	@./scripts/build_linux.sh $(BOARD)

u-boot:
	@./scripts/build_uboot.sh $(BOARD)

system:
	@./scripts/build_system.sh $(BOARD)

bootstrap:
	@./scripts/build_bootstrap.sh $(BOARD)

.PHONY: sysroot linux u-boot system bootstrap


initramfs:
	@mkdir -p initramfs

sd_card_$(BOARD)/uramdisk.image.gz: $(shell find initramfs 2>/dev/null)
	@./scripts/build_initramfs.sh $(BOARD)


clean:

distclean: clean
	rm -rf initramfs sd_card_* vivado
	@make -C linux-xlnx mrproper distclean
	@make -C u-boot-xlnx mrproper distclean

.PHONY: clean distclean
