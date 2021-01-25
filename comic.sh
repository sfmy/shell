#!/bin/bash
comic_site="http://www.kuman55.com"
echo "漫画网站:${comic_site}"


# 搜索漫画
# comic_name 漫画名
function SearchComic {
    local comic_name=${1}
    local search_url=`curl -s "${comic_site}/search.php?keyword=${comic_name}" | \
	grep 'h2.*h2' | \
	head -n 1 | \
	grep -o 'href="[^"]*"' | \
	sed 's/href=//' | \
	sed 's/"//g'`
    [[ ! -z ${search_url} ]] && echo ${comic_site}${search_url}
}

# 获取漫画目录
# search_url 目录地址
function GetCatalog {
    local search_url=${1}
    local catalog_url=`curl -s ${search_url} | \
	grep '查看目录' | \
	grep -o 'href="[^"]*"' | \
	sed 's/href=//' | \
	sed 's/"//g'`
    catalog_url=${comic_site}${catalog_url}
    local catalog_list=(`curl -s ${catalog_url} | \
	grep 'nofollow' | \
	grep -v '_blank' | \
	sed 's/<\/li>/<\/li>\n/g' | \
	grep -o 'href="[^"]*"' | \
	sed 's/href=//' | \
	sed 's/"//g'`)
    echo ${catalog_list[@]}
}

function DownloadComic {
    local comic_name=${1}
    local search_url=`SearchComic ${comic_name}`
    GetCatalog ${search_url}
}

DownloadComic '渡劫失败都怪你'
