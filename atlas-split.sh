#!/bin/bash

function Usage () {
    echo "根据atlas文件切割png图片为小图，路径名中不要含有空格"
    echo "	--atlas|-a)	atlas文件"
    echo "	--png|-p)	png文件"
    echo "	--dir|-d)	保存的文件夹"
    echo "example:"
    echo "./atlas-split.sh -a a.atlas -p a.png -d ./out/"
}

function SplitPng () {
    local png="${1}" name="${2}" rotate="${3}" xy="${4}" size="${5}" orig="${6}" offset="${7}" dir="${8}"
    local x=`echo ${xy} | awk '{print $1}'`
    local y=`echo ${xy} | awk '{print $2}'`
    local width=`echo ${size} | awk '{print $1}'`
    local height=`echo ${size} | awk '{print $2}'`
    echo convert ${png} -crop ${width}x${height}+${x}+${y} ${dir}/${name}.png
    convert ${png} -crop ${width}x${height}+${x}+${y} ${dir}/${name}.png
}

function SplitPngByAtlas () {
    local atlas="${1}" png="${2}" dir="${3}"
    mkdir -p "${dir}"
    local start_match=0
    local name rotate xy size orig offset index
    local png_name="${png##*/}"
    while read line; do
	[[ ${line} = ${png_name} ]] && start_match=1
	[[ ${start_match} -eq 0 ]] && continue
	[[ -z `echo ${line} | grep ':'` ]] && name=${line}
	[[ -n `echo ${line} | grep 'rotate'` ]] && rotate=`echo ${line} | awk '{print $2}'`
	[[ -n `echo ${line} | grep 'xy'` ]] && xy=`echo ${line} | awk -F ':|,' '{print $2 $3}'`
	[[ -n `echo ${line} | grep 'size'` ]] && size=`echo ${line} | awk -F ':|,' '{print $2 $3}'`
	[[ -n `echo ${line} | grep 'orig'` ]] && orig=`echo ${line} | awk -F ':|,' '{print $2 $3}'`
	[[ -n `echo ${line} | grep 'offset'` ]] && offset=`echo ${line} | awk -F ':|,' '{print $2 $3}'`
	if [[ -n `echo ${line} | grep 'index'` ]]; then
	    SplitPng "${png}" "${name}" "${rotate}" "${xy}" "${size}" "${orig}" "${offset}" "${dir}"
	fi
	[[ -z ${line} ]] && break
    done < ${atlas}
}

function Main () {
    [[ -z `which magick` ]] && "请先安装Imagemagick" && exit
    local atlas png dir
    while [[ -n "${1}" ]]; do
	case "${1}" in
	    --atlas|-a)
		[[ -n "${2}" ]] && atlas="${2}"
		[[ $# -ge 2 ]] && shift 2 || shift 1
		;;
	    --png|-p)
		[[ -n "${2}" ]] && png="${2}"
		[[ $# -ge 2 ]] && shift 2 || shift 1
		;;
	    --dir|-d)
		[[ -n "${2}" ]] && dir="${2}"
		[[ $# -ge 2 ]] && shift 2 || shift 1
		;;
	    *)
		shift 1
		;;

	esac
    done
    [[ -z "${atlas}" || -z "${png}" || -z "${dir}" ]] && Usage && exit
    SplitPngByAtlas "${atlas}" "${png}" "${dir}"
}

Main $@
