#!/bin/bash

if [ -f /tmp/bt_qc.txt ];then
        rm /tmp/bt_qc.txt
fi

if [ -f /tmp/btctl_scan.txt ];then
        rm /tmp/btctl_scan.txt
fi

echo fail >/tmp/bt_qc.txt

fail_count=0
while true
do
	bluetoothctl scan on >/tmp/btctl_scan.txt &
	btctl_scan_pid=`ps -F |grep "bluetoothctl scan on" |grep -v "grep" |awk '{print $2}'`
	sleep 5
	kill $btctl_scan_pid
	sleep 5
	cat /tmp/btctl_scan.txt |grep "NEW" |awk '{print $3}'>/tmp/bt_mac.txt
	bt_mac=`shuf -n1 /tmp/bt_mac.txt`
	if [[ -z "$bt_mac" ]];then
		sleep 5
		continue
	fi

	bluetoothctl info $bt_mac >/tmp/bt_info.txt
	cat /tmp/bt_info.txt |grep "Device $mac" |grep -v "not available"
	if [ $? == 0 ];then
		fail_count=0
		echo pass >/tmp/bt_qc.txt
	else
		fail_count=$(($fail_count+1))
	fi
	if [ $fail_count -ge 3 ];then
		echo fail >/tmp/bt_qc.txt
	fi
	sleep 10
done
