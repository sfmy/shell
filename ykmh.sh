#!/bin/bash
SITE="https://www.ykmh.com/"
COUNT=20

function Usage () {
    echo "下载漫画${SITE}"
    echo "	-h|--help 	帮助"
    echo "	-u|--url	漫画地址"
    echo "	-d|--dir	保存目录"
    echo "	-s|--search	搜索漫画"
}

function DownloadChapter () {
    local save_dir=${1}
    local chapter_url=${2}
    mkdir -p "${save_dir}"
    local image_list=(`curl -s ${chapter_url} | grep 'chapterImages' | grep -o "\[.*\]" | sed 's/"//g' | sed 's/,/ /g' | sed 's/\[//' | sed 's/\]//' | tr -d '\'`)
    [[ ${#image_list[@]} -eq 0 ]] && echo "下载${save_dir}失败" && return
    echo "正在下载${save_dir}"
    for item in ${image_list[@]}; do
	local file="${save_dir}/${item##*/}"
	if [[ ! -f ${file} ]]; then
	    echo "正在下载${file}"
	    curl -s "https://pic.w1fl.com/${item}" -o ${file} &
	    while [[ `pgrep curl | wc -l` -ge ${COUNT} ]]; do
	       	sleep 1
	    done
	else
	    echo "跳过下载${file}"
	fi
    done
}

function DownloadComic () {
    local url=${1}
    local dir=${2}
    local page=`mktemp`
    curl -s ${url} -o ${page}
    [[ $? -ne 0 ]] && echo "下载${url}失败" && exit
    local comic_name=`grep -o '<h1>.*</h1>' ${page} | sed 's/<[^>]*>//g'`
    [[ -z ${comic_name} ]] && echo "解析漫画名字失败" && exit
    comic_name="${dir}${comic_name}"
    mkdir -p "${comic_name}"
    local can_grep="false"
    local chapter_name chapter_url
    cat ${page} | while read item; do
    	[[ -n `echo ${item} | grep 'zj_list_con'` ]] && can_grep="true"
	[[ ${can_grep} = "false" ]] && continue
	if [[ -n `echo ${item} | grep 'href'` ]]; then
	    chapter_url=`echo ${item} | grep -o 'href="[^"]*' | sed 's/href=//' | sed 's/"//g'`
	    chapter_url="${SITE}${chapter_url#/}"
	fi
	if [[ -n `echo ${item} | grep 'list_con_zj'` ]]; then
	    chapter_name=`echo ${item} | awk -F '>' '{print $4}' | awk -F '<' '{print $1}' | tr -d ' '`
	    DownloadChapter "${comic_name}/${chapter_name}" ${chapter_url}
	fi
	[[ -n `echo ${item} | grep '</div>'` ]] && break
    done
    rm ${page}
}

function Main () {
    [[ $# -eq 0 ]] && Usage && exit

    local search dir url
    while [[ -n ${1} ]]; do
	case ${1} in
	    -h|--help)
		Usage && exit
		;;
	    -u|--url)
		if [[ -n ${2} ]]; then
		    url=${2}
		    shift 2
		else
		    shift 1
		fi
		;;
	    -d|--dir)
		if [[ -n ${2} ]]; then
		    dir=${2}
		    shift 2
		else
		    shift 1
		fi
		;;
	    -s|--search)
		if [[ -n ${2} ]]; then
		    search=${2}
		    shift 2
		else
		    shift 1
		fi
		;;
	    *)
		Usage && exit
		;;
	esac
    done
    [[ -z ${dir} ]] && dir="ykmh/"

    if [[ -n ${url} ]]; then
	DownloadComic ${url} ${dir}
    fi
}

Main $@
