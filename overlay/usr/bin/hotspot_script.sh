#/bin/bash

#OK=0
BACKTITLE="Hotspot Information"

Main() {
    while :; do
        Selection=$(dialog --title "HotSpot" --clear \
            --backtitle "$BACKTITLE" \
            --cancel-label "Exit" \
            --menu "Choose one" 12 45 5 \
            1 "Turn on new hotspot" \
            2 "Turn off hotspot" \
            2>&1 >/dev/tty)

        result=$?
        if [ $result -eq "0" ]; then
            Select $Selection
        else
            Exit
        fi
    done
}

Select() {
    choice=$1
    echo "choice "$choice >>log.txt
    case $choice in
    1)
        TurnOnHotspot
        ;;
    2)
        HotspotInformation "" "" "1"
        ;;
    esac
}

TurnOnHotspotByNmcli() {
    networkName=$1
    password=$2

    cmd="nmcli con add type wifi ifname wlan0 con-name "
    cmd="${cmd}"$networkName
    cmd="${cmd} autoconnect yes ssid "
    cmd="${cmd}"$networkName
    cmd="${cmd} ;"
    cmd="${cmd} nmcli con modify "
    cmd="${cmd}"$networkName
    cmd="${cmd} 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared;"
    cmd="${cmd} nmcli con modify "
    cmd="${cmd}"$networkName 
    cmd="${cmd} wifi-sec.key-mgmt wpa-psk;"
    cmd="${cmd} nmcli con modify "
    cmd="${cmd}"$networkName
    cmd="${cmd} wifi-sec.psk "
    cmd="${cmd}"$password
    cmd="${cmd} ;"
    cmd="${cmd} nmcli con up "
    cmd="${cmd}"$networkName

    echo $cmd >> log.txt
    sudo sh -c "$cmd"
}


TurnOffHotspotByNmcli() {
    wlan0ConnectedInfo=$(sudo nmcli d s | grep -E 'wlan0.*connected')
    echo "ConnectedInfo "$wlan0ConnectedInfo >> log.txt
    infoArr=($wlan0ConnectedInfo)
    echo "arr 0 "${infoArr[0]} " arr 1" ${infoArr[1]} >> log.txt
    connectedState=${infoArr[2]}
    networkName=${infoArr[3]}
    saveNetworkNameInfo=$(cat networkInfo.txt | grep NetworkName)
    nameArr=($saveNetworkNameInfo)
    saveNetworkName=${nameArr[1]}
    if [ $networkName -eq $saveNetworkName ]; then
        nmcli con down $networkName
	    rm networkInfo.txt
    fi
}

TurnOnHotspot() {
    while :; do {
        exec 3>&1
        input=$(dialog --title "Hotspot Setting" --clear \
            --backtitle "$BACKTITLE" \
            --nocancel \
            --form "Please input:" 10 70 5 \
            "NetworkName: " 1 1 "" 1 14 48 0 \
            "Password: " 2 1 "" 2 14 48 0 \
            2>&1 1>&3)
        result=$?
        exec 3>&-

        IFS=$'\n'
        values=($input)
        networkName=${values[0]}
        password=${values[1]}
        unset IFS

        passwordLength=${#password}
        echo "password length "$passwordLength >>log.txt
        if [ $passwordLength -lt 8 ]; then
            PasswordWarningMsg
            echo "PasswordWarning" >>log.txt
            continue
        fi

        if [ $result -eq "0" ]; then
            TurnOnHotspotByNmcli "$networkName" "$password"
            HotspotInformation "$networkName" "$password" "0"
            break
        else
            break
        fi
    }; done
}

HotspotInformation() {
    networkName=$1
    password=$2
    mode=$3 #0: information; 1: turn off

    msg="NetworkName $networkName\n"
    msg="${msg}Password $password"

    okLabel="OK"
    if [ "$mode" -eq "1" ]; then
        okLabel="TurnOff"
    fi
    echo "Mode "$mode >>log.txt
    echo "OkLabel "$okLabel >>log.txt

    while :; do
        if [ "$mode" -eq "1" ]; then
            if ! [ -f networkInfo.txt ]; then
                break
            fi
            dialog --title "Hotspot Information" --clear \
                --backtitle "$BACKTITLE" \
                --exit-label "$okLabel" \
                --textbox networkInfo.txt 10 70
        elif [ $mode -eq "0" ]; then
            dialog --title "Hotspot Information" --clear \
                --backtitle "$BACKTITLE" \
                --ok-label "$okLabel" \
                --msgbox \
                "$msg" 10 70
        fi

        result=$?

        if [ $result -eq "0" ]; then
            if [ "$mode" -eq "0" ]; then
                echo "Information" >> log.txt
                echo -e $msg > networkInfo.txt
                break
            elif [ "$mode" -eq "1" ]; then
                TurnOffHotspotByNmcli
                echo "Turn off" >> log.txt
                break
            fi
        fi
    done
}

PasswordWarningMsg() {
    msg="Wrong password length\n"

    dialog --title "Password Warning" --clear \
        --backtitle "$BACKTITLE" \
        --msgbox \
        "$msg" 10 70
}

Exit() {
    clear
    echo "Program Terminated."
    exit
}

Main
