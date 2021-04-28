#!/bin/bash

function Help () {
    echo '发布游戏到远程服务器'
    echo '--help|-h	显示帮助'
    echo '--dir|-d	游戏web-mobile路径'
}

function Deploy () {
    local dir=${1}
    [[ ! -d ${dir} ]] && echo "${dir}不存在" && exit

    local pack_name="web-mobile-`date '+%m-%d-%H-%M'`.zip"
    echo "打包${dir} -> ${pack_name}"
    7z a ${pack_name} ${dir}

    echo "拷贝${pack_name}到${USSERVER}"
    scp ${pack_name} root@$USSERVER:~/

    echo "删除${pack_name}"
    rm ${pack_name}

    echo "执行远程脚本"
    ssh root@${USSERVER} "[[ -f ~/cp-game-web-to-nginx.sh ]] && sh ~/cp-game-web-to-nginx.sh"
}

function Main () {
    [[ $# -ne 2 ]] && Help && exit
    [[ ${1} != '--dir' && ${1} != '-d' ]] && Help && exit
    Deploy ${2}
}

Main $@
