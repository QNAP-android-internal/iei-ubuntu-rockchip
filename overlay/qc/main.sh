#!/bin/bash
export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/

config="B675_qc_config.json"

config_path="/qc/configs/$config"

if [ -f /tmp/testitem.txt ];then
	rm /tmp/testitem.txt
fi
if [ -f /tmp/burnin_testitem.txt ];then
	rm /tmp/burnin_testitem.txt
fi
if [ -f /tmp/dialog_display.txt ];then
	rm /tmp/dialog_display.txt
fi

i=0
while true
do
	name=`eval jq '.[$i].names' $config_path |sed s/\"//g`
	burnin=`eval jq '.[$i].burnin' $config_path |sed s/\"//g`
	if [ $name == "END" ];then
		break
	elif [ $name == "NOR" ];then
		if [ $burnin == "true" ];then
			echo "$name \"\" off " >>/tmp/burnin_testitem.txt
		fi
		echo "$name \"\" off " >>/tmp/testitem.txt
	else
		if [ $burnin == "true" ];then
			echo "$name \"\" on " >>/tmp/burnin_testitem.txt
		fi
		echo "$name \"\" on " >>/tmp/testitem.txt
	fi
	i=$(($i+1))
done

while true 
do
	if [ -f /tmp/testmenu.txt ];then
		rm /tmp/testmenu.txt
	fi
	if [ -f /tmp/result.txt ];then
		rm /tmp/result.txt
	fi
	#dialog menu for burnin or regular test
	dialog --cancel-label "Exit" --menu "Choose test mode" 10 50 2 \
	1 "test" 2 "burnin" 2>/tmp/testmenu.txt
	menuflag=$?
	if [ $menuflag == 1 ];then
		exit
	fi
	testmenu=`cat /tmp/testmenu.txt`
	if [ $testmenu == 2 ];then
		dialog --inputbox "input test time(hours)" 10 50 \
		2>/tmp/burnin_time.txt
		if [ $? == 1 ];then
			continue
		fi
		burnin_time=`cat /tmp/burnin_time.txt`
		if ! [[ $burnin_time =~ ^[1-9][0-9]*$ ]];then
			continue
		fi
		testitem=`cat /tmp/burnin_testitem.txt`
		checklist_title="Burnin Test items"
		testmode=burnin
	elif [ $testmenu == 1 ];then
		testitem=`cat /tmp/testitem.txt`
		checklist_title="Test items"
		testmode=normal
	fi

	#dialog checklist for test items	
	dialog_cmd="dialog --colors --separate-output --title \"$checklist_title\" --checklist \"Choose test items\" 80 60 2 $testitem  2>/tmp/chosen_items.txt"
	echo $dialog_cmd |sh
	if [ $? == 1 ];then	
		continue
	else
		break
	fi
done

dialog --infobox "Loading... Please wait" 10 30

i=0
while true
do
	name=`eval jq '.[$i].names' $config_path |sed s/\"//g`
	if [ $name == "END" ];then
		break
	else
		matched=false
		while read line
		do
			if [ $line == $name ];then
				matched=true
				break
			fi
		done < /tmp/chosen_items.txt
		if $matched;then
			jq_cmd="jq '.[$i].teston = \"true\"' $config_path >/tmp/tmp.json"
		else
			jq_cmd="jq '.[$i].teston = \"false\"' $config_path >/tmp/tmp.json"
		fi
		echo $jq_cmd |sh
		sudo cp /tmp/tmp.json $config_path
	fi
	i=$(($i+1))
done

#collect and integrate status files defined in config file
i=0
while true
do	
	#auto test items
	name=`eval jq '.[$i].names' $config_path |sed s/\"//g`
	exec=`eval jq '.[$i].exec' $config_path |sed s/\"//g |sed s/\'/\"/g`
	checkauto=`eval jq '.[$i].auto' $config_path |sed s/\"//g`
	teston=`eval jq '.[$i].teston' $config_path |sed s/\"//g`
	burnin_exec=`eval jq '.[$i].burnin_exec' $config_path |sed s/\"//g |sed s/\'/\"/g`

	if [ $name == "END" ];then
		break
	else
		if [ $testmode == normal ] && $teston && $checkauto ;then
			echo ${exec} >> /tmp/exec.txt
			echo $exec |sh > /dev/null 2>&1 &
			echo $name: >>/tmp/result.txt
		elif [ $testmode == burnin ] && $teston ;then
			echo ${burnin_exec} >> /tmp/exec.txt
			echo $burnin_exec |sh > /dev/null 2>&1 &
			echo $name: >>/tmp/result.txt
		fi
	fi
	
	i=$(($i+1))		
