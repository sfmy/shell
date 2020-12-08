#!/bin/bash
PAGECOUNT=4
JSONNAME="videos.json"

function search () {
	format=$1
	filter=${2:-".*"}
	touch $JSONNAME
	[[ `cat $JSONNAME | wc -l` -eq 0 ]] && printf "{\n}" >> $JSONNAME
	gsed -i '$d' $JSONNAME # delete last line }
	[[ `cat $JSONNAME | wc -l` -gt 1 ]] && gsed -i '$s/}/},/' $JSONNAME # add , to last json item
	for ((i=1; i<$PAGECOUNT; ++i)); do
		pageurl="https://cn.pornhub.com/video/search?search=$format&page=$i"
		echo "parsing $pageurl"
		proxychains4 -q curl -s $pageurl | \
			grep "view_video.*title.*class=\"\"" | \
			grep -i "$filter" | \
			while read item; do
				url=`echo $item | grep -o "/view_video[^\"]*"`
				title=`echo $item | grep -o "title=\"[^\"]*" | sed 's/title="//'`
				viewkey=${url#*=}
				if [[ -z `grep $viewkey $JSONNAME` ]]; then
					printf "\t\"$viewkey\": { \n" >> $JSONNAME
					printf "\t\t\"url\": \"$url\", \n" >> $JSONNAME
					printf "\t\t\"title\": \"$title\", \n" >> $JSONNAME
					printf "\t\t\"download\": false \n" >> $JSONNAME
					printf "\t}, \n" >> $JSONNAME
					echo "$viewkey writed success!"
				else
					echo "$viewkey already existed!"
				fi
			done
	done
	gsed -i '$s/},/}/' $JSONNAME
	echo "}" >> $JSONNAME
}

function downitem () {
	key=$1
	if [[ `jq .$key $JSONNAME | jq length` -eq 0 ]]; then
		echo "$key doesn't exist!"
	else
		url=`jq .$key.url $JSONNAME`
		proxychains4 -q youtube-dl -c -f best "$url" -o "$key.mp4"
		lineno=`gsed -n "/\"$key\"/=" $JSONNAME`
		lineno=$((lineno+3))
		gsed -i "${lineno}s/false/true/" $JSONNAME
		echo "$key downloaded success!"
	fi
}

function download () {
	keys=(`jq -r keys[] $JSONNAME`)
	for ((i=0; i<${#keys[@]}; ++i)); do
		echo ${keys[$i]}
	done
}

search "s+cute+japan" 
download
