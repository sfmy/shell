#!/bin/bash
echo "redis集群配置脚本"

mkdir -p redis-cluster
dir_list=("7000" "7001" "7002" "7003" "7004" "7005")

for item in ${dir_list[@]}; do
	mkdir -p "redis-cluster/${item}"
	echo "port ${item}\ncluster-enabled yes\ncluster-config-file nodes-${item}.conf\ncluster-node-timeout 5000\nappendonly yes\ndaemonize yes\n" > "redis-cluster/${item}/redis.conf"
done

echo "\
#!/bin/bash
redis-server ./7000/redis.conf
redis-server ./7001/redis.conf
redis-server ./7002/redis.conf
redis-server ./7003/redis.conf
redis-server ./7004/redis.conf
redis-server ./7005/redis.conf
redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1
" > redis-cluster/run-redis-cluster.sh
