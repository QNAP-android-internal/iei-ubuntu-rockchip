#!/bin/bash

eth=$1
SOC=`cat /proc/device-tree/model | cut -d ' ' -f3`

if [ $# != 1 ];then
	echo "ex:eth_qc.sh eth0"
	return 1
fi

if [ -f /tmp/eth_qc_$eth.txt ];then
        rm /tmp/eth_qc_$eth.txt
fi

echo fail > /tmp/eth_qc_$eth.txt

ifconfig -a |awk  '{print $1}' |grep $eth
if [ $? != 0 ];then
	echo "not found $eth"
	return 1
fi

echo "eth=$eth"

while true 
do
	ping -I $eth -c 5 10.12.56.2
	if [ $? == 0 ];then
		echo pass > /tmp/eth_qc_$eth.txt
		sleep 3
	else
		echo fail > /tmp/eth_qc_$eth.txt
	fi
done
