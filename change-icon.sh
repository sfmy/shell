#!/bin/bash

function Usage () {
    echo "替换工程的图标"
    echo "	-d|--dir 	工程目录"
    echo "	-h|--help	帮助"
    echo "	-i|--icon	图标"
    echo "example:"
    echo "	./change-icon.sh -d MyApp -i ./icon.png"
}

function ChangeIcon () {
    local dir=${1}
    local icon=${2}
    find `pwd` -name "*.png" | grep 'ic_launcher.png' | while read item; do
    	local image_size=`identify ${item} | awk '{print $3}'`
	echo "convert ${icon} -resize ${image_size}! ${item}"
	convert ${icon} -resize ${size}! ${item}
    done
}

function Main () {
    [[ $# -eq 0 ]] && Usage && exit
    local dir icon
    while [[ -n ${1} ]]; do
	case ${1} in
	    -d|--dir)
		if [[ -n ${2} ]]; then
		    dir=${2} 
		    shift 2
		else
		    shift 1
		fi
		;;
	    -i|--icon)
		if [[ -n ${2} ]]; then
		    icon=${2} 
		    shift 2 
		else
		    shift 1
		fi
		;;
	    -h|--help)
		shift 1
		;;
	    *)
		shift 1
		;;
	esac
    done
    [[ -z ${dir} || -z ${icon} ]] && Usage && exit
    ChangeIcon ${dir} ${icon}
}

Main $@
