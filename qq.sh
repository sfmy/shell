#!/bin/bash

# 腾讯漫画
function CheckTools {
    local tool_list=("curl" "aria2c" "gsed" "magick")
    for item in ${tool_list[@]}; do
	[[ -z `which ${item}` ]] && echo "请安装${item}" && return 1
    done
}

function Usage {
    local SITE="https://ac.qq.com"
    local EXAMPLE=" sh qq.sh -n '渡劫失败都怪你' -u 'https://ac.qq.com/Comic/comicInfo/id/647793'"
    echo "Usage:下载漫画 ${SITE}"
    echo " -h | --help=HELP 帮助"
    echo " -n | --name=NAME 漫画名字"
    echo " -u | --url=URL 漫画地址"
    echo " -a | --append=APPEND 追加下载n个章节"
    echo " -c | --check 检查已经下载的章节中是否有遗漏下载的图片"
    echo " -s | --start=START 从第n话开始下载"
    echo "example:"
    echo ${EXAMPLE}
}

function ParseData {
    local data_str=${1}
    local result
    while true; do
	data_str=${data_str:1}
	[[ ${#data_str} -le 1 ]] && return
	result=`echo ${data_str} | base64 -d 2>/dev/null`
	if [[ ! -z `echo ${result} | grep -o 'chapter'` ]]; then
	    [[ ! -z `echo ${result} | grep -o '"vipStatus":2'` ]] && return
	    echo ${result} | \
	       	grep -o '"http[^"]*.jpg[^"]*"' | \
		grep 'manhua_detail' | \
	       	sed 's/"//g' | \
	       	sed 's/\\//g'
	    return
	fi
    done
}

function DownloadChapter {
    local chapter_url=${1} save_dir=${2} 
    local jpg_file="${save_dir}/pictures.txt"
    local chapter_file="${save_dir}/chapter.html"
    [[ ! -f ${chapter_file} ]] && curl -s ${chapter_url} -o ${chapter_file}
    if [[ ! -f ${jpg_file} ]]; then
	local data_str=`curl -s ${chapter_url} | grep 'DATA' | grep -o "'.*'" | sed "s/'//g"`
	ParseData ${data_str} > ${jpg_file}
    fi
    [[ `cat ${jpg_file} | wc -l` -eq 0 ]] && return 1
    local result=0 index=0 jpg
    for item in `cat ${jpg_file}`; do
	jpg="${index}.jpg"
	if [[ ! -f "${save_dir}/${jpg}" ]]; then
	    curl -s ${item} -o "${save_dir}/${jpg}"
	    [[ $? -ne 0 ]] && result=$?
	fi
	index=$((index+1))
    done
    return ${result}
}

function DownloadComic {
    local comic_name=${1} comic_url=${2} comic_count=${3} check=${4} startc=${5}
    local json_file="腾讯漫画/${comic_name}/${comic_name}.json"
    local html_file="腾讯漫画/${comic_name}/${comic_name}.html"
    local json_content

    mkdir -p "腾讯漫画/${comic_name}"
    [[ ! -f ${json_file} ]] && echo '{}' > ${json_file}
    json_content=`jq -r . ${json_file}`
    curl -s ${comic_url} | grep '<a target="_blank" title' | grep -v '</a>' > ${html_file}

    local title chapter_url 
    while read item; do
	title=`echo ${item} | grep -o 'title="[^"]*"' | sed 's/title=//' | sed 's/"//g' | sed 's/ /-/g'`
	startc=$((startc-1))
	if [[ ${startc} -gt 0 ]]; then
	    echo "跳过章节${title}" && continue
	fi
	chapter_url=`echo ${item} | grep -o 'href="[^"]*"' | sed 's/href=//' | sed 's/"//g'`
	chapter_url="https://ac.qq.com${chapter_url}"
	if [[ ${check} -eq 0 && `echo ${json_content} | jq -r .\"${title}\"` = '1' ]]; then
	    echo "已经下载 -> 腾讯漫画/${comic_name}/${title}" && continue
	fi
	mkdir -p "腾讯漫画/${comic_name}/${title}"
	echo "正在下载 -> 腾讯漫画/${comic_name}/${title}"
	DownloadChapter ${chapter_url} "腾讯漫画/${comic_name}/${title}"
	if [[ $? -eq 0 ]]; then
	    json_content=`echo ${json_content} | jq --args .\"${title}\"=1`
	    echo ${json_content} | jq -r . > ${json_file}
	fi
	comic_count=$((comic_count-1))
	[[ ${comic_count} -le 0 ]] && break
    done < ${html_file} && rm ${html_file}
}

[[ `CheckTools` -ne 0 ]] && exit
function Main {
    [[ $# -eq 0 ]] && Usage && exit
    local name url append startc check
    while [[ -n ${1} ]]; do
	case ${1} in
	    -n|--name)
		name=${2}
		shift 2
		;;
	    -u|--url)
		url=${2}
		shift 2
		;;
	    -a|--append)
		append=${2}
		shift 2
		;;
	    -s|--start)
		startc=${2}
		shift 2
		;;
	    -c|--check)
		check=1
		shift
		;;
	    -h|--help)
		return 1
		;;
	    *)
		return 1
		;;
	esac
    done
    [[ -z ${name} ]] && return 1
    [[ -z ${url} ]] && return 1
    [[ -z ${append} ]] && append=9999
    [[ -z ${check} ]] && check=0
    [[ -z ${startc} ]] && startc=1
    DownloadComic "${name}" "${url}" "${append}" "${check}" "${startc}"
    return 0
}
Main $@
[[ $? -ne 0 ]] && Usage
