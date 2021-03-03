#!/bin/bash
SITE_URL="https://m.uubqg.cc"

function Usage () {
    echo "下载https://m.uubqg.cc/网站电子书"
    echo "-h|--help		帮助"
    echo "-s|--search 		搜索电子书或作者"
    echo "-o|--objective  	保存文件"
    echo "-u|--url 		文件地址"
}

function Search () {
    local name=${1}
    local tmp_file=`mktemp`
    local book_name book_type book_url book_author
    curl -s -d "searchkey=${name}" "https://m.uubqg.cc/search/" > ${tmp_file}
    echo -e "搜索结果:\n"
    while read oneline; do
	[[ -z ${book_name} ]] && \
	    book_name=`echo ${oneline} | grep "bookname" | sed 's/<[^>]*>//g'`
	[[ -n ${book_name} && -z ${book_url} ]] && \
	    book_url=`echo ${oneline} | grep "bookname" | grep -o 'a href="[^"]*"' | sed 's/a href=//' | sed 's/"//g'`
	[[ -n ${book_name} && -z ${book_author} ]] &&
	    book_author=`echo ${oneline} | grep "author" | sed 's/<[^>]*>//g'` && \
	    continue
	[[ -n ${book_name} && -n ${book_author} && -z ${book_type} ]] &&
	    book_type=`echo ${oneline} | grep "author" | sed 's/<[^>]*>//g'`
	if [[ -n ${book_name} && -n ${book_type} && -n ${book_author} && -n ${book_url} ]]; then
	    book_url="${SITE_URL}${book_url}"
	    echo -e "书名：${book_name}\n${book_author}\n${book_type}\n地址：${book_url}"
	    book_name=""; book_type=""; book_url=""; book_author=""
	    echo -e "\n"
	fi
    done < ${tmp_file}
    rm ${tmp_file}
}

function DownloadBook () {
    local book_url=${1}
    local tmp_file=`mktemp`
    curl -s ${book_url} > ${tmp_file}

    local book_name=`grep 'book_name' ${tmp_file} | grep -o 'content="[^"]*"' | sed 's/content=//' | sed 's/"//g'`
    echo "正在下载小说《${book_name}》"
    book_name="小说/${book_name}.txt"

    mkdir -p "小说" 
    [[ -f ${book_name} ]] && rm ${book_name}

    grep 'index-container' ${tmp_file} | grep -o 'value="[^"]*"' | sed 's/value=//' | sed 's/"//g' | \
	while read oneline; do
	    oneline="${SITE_URL}${oneline}"
	    DownloadPage ${oneline} ${book_name}
	done
    rm ${tmp_file}
}

function DownloadPage () {
    local page_url=${1}
    local txt_file=${2}
    local tmp_file=`mktemp`
    curl -s ${page_url} | grep -A99 '<div class="directoryArea">' > ${tmp_file}
    while read oneline; do
	[[ -z `echo ${oneline} | grep '<p>'` ]] && continue
	[[ -n `echo ${oneline} | grep '</div>'` ]] && break
	local url=`echo ${oneline} | grep -o 'href="[^"]*"' | sed 's/href=//' | sed 's/"//g'`
	local title=`echo ${oneline} | sed 's/<[^>]*>//g'`
	url="${SITE_URL}${url}"
	echo "正在下载:${url} -> ${title}"
	echo ${title} >> ${txt_file}
	DownloadChapter ${url} ${txt_file}
    done < ${tmp_file}
    rm ${tmp_file}
}

function DownloadChapter () {
    local url=${1}
    local txt_file=${2}
    local tmp_file=`mktemp`
    curl -s ${url} > ${tmp_file}
    grep '<p>' ${tmp_file} | sed 's/<\/p>/<\/p>\n/g' | sed 's/<p>//g' | sed 's/<\/p>//g' | grep -v -i 'uubqg' | grep -v '\-\->' | grep -v '<!\-\-' >> ${txt_file}
    local next_page=`grep 'Readpage_up.*下一页' ${tmp_file} | grep -o 'href="[^"]*"' | sed 's/href=//' | sed 's/"//g' | head -n 1`
    rm ${tmp_file}
    if [[ -n ${next_page} ]]; then
	next_page="${SITE_URL}${next_page}"
	DownloadChapter ${next_page} ${txt_file}
    fi
}

function Main () {
    [[ $# -eq 0 ]] && Usage && exit
    local search_name save_file book_url
    while [[ -n ${1} ]]; do
	case ${1} in
	    -s|--search)
		search_name=${2}
		shift 2
		;;
	    -o|--objective)
		save_file=${2}
		shift 2
		;;
	    -u|--url)
		book_url=${2}
		shift 2
		;;
	    *)
		Usage && exit
		;;
	esac
    done
    if [[ -n ${search_name} ]]; then
	Search ${search_name} && exit
    fi
    if [[ -n ${book_url} ]]; then
	DownloadBook ${book_url} ${save_file}
    fi
}

Main $@
