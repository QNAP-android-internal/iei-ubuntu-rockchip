#!/bin/bash

if [ -f /tmp/m2_wifi_qc.txt ];then
        rm /tmp/m2_wifi_qc.txt
fi

echo fail >/tmp/m2_wifi_qc.txt

usb=$(lsusb | grep 04ca:3019)
pci=$(lspci -n | grep 168c:003e)

if ! [ -z "$usb" ] && ! [ -z "$pci" ];then
	echo "pass" > /tmp/m2_wifi_qc.txt
fi

