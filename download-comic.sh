#!/bin/bash
echo '下载https://18comic.vip网站的漫画'

function DownloadKoreaComic () {
    local comic_name=${1}
    local comic_url=${2}
    local json_file="${comic_name}/${comic_name}.json"
    GenerateJsonFile ${comic_name} ${comic_url} ${json_file}
    DownladAllChapter ${comic_name} ${json_file}
}

function GenerateJsonFile () {
    local comic_name=${1}
    local comic_url=${2}
    local json_file=${3}
    echo "开始解析《${comic_name}》章节信息"
    local chapter_url_list=(`proxychains4 -q curl -s "${comic_url}" | \
	grep -B 4 'class="hidden-xs" style="float: right;"' | \
	grep 'href' | \
	grep -o '".*"' | \
	sed 's/"//g'`)

    mkdir -p ${comic_name}; > ${json_file}

    [[ `cat "${json_file}" | wc -l` -eq 0 ]] && echo "{\n}" > ${json_file}

    for ((i=0; i<${#chapter_url_list[@]}; ++i)); do
	local chapter_url="https://18comic.vip${chapter_url_list[${i}]}"
	local title="第$((i+1))话"
	if [[ -z `grep "${chapter_url}" ${json_file}` ]]; then
	    if [[ `jq -r ".\"${title}\"" ${json_file}` != "null" ]]; then
		echo "《${comic_name}》覆盖${title}"
		continue
	    fi
	    local json_content="{ \"url\": \"${chapter_url}\", \"download\": false }"
	    local add_content=".\"${title}\"=\$arg"
	    local final_content=`jq -r --argjson arg "${json_content}" "${add_content}" ${json_file}`
	    echo ${final_content} | jq . > ${json_file}
	    echo "《${comic_name}》${title}写入json文件信息${json_content}"
	fi
    done
}

function DownladAllChapter () {
    local comic_name=${1}
    local json_file=${2}
    local chapter_key_list=(`jq -r 'keys[]' ${json_file}`)
    for ((i=0; i<${#chapter_key_list[@]}; ++i)); do
	local chapter_key=${chapter_key_list[${i}]}
	DownOneChapter ${comic_name} ${chapter_key} ${json_file}
    done
}

function DownOneChapter () {
    local comic_name=${1}
    local chapter_key=${2}
    local json_file=${3}
    mkdir -p ${comic_name}/${chapter_key}
    local jpg_file="${comic_name}/${chapter_key}/pictures.txt"
    local chapter_url=`jq -r ".\"${chapter_key}\".\"url\"" ${json_file}`
    if [[ ! -f ${jpg_file} || `cat ${jpg_file} | wc -l` -eq 0 ]]; then
	echo "解析《${comic_name}》${chapter_key}"
	match=`echo ${chapter_url} | sed 's/photo/photos/' | grep -o '/photos/\d*'`
	proxychains4 -q curl -s "${chapter_url}" | \
	    grep ${match} | \
	    grep 'jpg' | \
	    grep -o '"[^"]*"' | \
	    grep ${match} | \
	    sed 's/"//g' > ${jpg_file}
    fi
    if [[ `cat ${jpg_file} | wc -l` -eq 0 ]]; then
	echo "解析《${comic_name}》${chapter_key}网络错误!"
	return
    fi
    cat ${jpg_file} | \
	while read item; do
	    jpg_file_name="${comic_name}/${chapter_key}/"`echo ${item} | grep -o '\d*.jpg'`
	    if [[ -f "${jpg_file_name}" ]]; then
		continue
	    fi
	    proxychains4 -q aria2c ${item} -d ${comic_name}/${chapter_key}
	    if [[ `identify -verbose ${jpg_file_name} 2>&1 | grep 'Corrupt' | wc -l` -ne 0 ]]; then
		rm ${jpg_file_name}
	    fi
	done 
    if [[ `cat ${jpg_file} | wc -l` -eq `ls ${comic_name}/${chapter_key}/*.jpg | wc -l` ]]; then
	local replace_content=".\"${chapter_key}\".\"download\"=\"true\""
	local final_content=`jq -r "${replace_content}" ${json_file}`
	echo ${final_content} | jq . > ${json_file}
	echo "《${comic_name}》${chapter_key}下载完成!"
    fi
}

function DownloadOneComic () {
    local comic_name=${1}
    local comic_url=${2}
    mkdir -p ${comic_name}
    local jpg_file="${comic_name}/pictures.txt"
    if [[ ! -f ${jpg_file} || `cat ${jpg_file} | wc -l` -eq 0 ]]; then
	echo "解析《${comic_name}》!"
	proxychains4 -q curl -s "${comic_url}" | \
	    grep 'photos.*jpg' | \
	    grep -o '"[^"]*"' | \
	    grep 'photos' | \
	    sed 's/"//g' > ${jpg_file}
    fi
    if [[ `cat ${jpg_file} | wc -l` -eq 0 ]]; then
	echo "解析《${comic_name}》网络错误!"; return
    fi
    cat ${jpg_file} | \
	while read item; do
	    local jpg_name=`echo $item | grep -o '\d*.jpg'`
	    if [[ ! -f "${comic_name}/${jpg_name}" ]]; then
		proxychains4 -q aria2c ${item} -d ${comic_name}
		if [[ `identify -verbose ${jpg_file} 2>&1 | grep 'Corrupt' | wc -l` -ne 0 ]]; then
		    rm ${jpg_name}
		fi
	    fi
	done 
    if [[ `cat ${jpg_file} | wc -l` -eq `ls ${comic_name}/*.jpg | wc -l` ]]; then
	echo "《${comic_name}》下载完成!"
    else
	echo "《${comic_name}》下载失败!"
    fi
}

function CorrectFold () {
    local fold=${1}
    ls ${fold}/*.jpg | \
	while read item; do
	    CorrectFile ${item}
	done
}

function CorrectFile () {
    local file=${1}
    local size=`identify $file | awk '{print $3}'`
    local width=${size%x*}
    local height=${size#*x}
    local cropheight=$((height/10))
    local y=0
    for ((i=0; i<10; ++i)); do
	if [[ $i -ne 9 ]]; then
	    convert -crop ${width}x${cropheight}+0+${y} ${file} "tmp-${i}.jpg"
	    y=$((y+cropheight))
	else
	    cropheight=$(($height-9*$cropheight))
	    convert -crop ${width}x${cropheight}+0+${y} ${file} "tmp-${i}.jpg"
	fi
    done
    convert -append tmp-9.jpg tmp-8.jpg tmp-7.jpg tmp-6.jpg tmp-5.jpg tmp-4.jpg tmp-3.jpg tmp-2.jpg tmp-1.jpg tmp-0.jpg ${file}
    rm tmp-9.jpg tmp-8.jpg tmp-7.jpg tmp-6.jpg tmp-5.jpg tmp-4.jpg tmp-3.jpg tmp-2.jpg tmp-1.jpg tmp-0.jpg
    echo "CorrectFile ${file}"
}

# DownloadOneComic '雨后的我们' 'https://18comic.vip/photo/230658/'
