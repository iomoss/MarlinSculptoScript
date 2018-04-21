#!/bin/bash

# Needed for python and pip
sudo apt-get install python python-pip
sudo pip install virtualenv

# Needed for srec_cat
sudo apt-get install srecord

# Set Motherboard
sed "s/#define MOTHERBOARD BOARD_RAMPS_14_EFB/#define MOTHERBOARD BOARD_RAMPS_14_RE_ARM_EFB/g" -i Marlin/Marlin/Configuration.h
# Set chip
sed "s/env_default = megaatmega2560/env_default = LPC1768/g" -i Marlin/platformio.ini

virtualenv venv
source venv/bin/activate
pip install -r requirements.txt

cd Marlin
platformio run -v
cd ..

# Add the compiler to PATH

# Build LPC bootloader
cd LPC17xx-DFU-Bootloader/
PATH=~/.platformio/packages/toolchain-gccarmnoneeabi/bin/:$PATH make
cd ..


BOOTLOADER_HEX="LPC17xx-DFU-Bootloader/build/DFU-Bootloader.hex"
FIRMWARE_ELF="Marlin/.pioenvs/LPC1768/firmware.elf"
FIRMWARE_HEX="Marlin/.pioenvs/LPC1768/firmware.hex"
COMBINED_HEX="main-combined.hex"
UPLOAD_TTY=/dev/ttyUSB0

~/.platformio/packages/toolchain-gccarmnoneeabi/bin/arm-none-eabi-objcopy -R .stack -O ihex $FIRMWARE_ELF $FIRMWARE_HEX

srec_cat $BOOTLOADER_HEX -Intel $FIRMWARE_HEX -Intel -out $COMBINED_HEX -Intel

until lpc21isp $COMBINED_HEX $UPLOAD_TTY 115200 12000
do
    echo "Retrying in 5..."
    sleep 5
done
