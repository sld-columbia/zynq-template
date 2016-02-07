
BOARD ?= zc702
#BOARD ?= zc706

clean:

distclean: clean
	rm -rf initramfs sd_card_* vivado

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

.PHONY: clean distclean sysroot linux u-boot system bootstrap


initramfs:
	@mkdir -p initramfs

sd_card_$(BOARD)/uramdisk.image.gz: $(shell find initramfs 2>/dev/null)
	@./scripts/build_initramfs.sh $(BOARD)

