#!/bin/bash

echo "下载 https://18comic.fun/ 漫画书"

function showhelp () {
	echo "下载 https://18comic.fun/ 漫画书"
	echo "-i file 下载file中的漫画列表"
	echo "-u url 下载url中的漫画"
	echo "-n name 漫画名字"
	echo "-d dir 存储地址"
	echo "-h help"
	exit 0
}



comic_list=""
comic_url=""
comic_name=""
save_dir="./"
while getopts i:u:n:d:h: opts; do
	case ${opts} in
		i) comic_list=${OPTARG} ;;
		u) comic_url=${OPTARG} ;;
		n) comic_name=${OPTARG} ;;
		d) save_dir=${OPTARG} ;;
		h) showhelp ;;
	esac
done

function downloadurl () {
	comic_url=${1}
	comic_name=${2}
	if [ ! -d "${comic_name}" ]; then
		echo mkdir -p "${save_dir}${comic_name}"
		mkdir -p "${save_dir}${comic_name}"
		proxychains4 curl "${comic_url}" | grep -o "https.*photos.*jpg" | while read item; do
			echo wget -q "${item}" -P "${save_dir}${comic_name}"
			proxychains4 wget -q "${item}" -P "${save_dir}${comic_name}"
		done
	fi
}

if [ "${comic_list}" != "" ]; then
	cat "${comic_list}" | while read item; do
		comic_url=`echo ${item} | awk '{print $1}'`
		comic_name=`echo ${item} | awk '{print $2}'`
		downloadurl "${comic_url}" "${comic_name}"
	done
else
	if [ -z "${comic_url}" ]; then
		echo "请输入漫画地址"
		exit
	elif [ -z "${comic_name}" ]; then
		echo "请输入漫画名字"
		exit
	fi
	downloadurl "${comic_url}" "${comic_name}"
fi


