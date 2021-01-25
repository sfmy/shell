#!/bin/bash
# 秀人网
SITE="http://www.xiuren.org/"
EXAMPLE="./xiuren.sh -u http://www.xiuren.org/tuigirl-special-lilisha-double-uefaeuro-2016.html"

function SimulateGoogle {
    local page_url=${1}
    local save_file=${2}
    curl -sSk ${page_url} \
	-H 'Connection: keep-alive' \
	-H 'Cache-Control: max-age=0' \
	-H 'Upgrade-Insecure-Requests: 1' \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Safari/537.36' \
	-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
	-H 'Accept-Language: zh-CN,zh;q=0.9' \
	--compressed \
	--insecure \
	-o ${save_file}
}

function Usage {
    echo "Usage:下载图片 ${SITE}"
    echo " -h | --help=HELP 帮助"
    echo " -u | --url=URL 地址"
    echo "example:"
    echo ${EXAMPLE}
}

function DownloadPic {
    local url=${1}
    local html_file="${url##*/}"
    local json_file="xiuren/xiuren.json"

    mkdir -p "xiuren"
    [[ ! -f ${json_file} ]] && echo '{}' > ${json_file}
    [[ ! -f "xiuren/${html_file}" ]] && SimulateGoogle ${url} "xiuren/${html_file}"
    [[ ! -f "xiuren/${html_file}" ]] && echo "下载《${utl}》失败" && return 1
    local title=`grep 'description' "xiuren/${html_file}" | grep -o '"[^"]*"' | grep -v 'description' | sed 's/"//g' | sed 's/ /-/g'`

    [[ `jq -r .\"${title}\" ${json_file}` -eq 1 ]] && \
	echo "已经下载了《${title}》" && \
	return 0

    mkdir -p "xiuren/${title}"
    local jpg_file="xiuren/${title}/pictures.txt"

    grep 'photoThum' "xiuren/${html_file}" | grep -o '"[^"]*"' | grep 'http.*jpg' | grep -v 'Thum' | sed 's/"//g' > ${jpg_file}
    for item in `ls xiuren/${title}/`; do
	gsed -i "/${item}/d" ${jpg_file}
    done
    [[ `cat ${jpg_file} | wc -l` -ne 0 ]] && \
	aria2c -i ${jpg_file} -d "xiuren/${title}"

    local json_content
    if [[ $? -eq 0 ]]; then
	echo "下载成功《${title}》"
	json_content=`jq -r . ${json_file}`
	json_content=`echo ${json_content} | jq --args .\"${title}\"=1`
	echo ${json_content} > ${json_file}
    else
	echo "下载失败《${title}》"
    fi
}

[[ $# -eq 0 ]] && Usage && exit
while [[ -n ${1} ]]; do
    case ${1} in
	-h|--help)
	    Usage && exit
	    ;;
	-u|--url)
	    url=${2} && shift 2
	    ;;
	*)
	    Usage && exit
	    ;;
    esac
done
[[ -z ${url} ]] && Usage && exit
DownloadPic ${url}
