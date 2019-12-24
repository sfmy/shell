#!/bin/bash

########################################
#爬https://91mjw.com/网站的视频
########################################


#更具m3u8文件下载视频
function downloadM3u8Video () {
	url=${1}
	m3u8_file=${url##*/}
	pre_path=${url%/*}

	echo ${m3u8_file}
	if [ ! -e ${m3u8_file} ]; then
		echo "下载 ${url}"
		aria2c ${url} > /dev/null 2>&1
	fi

	if [ -e ${m3u8_file} ]; then
		ts_list=$(cat ${m3u8_file} | grep '.*.ts')
		len=$(echo ${ts_list} | wc -w | sed 's/ //g')
		count=0
		outfile=${m3u8_file%.m3u8}".ts"
		if [ -e ${outfile} ]; then
			echo "${outfile} 已经存在！"
		else
			for ts_file in ${ts_list}; do
				aria2c -s 10 -x 10 ${pre_path}/${ts_file} > /dev/null 2>&1
				cat ${ts_file} >> ${outfile}
				rm ${ts_file}
				count=$((count+1))
				echo "下载${ts_file}完成  当前进度${count}/${len}"
			done
		fi
	fi
}

#从网页爬取m3u8文件
function parseUrl () {
	web_url=${1}
	url=$(curl ${web_url} -s | grep -o '".*.m3u8"' | sed 's/"//g')
	url=$(echo ${url} | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g' | sed 's/\\x3a/:/' | sed 's/\\x2f/\//g') 
	url=$(echo ${url} |  sed 's/\\x3A/:/' | sed 's/\\x2F/\//g') 
	downloadM3u8Video ${url}
}


if [ -z "${1}" ]; then
	echo "这是一个自动下载视频脚本"
	echo "-u url 下载url上的视频"
	echo "-i file 下载file中的url上的视频"
else
	if [ "-u" == ${1} ]; then
		parseUrl ${2}
	elif [ "-i" == ${1} ]; then
		cat ${2} | while read url; do
			parseUrl ${url}
		done
	fi
fi

