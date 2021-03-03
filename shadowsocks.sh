#!/bin/bash

apt install shadowsocks
read -p "输入shadowsocks连接密码:\n" PASS

cat << EOF > ss.json
{
	"server": "`curl -s ip.gs`",
	"server_port": "8845",
	"password": "${PASS}",
	"timeout": 600,
	"method": "aes-256-cfb"
}
EOF
cat ss.json 
ssserver -c ss.json > /dev/null 2>&1 &
rm ss.json
