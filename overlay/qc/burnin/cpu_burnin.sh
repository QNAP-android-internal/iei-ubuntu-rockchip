#!/bin/bash
if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
fi

while true
do
	if [ "$OS" = "Ubuntu" ]; then
		if sudo stress-ng --cpu 2 --timeout 5s 2>&1 | grep -q "successful" ;then
			echo "pass" > /tmp/cpu_qc.txt
		else
			echo "fail" > /tmp/cpu_qc.txt
	fi
else
		if [[ "$(stress-ng --cpu 2 --timeout 5s 2>&1  | grep "successful")" ]];then
			echo "pass" > /tmp/cpu_qc.txt
		else
			echo "fail" > /tmp/cpu_qc.txt
		fi
	fi
done
