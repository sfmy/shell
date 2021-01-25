#!/bin/bash

function Usage () {
    echo "阅读漫画"
    echo "-h|--help 显示帮助"
    echo "-d|--dir  阅读漫画的章节目录"
    echo "example:"
    echo "./read.sh -d './18comic/与前妻同居/第10話-15'"
}

function Read () {
    local dir
    dir="$(pwd)/${1}"
    [[ ! -d ${dir} ]] && echo "${dir} not exist" && exit
    local html="tmp.html"
    echo "<html><title>漫画</title><body>" > ${html}
    find "${dir}" -name '*.jpg' | sort | while read -r item; do
	echo "<img src=\"${item}\" width=\"100%\" alt=\"${item}\">" >> ${html}
    done
    echo "</body></html>" >> ${html}
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' --new-window ${html}
    sleep 1
    rm ${html}
}

[[ $# -eq 0 ]] && Usage && exit

while [[ -n "${1}" ]]; do
    case "${1}" in
	-h|--help)
	    Usage && exit
	    ;;
	-d|--dir)
	    if [[ -n "${2}" ]]; then
		Read "${2}" && exit
	    else
		Usage && exit 
	    fi	
	    shift 2
	    ;;
	*)
	    Usage && exit
	    ;;
    esac
done
