#!/bin/bash


if [ $(ls $1) ]; then
    echo "ov5640 driver existed, starting test"
else
    echo "fail" > /tmp/camera_qc.txt
fi

gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,format=NV12,width=640,height=480, framerate=5/1  ! xvimagesink &
sleep 5

gst_pid=`ps -F |grep gst-launch |grep -v grep |awk '{print $2}'`
kill -9 $gst_pid

sh -c 'dialog --colors --title "Camera Test" \
--no-collapse --yesno "See the image??" 10 50'

CAMERA_RESULTS="$?"
if [[ "$CAMERA_RESULTS" == '1' ]]; then
    echo "fail" > /tmp/camera_qc.txt
elif [[ "$CAMERA_RESULTS" == '0' ]]; then
    echo "pass" > /tmp/camera_qc.txt
fi
