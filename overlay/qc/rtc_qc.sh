#!/bin/bash
if [ -f /tmp/rtc_qc.txt ];then
        rm /tmp/rtc_qc.txt
fi

echo fail > /tmp/rtc_qc.txt

while true
do
        rtc_time_before=`cat /sys/class/rtc/rtc0/time`
        echo $rtc_time_before   
        if [ $? == 0 ];then
                sleep 5
                rtc_time_after=`cat /sys/class/rtc/rtc0/time`
                echo $rtc_time_after
        else
                echo fail >/tmp/rtc_qc.txt
        fi

        if [[ $rtc_time_before != $rtc_time_after ]];then
                echo pass >/tmp/rtc_qc.txt
                exit
        else
                echo fail >/tmp/rtc_qc.txt
        fi
        cat /tmp/rtc_qc.txt
done

