#!/bin/bash

source ./build_common.sh

echo "=== Building u-boot for ZYNQ $board ==="

ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C u-boot-xlnx zynq_$board\_config
ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C u-boot-xlnx -j
cp u-boot-xlnx/u-boot $SD_CARD/u-boot.elf
