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

if [ $SOC == B643 ];then
	case $eth in
	eth0)
		first=true
		;;
	eth1)
		first=false
		;;
	esac
	if $first;then
		ifconfig eth1 down
	else
		while true
		do
			if [ -f /tmp/eth_qc_eth0.txt ];then
				status=`cat /tmp/eth_qc_eth0.txt`
				if [ $status == pass ];then
					ifconfig eth0 down
					break
				fi			
			fi
			sleep 3
		done
	fi
fi

while true 
do
	ping -I $eth -c 5 10.12.56.2
	if [ $? == 0 ];then
		echo pass > /tmp/eth_qc_$eth.txt
		break
	fi
done

if [ $SOC == B643 ];then
	ifconfig eth0 up
	ifconfig eth1 up
fi
