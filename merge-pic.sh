#!/bin/bash

echo "合并图片"

function MergePictures () {
	cur_dir=`pwd`
	comic_dir=${1}
	cd ${comic_dir}

	for chapter in `ls`; do
		if [ -d "${chapter}" ]; then
			echo "进入目录${chapter}" && cd ${chapter}
			if [ ! -e "pictures.txt" ]; then
				echo "${chapter}未找到排序文件"
			else
				pictures=`cat "pictures.txt" | grep -o "[^/]*.jpg"`
				for pic in "${pictures[@]}"; do
					echo "合并${chapter}漫画"
					convert -append ${pic} "${chapter}.jpg"
				done
			fi
			cd ..
		fi
	done
}

MergePictures ${1}

