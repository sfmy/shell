#!/bin/bash

if [[ `which cliclick` = "" ]]; then
	echo "please install cliclick: brew install cliclick"
	exit
fi

poslist=()

function showMenu () {
	echo "请选择以下功能:"
	echo "  1) 添加位置"
	echo "  2) 持续点击"
	echo "  3) 点击添加的位置"
	read -p "输入:" num
	case $num in
		1) addPos ;;
		2) alwaysClick ;;
		3) clickAllPos ;;
		*) showMenu ;;
	esac
}

function addPos () {
	echo "移动鼠标到添加位置"
	cliclick w:2000
	pos=`cliclick p`
	echo "添加位置${pos}成功"
	len=${#poslist[@]}
	poslist[$len]=$pos
	showMenu
}

function alwaysClick () {
	echo "移动鼠标到点击位置"
	cliclick w:2000
	pos=`cliclick p`
	cliclick m:$pos
	echo "开始点击$pos位置"
	count=0
	while [[ `cliclick p` = $pos ]]; do
		cliclick c:.
		cliclick w:100
		count=$((count+1))
		echo $count
	done
	echo "点击取消"
	showMenu
}

function clickAllPos () {
	echo "点击添加的位置"
	if [[ ${#poslist[@]} -gt 0 ]]; then
		index=0
		pos=`cliclick p`
		while true; do
			if [[ `cliclick p` != $pos ]]; then
				break
			fi
			pos=${poslist[$index]}
			cliclick c:$pos
			cliclick w:100
			index=`echo "($index+1)%${#poslist[@]}" | bc`
			echo $index
		done
	fi
	showMenu
}

showMenu
