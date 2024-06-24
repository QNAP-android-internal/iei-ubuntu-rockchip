#!/bin/bash

if [ -f /tmp/wifi_qc.txt ];then
	rm /tmp/wifi_qc.txt
fi

if [ -f /tmp/wifiscan_tmp.txt ];then
        rm /tmp/wifiscan_tmp.txt
fi

if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
fi

if [ ${OS} = "Ubuntu" ] ;then
        while true
	do
		sudo ifconfig wlan0 down
		sudo ifconfig wlan0 up

		sleep 3

		sudo nmcli device wifi list > /tmp/wifiscan_tmp.txt
		sync

		cat /tmp/wifiscan_tmp.txt
		if [ ! -s "/tmp/wifiscan_tmp.txt" ];then
			echo fail > /tmp/wifi_qc.txt
                else
                        echo pass > /tmp/wifi_qc.txt
                fi
                sleep 10
	done

else

	for i in $(seq 1 10);
	do
		if [ -f /tmp/modem_qc.txt ];then
			break
		else
			if [ $i == 10 ];then
				systemctl stop NetworkManager
				sleep 2
			fi
		fi
		sleep 1
	done

	while true
	do
		connmanctl disable wifi
		connmanctl enable wifi
		sleep 3

		connmanctl scan wifi
		sleep 5
		connmanctl services > /tmp/wifiscan_tmp.txt
		sync

		cat /tmp/wifiscan_tmp.txt |grep "wifi_"
		if [ $? == 1 ];then
			echo fail > /tmp/wifi_qc.txt
		else
			echo pass > /tmp/wifi_qc.txt
		fi
		sleep 10
	done
fi
