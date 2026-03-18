#!/bin/bash

bt_firmware_path=/lib/firmware/BCM4362A2.hcd
bt_baudrate=3000000

brcm_patchram_plus --enable_hci --no2bytes --use_baudrate_for_download --tosleep 200000 --baudrate $bt_baudrate --patchram $bt_firmware_path /dev/ttyS9 &

