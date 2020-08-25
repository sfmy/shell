filename="书剑春秋.txt"
> ${filename}
for ((i=1; i<=225; ++i)); do
	echo "下载第${i}章"
	url="http://www.my2852.com/wuxia/zgqy/sjcq/${i}.htm"
	curl -s ${url} | iconv -f cp936 -t utf-8 | grep '<br /><br />' | sed 's/<br \/>//g' | gsed 's/^\s*//g' >> ${filename}
done
