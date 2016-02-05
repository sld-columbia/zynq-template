#!/bin/bash

mkdir -p sd_card

board=zc702

while true; do
    echo "Available target boards:"
    echo "  1: ZYNQ ZC702"
    echo "  2: ZYNQ ZC706"
    read -p 'Select target board (1-2): ' sel

    case $sel in

	1) board=zc702; break;;

	2) board=zc706;  break;;

	*) echo "Invalid selection"; echo "";;

    esac
done

echo "Building u-boot for ZYNQ $board"

ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C u-boot-xlnx zynq_$board\_config
ARCH=arm CROSS_COMPILE=arm-xilinx-linux-gnueabi- make -C u-boot-xlnx -j
cp u-boot-xlnx/u-boot sd_card/u-boot.elf
