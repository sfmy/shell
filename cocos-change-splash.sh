#!/bin/bash

function Usage () {
    echo "Cocos Creator 自动更换splash脚本"
    echo "	-h|--help		帮助"
    echo "	-d|--directory		目录"
    echo "	-t|--target		平台(mobile|desktop)"
    echo "	-i|--icon		图标图片"
    echo "	-s|--splash 		背景图片"
    echo "example:"
    echo "	./cocos-change-splash.sh -d ./fold/ -t mobile -i ./icon.png -s ./splash.png"
}

function ChangeSplash () {
    local dir=${1} target=${2} icon=${3} splash=${4}
    local lineno insert_str

    local html_file=`find "${dir}" -name "index.html" | grep "${target}"`
    echo "正在修改html文件:	${html_file}"
    lineno=`grep -n 'id="splash"' "${html_file}" | awk -F ':' '{print $1}'`
    local icon_size=`identify "${icon}" | awk '{print $3}'`
    local height=${icon_size#*x} width=${icon_size/x*}
    insert_str="<img src=\"icon.png\" style=\" position: absolute; width: ${width}px; height: ${height}px; left: 50%; top: 50%; margin-left: -$((width/2))px; margin-top: -$((height/2))px; \"/>"
    gsed -i "${lineno}a${insert_str}" "${html_file}"

    echo "正在复制icon图片 ${icon}"
    cp "${icon}" `find "${dir}" -name "web-${target}"`/icon.png
    echo "正在复制splash图片"
    cp "${splash}" `find "${dir}" -name "splash*.png" | grep "${target}"`
    local css_file=`find "${dir}" -name "style-${target}*.css" | grep "${target}"`
    echo "正在修改css文件:	${css_file}"
    lineno=`grep -n 'background:' "${css_file}" | awk -F ':' '{print $1}'`
    lineno=$((lineno+1))
    gsed -i "${lineno}s/\d*/100/" "${css_file}"

    local js_file=`find "${dir}" -name "main*.js" | grep "${target}"`
    echo "正在修改js文件:	${js_file}"
    lineno=`grep -n 'none' "${js_file}" | awk -F ':' '{print $1}'`
    gsed -i "${lineno}s/^/\/\//" "${js_file}"
    lineno=`grep -n 'var progressBar' "${js_file}" | awk -F ':' '{print $1}'`
    insert_str='var tm = Date.now();'
    gsed -i "${lineno}a${insert_str}" "${js_file}"
    lineno=`grep -n 'var percent' "${js_file}" | awk -F ':' '{print $1}'`
    lineno=$((lineno+3))
    insert_str='if (percent == 100) { if (Date.now()-tm >= 1000) { splash.style.display = "none"; } else { setTimeout(() => { splash.style.display = "none"; }, tm+1000-Date.now()); }}'
    gsed -i "${lineno}a${insert_str}" "${js_file}"
}

function Main () {
    [[ $# -eq 0 ]] && Usage && exit 1
    local dir splash icon target="mobile" 
    while [[ -n $1 ]]; do
	case $1 in
	    -h|--help)
		shift 1
		;;
	    -d|--directory)
		if [[ -n $2 ]]; then
		    dir=$2; shift 2
		else
		    shift 1
		fi
		;;
	    -t|--target)
		if [[ -n $2 ]]; then
		    target=$2; shift 2
		else
		    shift 1
		fi
		;;
	    -i|--icon)
		if [[ -n $2 ]]; then
		    icon=$2; shift 2
		else
		    shift 1
		fi
		;;
	    -s|--splash)
		if [[ -n $2 ]]; then
		    splash=$2; shift 2
		else
		    shift 1
		fi
		;;
	    *)
		shift 1
		;;
	esac
    done
    if [[ -z ${dir} || -z ${target} || -z ${splash} ]]; then
	Usage
    else
	[[ -z ${icon} ]] && icon=`find ${dir} -name 'splash*.png' | grep ${target}`
	ChangeSplash ${dir} ${target} ${icon} ${splash}
    fi
}

Main $@
