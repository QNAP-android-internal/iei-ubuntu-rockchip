#!/bin/bash

if [ -f /tmp/otg_qc.txt ];then
        rm /tmp/otg_qc.txt
fi

IRQ_name="dwc3"

while true
do
	cat /proc/interrupts | grep "$IRQ_name"
	if [ $? != 0 ];then
		IRQ_times_before=0
	else
		IRQ_times_before=`cat /proc/interrupts | grep "$IRQ_name" | awk '{print $2}'`
	fi
	sleep 1

	IRQ_times_after=`cat /proc/interrupts | grep "$IRQ_name" | awk '{print $2}'`

	echo "IRQ_times_before=$IRQ_times_before"
	echo "IRQ_times_after=$IRQ_times_after"
 
	times=`expr $IRQ_times_after - $IRQ_times_before`
	echo "times=$times"

	if [ $times -gt 0 ];then
		echo pass >/tmp/otg_qc.txt
		exit
	else
		echo fail >/tmp/otg_qc.txt
	fi
	cat /tmp/otg_qc.txt
done
