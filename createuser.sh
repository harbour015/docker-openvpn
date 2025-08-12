#!/bin/bash
if [ $# -ne 1 ];then
	echo "usage : $0  username"
	exit
fi


docker compose run --rm  openvpn easyrsa build-client-full $1 nopass
# docker compose run --rm  openvpn easyrsa build-client-full $1
docker compose run --rm openvpn ovpn_getclient $1 > ./client/$1.ovpn
sed -i 's/1194/28039/g' ./client/$1.ovpn


# 下面的选项，按照自己的需求启用
# 不添加默认路由，指定ip段使用vpn转发
sed -i 's@redirect-gateway def1@#redirect-gateway def1@g' ./client/$1.ovpn
sed -i '7i\route-nopull'  ./client/$1.ovpn
sed -i '7i\comp-lzo no'  ./client/$1.ovpn
# sed -i '8i\route 192.168.0.0  255.255.224.0  vpn_gateway'  ./client/$1.ovpn
# sed -i '8i\route 1.1.0.0  255.255.224.0  vpn_gateway'  ./client/$1.ovpn
