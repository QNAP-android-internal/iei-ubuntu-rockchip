#!/bin/bash
if [ -f /tmp/mem_qc.txt ];then
	rm /tmp/mem_qc.txt
fi

if [ -f /tmp/mem_tmp.txt ];then
        rm /tmp/mem_tmp.txt
fi

echo fail >/tmp/mem_qc.txt

if [ $1 -gt 3000 ];then
	exit 1
fi

memtester $1 >/tmp/mem_tmp.txt &

checkps=false
checkok=false
while true
do
	ps |grep memtester |grep -v "grep"
	if [ $? == 0 ];then
                checkps=true
        else
                checkps=false
        fi

	cat /tmp/mem_tmp.txt |grep ok
	if [ $? == 0 ];then
		checkok=true
	else
		checkok=false
	fi	

	if $checkps && $checkok;then	
		echo pass >/tmp/mem_qc.txt		
		break
	fi
done
rm /tmp/mem_tmp.txt

