#!/bin/bash

check_life_time()
{
	eval TYPE="$"EST_TYP_$1""
	echo $TYPE
	if [ $TYPE == "0x00" ] ; then
		echo "EXT_CSD_DEVICE_LIFE_TIME_EST_TYP_$1: 0x00    NOT SUPPORT!"
		if [ $1 == "B" ];then
			checkB=true
		fi
	elif [ $TYPE == "0x0B" ] ; then
		echo "Exceeded its maximum estimated device life time !"
	else
		case $TYPE in
			0x01)
				USED_pct="0% - 10%"
				eval check$1=true
				;;
			0x02)
				USED_pct="10% - 20%"
				;;
			0x03)
				USED_pct="20% - 30%"
	                        ;;
	                0x04)
				USED_pct="30% - 40%"
	                        ;;
			0x05)
				USED_pct="40% - 50%"
	                        ;;
	                0x06)
				USED_pct="50% - 60%"
	                        ;;
			0x07)
				USED_pct="60% - 70%"
	                        ;;
	                0x08)
				USED_pct="70% - 80%"
	                        ;;
			0x09)
				USED_pct="80% - 90%"
	                        ;;
	                0x0A)
				USED_pct="90% - 100%"
	                        ;;
		esac
		echo "$USED_pct device life time used !"
	fi
}

check_EOL_INFO()
{
	echo $EOL_INFO
	case $EOL_INFO in
		0x00)
			EOL_STATUS=Not Defined
			;;
		0x01)
			EOL_STATUS=Normal
			;;
		0x02)
			EOL_STATUS=Warning
			;;
		0x03)
			EOL_STATUS=Urgent
			;;	
	esac
	echo $EOL_STATUS
	if [ $EOL_STATUS == "Normal" ];then
		checkEOL=true
	fi
}

EMMC_NUM="1"
if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
fi

if [ ${OS} = "Ubuntu" ] ;then
	EST_TYP_A=`sudo mmc extcsd read /dev/mmcblk$EMMC_NUM | grep "EXT_CSD_DEVICE_LIFE_TIME_EST_TYP_A" | cut -d ':' -f2 | sed s/[[:space:]]//g`
	EST_TYP_B=`sudo mmc extcsd read /dev/mmcblk$EMMC_NUM | grep "EXT_CSD_DEVICE_LIFE_TIME_EST_TYP_B" | cut -d ':' -f2 | sed s/[[:space:]]//g`
	EOL_INFO=`sudo mmc extcsd read /dev/mmcblk$EMMC_NUM | grep "EXT_CSD_PRE_EOL_INFO" | cut -d ':' -f2 | sed s/[[:space:]]//g`
else
	EST_TYP_A=`mmc extcsd read /dev/mmcblk$EMMC_NUM | grep "EXT_CSD_DEVICE_LIFE_TIME_EST_TYP_A" | cut -d ':' -f2 | sed s/[[:space:]]//g`
	EST_TYP_B=`mmc extcsd read /dev/mmcblk$EMMC_NUM | grep "EXT_CSD_DEVICE_LIFE_TIME_EST_TYP_B" | cut -d ':' -f2 | sed s/[[:space:]]//g`
	EOL_INFO=`mmc extcsd read /dev/mmcblk$EMMC_NUM | grep "EXT_CSD_PRE_EOL_INFO" | cut -d ':' -f2 | sed s/[[:space:]]//g`
fi

EOL_STATUS="null"

checkA=false
checkB=false
checkEOL=false

if [ -f /tmp/emmc_qc.txt ];then
	rm /tmp/emmc_qc.txt
fi

echo "check eMMC Life Time Estimation A"
check_life_time A
echo "##########################################"

echo "check eMMC Life Time Estimation B"
check_life_time B
echo "##########################################"

echo "check eMMC Pre EOL information"
check_EOL_INFO
echo "##########################################"

#echo "$checkA ; $checkB ; $checkEOL ;"

if $checkA && $checkB && $checkEOL;then
	echo pass >/tmp/emmc_qc.txt
else
	echo fail >/tmp/emmc_qc.txt
fi
