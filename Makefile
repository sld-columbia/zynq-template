
BOARD ?= zc702
#BOARD ?= zc706

clean:

distclean: clean
	rm -rf initramfs sd_card_* vivado

sysroot:
	BOARD=$(BOARD) $(MAKE) initramfs && BOARD=$(BOARD) $(MAKE) sd_card_$(BOARD)/uramdisk.image.gz


.PHONY: clean distclean sysroot


initramfs:
	@mkdir -p initramfs

sd_card_$(BOARD)/uramdisk.image.gz: $(shell find initramfs 2>/dev/null)
	@./scripts/build_initramfs.sh $(BOARD)

