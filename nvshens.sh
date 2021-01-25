#!/bin/bash

function Usage () {
    echo "下载https://www.nvshens.org/网站图片"
    echo "	-h|--help	帮助"
    echo "	-u|--url	地址"
    echo "	-l|--list       地址"
    echo "example:"
    echo "	sh nushens.sh --url 'https://www.nvshens.org/g/27877'"
}

function DownloadPics () {
    local page_url=${1}
    local json_file="nvshens/nvshens.json"
    local html_file=`mktemp`

    echo "正在下载《${page_url}》"
    curl -s ${page_url} -o ${html_file}
    [[ $? -ne 0 ]] && echo "下载《${page_url}》失败" && return 1
    mkdir -p "nvshens"
    [[ ! -f ${json_file} ]] && echo '{}' > ${json_file}

    local page_id=`echo ${page_url:25} | sed 's/\///g'`
    local title=`grep -o '<title>.*</title>' ${html_file} | sed 's/<title>//' | sed 's/<\/title>//' | sed 's/ /-/g'`
    [[ `jq .\"${title}\" ${json_file}` = "1" ]] && echo "已经下载《${page_url}》" && return
    mkdir -p "nvshens/${title}"
    local jpg_file="nvshens/${title}/pictures.txt"
    > "${jpg_file}"

    local page_list=(`grep -o -E "href=\"[^\"]*\"|href='[^']*'" ${html_file} | grep ${page_id} | sed 's/href=//' | sed 's/"//g' | sed "s/'//g" | sort | uniq`)
    for item in ${page_list[@]}; do
	item="https://www.nvshens.org/${item}"
	curl -s ${item} | grep -o "http[^\"^']*.jpg" | grep ${page_id} >> "${jpg_file}"
    done
    rm ${html_file}
    page_id="${page_id}"
    local result=0
    while read item; do
	local file_name=`echo ${item//*${page_id}} | sed 's/\//_/g'`
	echo "正在下载nvshens/${title}/${file_name}"
	if [[ ! -f "nvshens/${title}/${file_name}" ]]; then
	    curl -s ${item} -o "nvshens/${title}/${file_name}"
	    [[ $? -ne 0 ]] && result=1
	fi
    done < "${jpg_file}"
    if [[ ${result} -eq 0 ]]; then
	local json_content=`jq -r . ${json_file}`
	echo ${json_content} | jq --args .\"${title}\"=1 > ${json_file}
	echo "下载《${page_url}》完成"
    else
	echo "下载《${page_url}》失败"
    fi
}

function GetPageList () {
    local url=${1}
    curl -s ${url} | grep "href=" | grep -o '/g/\d\+/' | sed 's/^/https:\/\/www.nvshens.org/' | sort| uniq
}

function Main () {
    [[ $# -eq 0 ]] && Usage && return
    local page_url
    local page_list
    while [[ -n ${1} ]]; do
	case ${1} in
	    -u|--url)
		page_url=${2}
		shift 2
		;;
	    -l|--list)
		page_list=(`GetPageList ${2}`)
		shift 2
		;;
	    *)
		shift 1
		;;
	esac
    done
    if [[ ${#page_list[@]} -ne 0 ]]; then
	for item in ${page_list[@]}; do
	    DownloadPics ${item}
	done
    else
	[[ -z ${page_url} ]] && Usage && return
	DownloadPics ${page_url}
    fi
}

Main "$@"
