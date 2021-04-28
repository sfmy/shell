#!/bin/bash

function Tip () {
    local delay=${1} word=${2} loop=${3}
    [[ -z ${loop} || ${loop} = 0 ]] && loop=999999
    while [[ ${loop} -gt 0 ]]; do
	sleep ${delay}
	say "${word}"
	loop=$((loop-1))
    done
}

function Main () {
    Tip 120 '注意坐姿'
}

Main
