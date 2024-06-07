#!/bin/bash
name=$(env | grep USER | cut -d '=' -f2-);
path=/home/$name/.config/monitors.xml
if ! [ -f $path ];then
	sleep 0.1 && xrandr --output DSI-2 --off --output HDMI-2 --left-of DSI-1 --output HDMI-1 --left-of HDMI-2 --output DSI-1 --rotate right
fi
