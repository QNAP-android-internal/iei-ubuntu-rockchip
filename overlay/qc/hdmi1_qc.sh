#!/bin/bash

if [ -f /tmp/hdmi1_qc.txt ];then
	rm /tmp/hdmi1_qc.txt
fi
if [ -f /tmp/edid1_tmp ];then
        rm /tmp/edid1_tmp
fi

res_org=`fbset |grep geometry |cut -d ' ' -f 5 --complement`
echo "$res_org" >/tmp/res.txt

hexdump /sys/devices/platform/display-subsystem/drm/card0/card0-HDMI-A-1/edid >/tmp/edid1_tmp
edid_size=`du /tmp/edid1_tmp | awk '{print $1}'`
if [ $edid_size == 0 ];then
	echo fail >/tmp/hdmi1_qc.txt
	cat /tmp/hdmi1_qc.txt
	return 1
else
	echo pass >/tmp/hdmi1_qc.txt
fi

#fbset -fb /dev/fb0 -g 1920 1080 1920 1080 16

#fbset -fb /dev/fb0 -g $res_org

#kill -9 $$
