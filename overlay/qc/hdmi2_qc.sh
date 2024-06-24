#!/bin/bash

if [ -f /tmp/hdmi2_qc.txt ];then
	rm /tmp/hdmi2_qc.txt
fi
if [ -f /tmp/edid2_tmp ];then
        rm /tmp/edid2_tmp
fi

res_org=`fbset |grep geometry |cut -d ' ' -f 5 --complement`
echo "$res_org" >/tmp/res.txt

hexdump /sys/devices/platform/display-subsystem/drm/card0/card0-HDMI-A-2/edid >/tmp/edid2_tmp
edid_size=`du /tmp/edid2_tmp | awk '{print $1}'`
if [ $edid_size == 0 ];then
	echo fail >/tmp/hdmi2_qc.txt
	cat /tmp/hdmi2_qc.txt
	return 1
else
	echo pass >/tmp/hdmi2_qc.txt
fi

#fbset -fb /dev/fb0 -g 1920 1080 1920 1080 16

#fbset -fb /dev/fb0 -g $res_org

#kill -9 $$
