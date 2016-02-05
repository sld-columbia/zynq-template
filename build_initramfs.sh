#!/bin/bash

mkdir -p initramfs
cd initramfs

# If sysroot template does not exist download the default one.
if [ ! -d mnt ]; then
    wget http://espdev.cs.columbia.edu/zynq/zynq_sysroot.tar
    tar xf zynq_sysroot.tar
    rm zynq_sysroot.tar
fi

# Create a cpio initramfs with gzip compression and pack it for Zynq
sh -c 'cd mnt/ && find . | cpio -H newc -o' | gzip -9 > initramfs.cpio.gz
mkimage -A arm -T ramdisk -C gzip -d initramfs.cpio.gz uramdisk.image.gz
cp uramdisk.image.gz ../sd_card

cd ..
