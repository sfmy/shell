#!/bin/bash 
PAGECOUNT=20
JSONNAME="videos.json"

# @param1 json '{ "keyword": "final fantasy", "filter": "final fantasy", "hd": 1 }'
function search () {
	keyword=`echo $1 | jq -r .keyword | sed 's/-/+/g' | sed 's/ /+/g'`
	[[ -n `echo $1 | jq .hd` ]] && keyword=$keyword"&hd=1"
	filter=`echo $1 | jq -r .filter`
	filter=${filter:-".*"}
	touch $JSONNAME
	[[ `cat $JSONNAME | wc -l` -eq 0 ]] && printf "{\n}" >> $JSONNAME
	gsed -i '$d' $JSONNAME # delete last line }
	[[ `cat $JSONNAME | wc -l` -gt 1 ]] && gsed -i '$s/}/},/' $JSONNAME # add , to last json item
	for ((i=1; i<=$PAGECOUNT; ++i)); do
		pageurl="https://cn.pornhub.com/video/search?search=$keyword&page=$i"
		echo "parsing $pageurl"
		proxychains4 -q curl -s $pageurl | \
			grep -E "\"duration\"|view_video.*title.*class=\"\"|\"views\"|\"value\"" \
			> tmp

		url=""; title=""; duration=""; views=""
		cat tmp | \
			grep -i "$filter" -A 2 -B 1 | \
			grep "view_video" -A 2 -B 1 | \
			while read item; do
				[[ -n `echo $item | grep "duration" | grep -o -E "\d*:\d*|\d*:\d*:\d*"` ]] && 
				       	duration=`echo $item | grep "duration" | grep -o -E "\d*:\d*|\d*:\d*:\d*"`
				[[ -n `echo $item | grep -o "/view_video[^\"]*"` && -n $duration ]] && \
				       	url=`echo $item | grep -o "/view_video[^\"]*"`
				[[ -n `echo $item | grep -o "title=\"[^\"]*" | sed 's/title="//'` && -n $duration ]] && \
				       	title=`echo $item | grep -o "title=\"[^\"]*" | sed 's/title="//'`
				[[ -n `echo $item | grep -o "\d\+\.\d\+[KMG]*"` && -n $url ]] && \
					views=`echo $item | grep -o "\d\+\.\d\+[KMG]*"`
				[[ -n `echo $item | grep -o "\d\+%" | sed 's/%//'` && -n $views ]] && \
					value=`echo $item | grep -o "\d\+%" | sed 's/%//'`
				if [[ -n $url && -n $title && -n $duration && -n $views  && -n $value ]]; then
					viewkey=${url#*=}
					if [[ -z `grep $viewkey $JSONNAME` ]]; then
						printf "\t\"$viewkey\": { \n" >> $JSONNAME
						printf "\t\t\"url\": \"$url\", \n" >> $JSONNAME
						printf "\t\t\"title\": \"$title\", \n" >> $JSONNAME
						printf "\t\t\"duration\": \"$duration\", \n" >> $JSONNAME
						printf "\t\t\"views\": \"$views\", \n" >> $JSONNAME
						printf "\t\t\"value\": \"$value\", \n" >> $JSONNAME
						printf "\t\t\"download\": false \n" >> $JSONNAME
						printf "\t}, \n" >> $JSONNAME
						echo "$viewkey writed success!"
					else
						echo "$viewkey already existed!"
					fi
					url=""; title=""; duration=""; views=""; value=""
				fi

			done
	done
	gsed -i '$s/},/}/' $JSONNAME
	echo "}" >> $JSONNAME
	rm tmp
}

function downitem () {
	key=$1
	if [[ `jq ".\"$key\"" $JSONNAME | jq length` -eq 0 ]]; then
		echo "$key doesn't exist!"
	elif [[ `jq ".\"$key\".download" $JSONNAME` = "true" ]]; then
		echo "$key already downloaded!"
	else
		url="https://cn.pornhub.com"`jq -r ".\"$key\".url" $JSONNAME`
		echo "downloading $url"
		proxychains4 -q youtube-dl -f best -c "$url" -o "$key.mp4"  --external-downloader aria2c --external-downloader-args "-x 15"
		if [[ $? -eq 0 ]]; then
			lineno=`gsed -n "/\"$key\"/=" $JSONNAME`
			lineno=$((lineno+6))
			gsed -i "${lineno}s/false/true/" $JSONNAME
			echo "$key downloaded success!"
		fi
	fi
}

function getnum () {
	str=$1
	len=$((${#str}-1))
	num=${str: 0: $len}
	unit=${str: -1}
	case $unit in
		[Kk]) num=`echo "$num * 1000" | bc` ;;
		[Mm]) num=`echo "$num * 1000 * 1000" | bc` ;;
		[Gg]) num=`echo "$num * 1000 * 1000 * 1000" | bc` ;;
	esac
	echo $num
}

function gettm () {
	tm=$1
	len=${#tm}
	second="0"; minuter="0"; hour="0"
	[[ $len -ge 2 ]] && second=${tm: $((len-2)):2}
	[[ $len -ge 4 ]] && minuter=${tm: $((len-5)):2}
	[[ $len -ge 7 ]] && hour=${tm: $((len-8)):2}
	echo "$hour*60*60+$minuter*60+$second" | bc
}

function verify () {
	filter=$1
	item=$2
	result="false"
	if [[ -n `echo $filter | jq -r .views` ]]; then
		num1=$(getnum `echo $filter | jq -r .views`)
		num2=$(getnum `echo $item | jq -r .views`)
		if [[ `echo "$num1 > $num2" | bc` -eq 1 ]]; then
			result="false"
		fi
	fi
	if [[ -n `echo $filter | jq -r .value` ]]; then
		num1=`echo $filter | jq -r .value`
		num2=`echo $item | jq -r .value`
		if [[ $num1 -gt $num2 ]]; then
			result="false"
		fi
	fi
	if [[ -n `echo $filter | jq -r .min_duration` ]]; then
		num1=$(gettm `echo $filter | jq -r .min_duration`)
		num2=$(gettm `echo $item | jq -r .duration`)
		if [[ `echo "$num1 > $num2" | bc` -eq 1 ]]; then
			result="false"
		fi
	fi
	if [[ -n `echo $filter | jq -r .max_duration` ]]; then
		num1=$(gettm `echo $filter | jq -r .max_duration`)
		num2=$(gettm `echo $item | jq -r .duration`)
		if [[ `echo "$num1 < $num2" | bc` -eq 1 ]]; then
			result="false"
		fi
	fi
	echo "true"
}

function download () {
	filter=$1
	keys=(`jq -r keys[] $JSONNAME`)
	for ((i=0; i<${#keys[@]}; ++i)); do
		item=`jq -r .\"${keys[$i]}\" $JSONNAME`
		if [[ `verify "$filter" "$item"` = "true" ]]; then
			downitem ${keys[$i]} 
		fi
	done
}

# search '{ "keyword": "final fantasy", "hd": 1, "filter": "final fantasy" }'
download '{ "views": "20K", "value": 85 }'
