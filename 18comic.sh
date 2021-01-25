#!/bin/bash
# '下载https://18comic.vip网站的漫画'

function CheckTools {
    local tool_list=("curl" "aria2c" "gsed" "magick")
    for item in ${tool_list[@]}; do
	[[ -z `which ${item}` ]] && echo "请安装${item}" && return 1
    done
}


function Usage () {
    local SITE="https://18comic.bet"
    local EXAMPLE=" sh 18comic.sh -n '漂亮干姐姐' -u 'https://18comic.vip/album/195818'"
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

function DownOneChapter () {
    local save_dir=${1} chapter_url=${2} 
    local jpg_file="${save_dir}/pictures.txt"
    local chapter_file="${save_dir}/chapter.html"
    
    [[ ! -f ${chapter_file} ]] && curl -ks ${chapter_url} -o ${chapter_file}
    [[ ! -f ${chapter_file} ]] && echo "下载《${save_dir}》失败" && return 1

    local aid=`grep 'aid' ${chapter_file} | grep -o '\d\+'`
    local scramble_id=`grep 'scramble_id' ${chapter_file} | grep -o '\d\+'`
    local result=0
    grep -o '"https:[^"]*"' ${chapter_file} | sed 's/"//g' | grep 'photos.*jpg' > ${jpg_file}
    for item in `ls ${save_dir} | grep 'jpg'`; do
	gsed -i "/${item}/d" ${jpg_file}
    done
    if [[ `cat ${jpg_file} | wc -l` -gt 0 ]]; then
	aria2c -i ${jpg_file} -d ${save_dir} 
	result=$?
    fi
    if [[ ${aid} -gt ${scramble_id} ]]; then
	grep -o '\d\+.jpg' ${jpg_file} | while read item; do
		CorrectFile "${save_dir}/${item}"
	done
    fi
    return ${result}
}

function CorrectFile () {
    local file=${1}
    local size=`identify $file | awk '{print $3}'`
    local width=${size%x*}
    local height=${size#*x}
    local cropheight=$((height/10))
    echo "重新生成文件:${file}"
    local y=0
    for ((i=0; i<10; ++i)); do
	if [[ $i -ne 9 ]]; then
	    convert -crop ${width}x${cropheight}+0+${y} ${file} "tmp-${i}.jpg"
	    y=$((y+cropheight))
	else
	    cropheight=$(($height-9*$cropheight))
	    convert -crop ${width}x${cropheight}+0+${y} ${file} "tmp-${i}.jpg"
	fi
    done
    convert -append tmp-9.jpg tmp-8.jpg tmp-7.jpg tmp-6.jpg tmp-5.jpg tmp-4.jpg tmp-3.jpg tmp-2.jpg tmp-1.jpg tmp-0.jpg ${file}
    rm tmp-9.jpg tmp-8.jpg tmp-7.jpg tmp-6.jpg tmp-5.jpg tmp-4.jpg tmp-3.jpg tmp-2.jpg tmp-1.jpg tmp-0.jpg
}

function DownloadComic {
    local comic_name=${1} comic_url=${2} comic_count=${3} check=${4} startc=${5}
    local json_file="18comic/${comic_name}/${comic_name}.json"
    local site_url=`echo ${comic_url} | grep -o 'https://[^/]*'`
    local chapter_url
    local title
    local jump_title=""

    mkdir -p "18comic/${comic_name}"
    [[ ! -f ${json_file} ]] && echo '{}' > ${json_file}
    local json_content=`cat ${json_file}`
    local html_file="18comic/${comic_name}/${comic_name}.html"
    [[ ! -f ${html_file} ]] && curl -ks ${comic_url} -o ${html_file}
    [[ ! -f ${html_file} ]] && echo "下载《${comic_name}》失败" && return 1

    if [[ -n `grep 'class="current_series"' ${html_file}` ]]; then
	 grep -B 4 'class="hidden-xs" style="float: right;"' ${html_file} | sed '/--/d' | tr '\n' ' ' | sed 's/<\/span>/<\/span>\n/g' | grep 'href' | \
	    while read item; do
		local title=`echo ${item} | sed 's/<span.*//' | sed 's/<[^>]*>//g' | sed 's/^ *//g' | sed 's/ *$//g' | tr '/' ' ' | sed 's/ /-/g'`
		startc=$((startc-1))
		if [[ -n `echo ${jump_title} | grep -o ${title}` ]]; then 
		    continue
	       	fi
		if [[ ${startc} -gt 0 ]]; then
		    echo "跳过章节${title}"
		    jump_title="${jump_title} ${title}"
		    continue
		fi
		local chapter_url=`echo ${item} | grep -o 'href="[^"]*"' | sed 's/href=//' | sed 's/"//g'`
		chapter_url="${site_url}${chapter_url}"
		[[ ${check} -eq 0 && `echo ${json_content} | jq -r .\"${title}\"` = '1' ]] && echo "已经下载 -> 18comic/${comic_name}/${title}" && continue
		mkdir -p "18comic/${comic_name}/${title}"
		echo "开始下载《18comic/${comic_name}/${title}》" 
		DownOneChapter "18comic/${comic_name}/${title}" "${chapter_url}"
		if [[ $? -eq 0 ]]; then
		    echo "下载成功《18comic/${comic_name}/${title}》"
		    json_content=`echo ${json_content} | jq --args .\"${title}\"=1`
		else
		    echo "下载失败《18comic/${comic_name}/${title}》"
		    json_content=`echo ${json_content} | jq --args .\"${title}\"=0`
		fi
		echo ${json_content} | jq -r . > ${json_file}
		comic_count=$((comic_count-1))
		[[ ${comic_count} -le 0 ]] && break
	    done 
    else
	title=${comic_name}
	chapter_url=`grep -E '開始閱讀|开始阅读' ${html_file} | grep -o 'href="[^"]*"' | sed 's/href=//g' | sed 's/"//g'`
	chapter_url="${site_url}${chapter_url}"
	if [[ ${check} -eq 0 && `echo ${json_content} | jq -r .\"${title}\"` = '1' ]]; then
	    echo "已经下载《18comic/${title}》" 
	else
	    echo "开始下载《18comic/${title}》" 
	    DownOneChapter "18comic/${title}" "${chapter_url}"
	    if [[ $? -eq 0 ]]; then
		echo "下载成功《18comic/${title}》" 
		json_content=`echo ${json_content} | jq --args .\"${title}\"=1`
		echo ${json_content} | jq -r . > ${json_file}
	    else
		echo "下载失败《18comic/${title}》" 
	    fi
	fi
    fi
    rm ${html_file}
}

[[ `CheckTools` -ne 0 ]] && exit
# shell_args=(`GetShellArgs $@`)
# [[ $? -ne 0 ]] && Usage && exit
# [[ ${#shell_args[@]} -eq 5 ]] && DownloadComic ${shell_args[@]}
function Main () {
    local name url append startc check
    [[ $# -eq 0 ]] && Usage && exit
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
}
Main $@
[[ $? -ne 0 ]] && Usage
