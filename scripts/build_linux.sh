#!/bin/bash

source ./build_common.sh

echo "=== Building Linux kernel for ZYNQ $board ==="

if [ ! -f linux-xlnx/.config ]; then
   cp -i config/linux-zynq-config linux-xlnx/.config
fi

ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C linux-xlnx UIMAGE_LOADADDR=0x8000 uImage -j
cp linux-xlnx/arch/arm/boot/uImage $SD_CARD
