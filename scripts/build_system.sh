#!/bin/bash

CURR_DIR=${PWD}

source $CURR_DIR/scripts/build_common.sh

export BOARD=$board

mkdir -p vivado
cd $CURR_DIR/vivado

#Generate system and create bitstream. Add customizations to vivado.tcl
echo "=== Generating IPs and bitstream for ZYNQ $board ==="

vivado -mode batch -source $CURR_DIR/scripts/vivado_tcl/vivado.tcl | tee vivado_$board.log

cd $CURR_DIR
