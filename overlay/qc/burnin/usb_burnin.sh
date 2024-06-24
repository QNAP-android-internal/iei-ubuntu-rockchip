#!/bin/bash

if [ -f /tmp/usb_qc.txt ];then
	rm /tmp/usb_qc.txt
fi

PORT_A="Port 1"
PORT_B="Port 2"
PORT_C="Port 3"
PORT_D="Port 4"
PORT_E="Port 5"

while true
do
	USB_CNT=0

		if [[ "$(lsusb -t | grep "$PORT_A")" ]]; then
			USB_CNT=$(($USB_CNT+1))
		fi


	if [[ "$USB_CNT" == "1" ]]; then
		echo "pass stage 1"
	else
		echo fail > /tmp/usb_qc.txt
		sleep 3
		continue
	fi

	PORTA_STORAGE_CNT=$(lsusb -t | grep "$PORT_A" | grep "usb-storage" | wc -l)
	PORTA_HID_CNT=$(lsusb -t | grep "$PORT_A" | grep "usbhid" | wc -l)
	PORTB_STORAGE_CNT=$(lsusb -t | grep "$PORT_B" | grep "usb-storage" | wc -l)
	PORTB_HID_CNT=$(lsusb -t | grep "$PORT_B" | grep "usbhid" | wc -l)
	PORTC_STORAGE_CNT=$(lsusb -t | grep "$PORT_C" | grep "usb-storage" | wc -l)
	PORTC_HID_CNT=$(lsusb -t | grep "$PORT_C" | grep "usbhid" | wc -l)
	PORTD_STORAGE_CNT=$(lsusb -t | grep "$PORT_D" | grep "usb-storage" | wc -l)
        PORTD_HID_CNT=$(lsusb -t | grep "$PORT_D" | grep "usbhid" | wc -l)
	PORTE_STORAGE_CNT=$(lsusb -t | grep "$PORT_E" | grep "usb-storage" | wc -l)
        PORTE_HID_CNT=$(lsusb -t | grep "$PORT_E" | grep "usbhid" | wc -l)
	
	
	PORT_TOTAL=$(($PORTA_STORAGE_CNT+$PORTA_HID_CNT+$PORTB_STORAGE_CNT+$PORTB_HID_CNT+$PORTC_HID_CNT+$PORTC_STORAGE_CNT+$PORTD_STORAGE_CNT+$PORTD_HID_CNT+$PORTE_STORAGE_CNT+$PORTE_HID_CNT))

	STORAGE_CNT=$(lsusb -t | grep "usb-storage" | wc -l)
	HID_CNT=$(lsusb -t | grep "usbhid" | wc -l)
	TOTAL_CNT=$(($STORAGE_CNT+$HID_CNT))
	echo $PORT_TOTAL
	echo $TOTAL_CNT
	if [[ "$TOTAL_CNT" == "$PORT_TOTAL" ]]; then
		echo pass > /tmp/usb_qc.txt
	else
		echo fail > /tmp/usb_qc.txt
	fi
	sleep 3
done
