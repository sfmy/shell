#!/bin/bash
#抓取腾讯国漫视频

function getYouGetPid () {
	number=`ps aux | grep you-get | grep -v grep | wc -l`
	if [ "${number}" == "0" ]; then
		echo "0"
	else
		echo `ps aux | grep you-get | grep -v grep | awk '{print $2}'`
	fi
}

function downloadVideo () {
	echo "正在下载${1}"
	you-get -n "${1}" &
	sleep 3
	if [ `getYouGetPid` != "0" ]; then
		sleep 15
		if [ `getYouGetPid` != "0" ]; then
		   	kill `getYouGetPid` 
			downloadVideo "${1}"
		fi
	fi
}

function downFromUrl () {
	root_url="https://v.qq.com"
	curl -s "${1}" | grep "span __wind" -A 8 | grep -o "/x/cover/.*html" | while read item; do 
		downloadVideo "${root_url}${item}"
		you-get "${root_url}${item}" #合并视频
	done
}

downFromUrl "${1}"

