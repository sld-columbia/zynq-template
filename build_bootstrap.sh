#!/bin/bash

source ./build_common.sh

export BOARD=$board

mkdir -p vivado
cd vivado

#Generate system and create bitstream. Add customizations to vivado.tcl
echo "=== Generating IPs and bitstream for ZYNQ $board ==="

vivado -mode batch -source ../vivado_tcl/vivado.tcl | tee vivado_$board.log
cp $board/$board.sdk/system_wrapper.bit ../$SD_CARD

# Generate the device tree and the bootloader based on the system configuration
echo "=== Building device tree and boot loader for ZYNQ $board ==="

hsi -mode batch -source ../vivado_tcl/hsi.tcl | tee hsi_$board.log
dtc -I dts -O dtb -o $board\_dtb/system.dtb $board\_dtb/system.dts
cp $board\_dtb/system.dtb ../$SD_CARD/devicetree.dtb
cp $board\_fsbl/executable.elf ../$SD_CARD/fsbl.elf

cd ..

cd $SD_CARD

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

cd ..
