#!/bin/bash

if [ $(ls $1) ]; then
	echo "pass" > /tmp/camera_qc.txt
else
	echo "fail" > /tmp/camera_qc.txt
fi

gst-launch-1.0 -e v4l2src device=/dev/video0 ! autovideosink sync=false
