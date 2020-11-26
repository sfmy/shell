#!/bin/bash

function install {
	name="${1}"
	check="${2}"
	if [[ -z "${check}" ]]; then
		check="${name}"
	fi
	if [[ `command -v ${check}` ]]; then
		echo "already exist ${name}!"
	else
		echo "installing ${name}"
		brew install ${name}
	fi
}

install macvim mvim
install mpv 
install git
install subversion svn
install tmux
install imagemagick magick
install youtube-dl
install aria2 aria2c
