#!/bin/bash

CURR_DIR=${PWD}

source $CURR_DIR/scripts/build_common.sh

echo "=== Building root file system for ZYNQ $board ==="

mkdir -p initramfs
cd initramfs

# If sysroot template does not exist download the default one.
if [ ! -d mnt ]; then
    wget http://espdev.cs.columbia.edu/zynq/zynq_sysroot.tar
    tar xf zynq_sysroot.tar
    rm zynq_sysroot.tar
fi

# Create a cpio initramfs with gzip compression and pack it for Zynq
sh -c 'cd mnt/ && find . | cpio -H newc -o' | gzip -9 > $CURR_DIR/$SD_CARD/initramfs.cpio.gz
mkimage -A arm -T ramdisk -C gzip -d $CURR_DIR/$SD_CARD/initramfs.cpio.gz $CURR_DIR/$SD_CARD/uramdisk.image.gz
rm $CURR_DIR/$SD_CARD/initramfs.cpio.gz

cd ..
