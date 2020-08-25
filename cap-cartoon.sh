#!/bin/bash

# 搜索爬取漫画
web_url="https://www.kanmanshe.com/"

SearchCartoon () {
	cartoon_name="${1}"
	search_url="https://www.kanmanshe.com/sou?keyword=${cartoon_name}"
	cartoon_url=`curl -s "${search_url}" | \
		grep "href.*title.*${cartoon_name}" | \
	   	head -n 1 | \
		grep -o "\"[^\"]*\"" | \
		head -n 1 |
	   	sed "s/\"//g"`
	echo "${cartoon_url}"
}

# SearchCartoon "恶作剧初吻"
DownloadChapter () {
	chapter_url="${1}"
	chapter_name="${2}"
	cartoon_name="${3}"
	mkdir -p "${cartoon_name}/${chapter_name}"
	file_name="${cartoon_name}/${chapter_name}/pictures.txt"
	curl -s "${chapter_url}" | \
		grep "data-original" | \
		grep -o "https[^\"]*" \
		> "${file_name}"
	aria2c -i "${file_name}" -d "${cartoon_name}/${chapter_name}"
	# 合并图片比较费时
	# convert -append `cat "${file_name}"` "${cartoon_name}/${chapter_name}"""".jpg" 
}

DownloadCartoon () {
	cartoon_name="${1}"
	cartoon_url=`SearchCartoon "${cartoon_name}"`
	if [ -z "${cartoon_url}" ]; then
		echo "未搜索到漫画《${cartoon_name}》"
	else
		echo "开始下载漫画《${cartoon_name}》"
		mkdir -p "${cartoon_name}"
		cartoon_url="${web_url}${cartoon_url}"
		curl -s "${cartoon_url}" | \
		   	grep "href.*chapter.*_blank" | \
			while read item; do
				chapter_url=`echo "${item}" | \
					awk -F '"' '{print $2}'`
				chapter_name=`echo "${item}" | \
					grep -o ">.*<" | \
					sed "s/>//g" | \
					sed "s/<//g"`
				chapter_url="${web_url}${chapter_url}"
				DownloadChapter "${chapter_url}" "${chapter_name}" "${cartoon_name}" 
			done
	fi
}

# DownloadCartoon "恶作剧初吻"
cartoon_list=( "比邻而交" )
for name in "${cartoon_list[@]}"; do
	DownloadCartoon "${name}"
done
