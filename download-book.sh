#!/bin/bash

booksite="https://m.uubqg.cc"
tipstr="###"
echo "${tipstr} download books from ${booksite}"

function DownloadUrl {
	url="${1}"
	name="${2}"

	page="${booksite}"`curl -s ${url} | grep "开始阅读" | grep -o "/[^\"]*html"`
	> "${name}.txt"
	title=
	pretitle=
	while [ "${page}" != "${booksite}" ]; do
		curl -s ${page} -o tmp
		page="${booksite}"`cat tmp | grep -E "下一页|下一章" | grep -o "/[^\"]*html"`

		title=`cat tmp | grep -o "class=\"title\"[^<]*" | sed 's/class="title">//' | sed 's/&nbsp;/ /g'`
		if [ "${title}" != "${pretitle}" ]; then
			echo "${title}" >> "${name}.txt"
			echo "${tipstr} downlading ${title}"
		fi
		pretitle=${title}
		cat tmp | grep '<p>' | sed 's/<p>//g' | sed 's/<\/p>//g' | sed 's/<!--.*-->//g' | sed 's///g'  >> "${name}.txt"
	done
}

function DownloadBook {
	name="${1}"

	echo "${tipstr} search book: ${name}"
	curl -s --data "searchkey=${name}&submit=" "${booksite}/search/" > tmp
	namelist=(`cat tmp | grep "bookname" | grep -o "[^>]*</a" | sed 's/<\/a//'`)
	urllist=(`cat tmp | grep "bookname" | grep -o "href=\"[^\"]*\"" | grep -o "/.*/"`)
	if [ ${#namelist[@]} -eq 0 ]; then
		echo "${tipstr} can't find ${name}"
		exit
	fi

	echo "${tipstr} choose a file to download: " 
	for ((i=0; i<${#namelist[@]}; ++i)); do
		echo "${i}\t${namelist[${i}]}"
	done

	read -p "${tipstr} input the file number you want to download:" choose
	while [[ `echo ${choose} | grep -o "[0-9]*"` != "${choose}" ]]; do
		read -p "${tipstr} input the file number you want to download:" choose
	done

	url="${booksite}${urllist[${choose}]}"
	DownloadUrl "${url}" "${name}"
}

# DownloadBook "窃玉"
DownloadBook "灵山"
