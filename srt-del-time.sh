#!/bin/bash

function Usage () {
    echo "srt文件删除时间行，路径名不要有空格"
    echo "	-d|--dir)	处理文件夹中的所有文件"
    echo "	-o|--out)	处理后的文件路径"
    echo "example:"
    echo "./srt-del-time.sh -d ./a -o ./b"
}

function HandleFile () {
    local dir=${1}
    local out=${2}
    mkdir -p ${out}
    find ${dir} -name "*.srt" | while read item; do
	echo "正在处理文件:${item}"
	cat ${item} | sed "/^[0-9]*:[0-9]*:[0-9]*,[0-9]* \-\-> [0-9]*:[0-9]*:[0-9]*,[0-9]*$/d" | sed "/^[0-9]*:[0-9]*,[0-9]* \-\-> [0-9]*:[0-9]*,[0-9]*$/d"  > ${out}/${item##*/}
    done
}

function Main () {
    [[ $# -eq 0 ]] && Usage && exit
    local dir out
    while [[ -n ${1} ]]; do
	case ${1} in
	    -d|--dir)
		[[ $# -ge 2 ]] && dir=${2} && shift 1
		shift 1
		;;
	    -o|--out)
		[[ $# -ge 2 ]] && out=${2} && shift 1
		shift 1
		;;
	    *)
		shift 1
		;;
	esac
    done
    [[ -z ${dir} || -z ${out} ]] && Usage && exit
    HandleFile ${dir} ${out}
}

Main $@
