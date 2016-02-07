#!/bin/bash

CURR_DIR=${PWD}

source $CURR_DIR/scripts/build_common.sh

echo "=== Building u-boot for ZYNQ $board ==="

ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C $CURR_DIR/u-boot-xlnx zynq_$board\_config
ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C $CURR_DIR/u-boot-xlnx -j
cp $CURR_DIR/u-boot-xlnx/u-boot $CURR_DIR/$SD_CARD/u-boot.elf
