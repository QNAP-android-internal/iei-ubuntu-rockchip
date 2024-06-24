#!/bin/bash
echo "fail" > /tmp/video_qc.txt
test_video_path="/qc/test_video.mp4"
while true
do
	gst-launch-1.0 filesrc location=$test_video_path ! qtdemux ! h264parse ! mppvideodec width=480 height=360 ! xvimagesink render-rectangle='<0,0,480,360>'
	echo "pass" > /tmp/video_qc.txt
done