done

i=0
while true
do
	#non-auto test items
	name=`eval jq '.[$i].names' $config_path |sed s/\"//g`
	exec=`eval jq '.[$i].exec' $config_path |sed s/\"//g |sed s/\'/\"/g`
	checkauto=`eval jq '.[$i].auto' $config_path |sed s/\"//g`
	teston=`eval jq '.[$i].teston' $config_path |sed s/\"//g`

	if [ $name == "END" ];then
		break
	else
		if [ $testmode == normal ] && $teston && ! $checkauto ;then
			echo $exec |sh
			echo $name: >>/tmp/result.txt
		fi
	fi
	i=$(($i+1))
done

dialog --infobox "Loading... Please wait" 10 30

org_time=`date "+%Y-%m-%d_%H:%M:%S"`
org_time_sec=`date +%s`
i=0
while true
do
	name=`eval jq '.[$i].names' $config_path |sed s/\"//g`
	statusFile=`eval jq '.[$i].statusFile' $config_path |sed s/\"//g`	
	teston=`eval jq '.[$i].teston' $config_path |sed s/\"//g`
	
	if [ $name == "END" ];then
		#dialog output
		dialog_display=`cat /tmp/dialog_display.txt`
		rm /tmp/dialog_display.txt
		station="IEI_Test"
		echo $dialog_display >/tmp/display_debug.txt
		dialog_cmd="dialog --colors --title \"$station\" --msgbox \"$dialog_display\" 50 50 &"
		echo $dialog_cmd >/tmp/dialog_debug.txt
		echo $dialog_cmd |sh
		
		sleep 5
		msgbox_pid=`ps -F |grep msgbox |grep -v grep |awk '{print $2}'`
		if [ $testmode == burnin ];then
			now_time=`date +%s`
			time_long=$(($now_time-$org_time_sec))
			time_long_min=$(($time_long/60))
			burnin_time=`cat /tmp/burnin_time.txt`	#hours
			burnin_time_min=$(($burnin_time*60))
			burnin_time=$(($burnin_time*3600))	#seconds
			echo -n "\ntime: $time_long_min / $burnin_time_min (minutes)\n\n" >>/tmp/dialog_display.txt
			echo -n "\n" >>/tmp/dialog_display.txt
			if [ $time_long -gt $burnin_time ];then
				kill -9 $msgbox_pid
				/qc/log_qc.sh
				dialog --infobox "time's up" 5 30
				sleep 3
				break
			fi
		fi
		
		if [[ -n "$msgbox_pid" ]];then
			kill -9 $msgbox_pid
			i=0
			continue
		else
			kill -9 $msgbox_pid
			dialog --title "stop test" --yesno "Sure you want to stop test?" 10 30
			if [ $? == 0 ];then
				/qc/log_qc.sh
				dialog --infobox "complete" 5 30
				break
			else
				i=0
				continue
			fi
		fi
	fi
	if $teston;then
		status=`cat $statusFile`
		eval sed -i 's/^$name:.*/$name:$status/g' /tmp/result.txt
		if [ $status == "pass" ];then
			echo -n "\Z0\ZB$name:\Z2PASS\n" >>/tmp/dialog_display.txt
		else
			echo -n "\Z0\ZB$name:\Z1Failed\n" >>/tmp/dialog_display.txt
		fi
	fi
	i=$(($i+1))	
done

ps -F |grep burnin |grep -v grep |awk '{print $2}' >/tmp/burnin_pid.txt
while read line 
do
	kill -9 $line
done </tmp/burnin_pid.txt
ps -F |grep _qc |grep -v grep |awk '{print $2}' >/tmp/qc_pid.txt
while read line
do
	 kill -9 $line
done </tmp/qc_pid.txt
ps -F |grep "cat /dev/tty" |grep -v grep |awk  '{print $2}' >/tmp/uartcat_pid.txt
while read line
do
	 kill -9 $line
done </tmp/uartcat_pid.txt
if [ $testmode == burnin ];then
	ps -F |grep gst-launch |grep -v grep |awk '{print $2}' >/tmp/gst-launch_pid.txt
	while read line
	do
		kill -9 $line
	done </tmp/gst-launch_pid.txt
	glmark2_pid=`ps -F |grep glmark2-es2-way |grep -v grep |awk '{print $2}'`
	kill -9 $glmark2_pid
fi

dialog_cmd="dialog --colors --title \"Result\" --msgbox \"$dialog_display\" 50 50"
echo $dialog_cmd |sh
