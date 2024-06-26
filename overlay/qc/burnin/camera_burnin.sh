#!/bin/bash

if [ $(ls $1) ]; then
	echo "pass" > /tmp/camera_qc.txt
else
	echo "fail" > /tmp/camera_qc.txt
fi

gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,format=NV16,width=480,height=360 ! glimagesink sync=false
