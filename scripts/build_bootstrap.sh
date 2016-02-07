#!/bin/bash

CURR_DIR=${PWD}

source $CURR_DIR/scripts/build_common.sh

export BOARD=$board

if [ ! -f $CURR_DIR/vivado/$board/$board.sdk/system_wrapper.hdf ]; then
    echo "Error: desing not found or not exported to SDK. Run "make system" first!"
    exit
fi

cd $CURR_DIR/vivado

# Generate the device tree and the bootloader based on the system configuration
echo "=== Building device tree and boot loader for ZYNQ $board ==="

hsi -mode batch -source $CURR_DIR/scripts/vivado_tcl/hsi.tcl | tee hsi_$board.log
dtc -I dts -O dtb -o $board\_dtb/system.dtb $board\_dtb/system.dts
cp $board\_dtb/system.dtb $CURR_DIR/$SD_CARD/devicetree.dtb
cp $board\_fsbl/executable.elf $CURR_DIR/$SD_CARD/fsbl.elf
cp $board/$board.sdk/system_wrapper.bit $CURR_DIR/$SD_CARD

cd $CURR_DIR

cd $CURR_DIR/$SD_CARD

echo "=== Generate bootstrap for ZYNQ $board ==="

# Write boot partition table
echo "the_ROM_image:" > boot.bif
echo "{" >> boot.bif
echo "	[bootloader]fsbl.elf" >> boot.bif
echo "	u-boot.elf" >> boot.bif
echo "	system_wrapper.bit" >> boot.bif
echo "}" >> boot.bif

# Generate bootstrap
bootgen -image boot.bif -o BOOT.bin

cd $CURR_DIR
