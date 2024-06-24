#!/bin/bash
test_video_path="/qc/test_video.mp4"
gst-launch-1.0 filesrc location=$test_video_path ! qtdemux ! h264parse ! mppvideodec width=480 height=360 ! xvimagesink render-rectangle='<0,0,480,360>'

sh -c 'dialog --colors --title "Video Test" \
--no-collapse --yesno "See the vdieo??" 10 50'

video_result=$?

if [[ "$video_result" == '1' ]]; then
    echo "fail" > /tmp/video_qc.txt
elif [[ "$video_result" == '0' ]]; then
    echo "pass" > /tmp/video_qc.txt
fi
