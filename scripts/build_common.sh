#!/bin/bash

if [ "$1" = "zc702" ] || [ "$1" = "zc706" ]; then
    board=$1
else
    echo "Usage: $0 [zc702|zc706]"
    exit
fi
SD_CARD=sd_card_$board
mkdir -p $SD_CARD
