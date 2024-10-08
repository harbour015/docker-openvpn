# OpenVPN for Docker

[![Build Status](images/openvpn-github-Readme/docker-openvpn.svg)](https://travis-ci.org/kylemanna/docker-openvpn)
[![Docker Stars](images/openvpn-github-Readme/openvpn.svg+xml)](https://hub.docker.com/r/kylemanna/openvpn/)
[![Docker Pulls](images/openvpn-github-Readme/openvpn-1684038252898-1.svg+xml)](https://hub.docker.com/r/kylemanna/openvpn/)
[![ImageLayers](https://images.microbadger.com/badges/image/kylemanna/openvpn.svg)](https://microbadger.com/#/images/kylemanna/openvpn)
[![FOSSA Status](images/openvpn-github-Readme/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn.svg+xml)](https://app.fossa.io/projects/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn?ref=badge_shield)

Docker容器中的OpenVPN服务器，并配有EasyRSA PKI CA。

Extensively tested on [Digital Ocean $5/mo node](http://bit.ly/1C7cKr3) and has
a corresponding [Digital Ocean Community Tutorial](http://bit.ly/1AGUZkq).

#### Upstream Links

* Docker Registry @ [vip8/openvpn](https://hub.docker.com/r/vip8/openvpn)
* GitHub @ [harbour016/docker-openvpn](https://github.com/harbour016/docker-openvpn)

## Quick Start

* 定义`$OVPN_DATA`变量为数据卷容器名称。建议使用`ovpn-data-`前缀。

      OVPN_DATA="ovpn-data-example"

* 初始化将保存配置文件的`$OVPN_DATA`容器和证书。容器将提示输入密码短语来保护新生成的证书颁发机构使用的私钥。

      docker volume create --name $OVPN_DATA
      docker run -v $OVPN_DATA:/etc/openvpn --rm vip8/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
      docker run -v $OVPN_DATA:/etc/openvpn --rm -it vip8/openvpn ovpn_initpki

* 启动OpenVPN服务进程

      docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN vip8/openvpn

* 生成不带密码的客户端证书


      docker run -v $OVPN_DATA:/etc/openvpn --rm -it vip8/openvpn easyrsa build-client-full CLIENTNAME nopass
      # nopass 去掉这个参数，生成时提示输入密码


* 生成客户端证书和配置文件

      docker run -v $OVPN_DATA:/etc/openvpn --rm vip8/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

## docker-compose安装

### 准备docker-compose文件

```shell
cd /opt/openvpn
cat docker-compose.yaml
services:
   openvpn:
     container_name: openvpn
     image: vip8/openvpn
     environment:
       TZ: Asia/Shanghai
     volumes:
      - "./data:/etc/openvpn"
     ports:
      - '28039:1194/udp'
     cap_add:
      - NET_ADMIN
     restart: always
     privileged: true
```
>生成了docker-compose文件，先不启动


### 生成配置文件

```shell
docker-compose run --rm openvpn ovpn_genconfig -u udp://1.12.18.89
# 1.12.18.89为公网的ip地址
```


### 生成密钥文件

```shell
docker-compose run -e  EASYRSA_CRL_DAYS=3650 --rm openvpn ovpn_initpki
# EASYRSA_CRL_DAYS=3650 设置ca证书过期时间为3650天，默认Dockerfile里写的是36500
```

### 生成客户端配置文件

```shell
docker-compose run --rm openvpn easyrsa build-client-full client_name nopass
# nopass 添加此参数表示客户端证书不使用密码保护
```

### 导出客户端证书

```shell
docker-compose run --rm openvpn ovpn_getclient client_name > ./client/client_name.ovpn
# 默认情况下，没有client文件夹，需要手动创建
```

添加用户脚本

```shell
#!/bin/bash
if [ $# -ne 1 ];then
	echo "usage : $0  username"
	exit
fi

docker-compose run --rm  openvpn easyrsa build-client-full $1 nopass
#docker-compose run --rm  openvpn easyrsa build-client-full $1
docker-compose run --rm openvpn ovpn_getclient $1 > ./client/$1.ovpn
# 因为我这边外网映射的端口是28019，所以有一下修改，如果映射的是1194就不需要下面这个修改了
sed -i 's/1194/28039/g' ./client/$1.ovpn

# 可以根据情况选择是否要一下设置，默认情况下，所有流量走要走openvpn，我的需求是指定的ip段走openvpn。
# 不添加默认路由，指定ip段使用vpn转发
sed -i 's@redirect-gateway def1@#redirect-gateway def1@g' ./client/$1.ovpn
sed -i '8i\route 192.168.0.0  255.255.224.0  vpn_gateway'  ./client/$1.ovpn
sed -i '8i\route 1.1.0.0  255.255.224.0  vpn_gateway'  ./client/$1.ovpn
```
启动
```shell
docker-compose up -d
```




## Next Steps

### More Reading

Miscellaneous write-ups for advanced configurations are available in the
[docs](docs) folder.

### Systemd Init Scripts

A `systemd` init script is available to manage the OpenVPN container.  It will
start the container on system boot, restart the container if it exits
unexpectedly, and pull updates from Docker Hub to keep itself up to date.

Please refer to the [systemd documentation](docs/systemd.md) to learn more.

### Docker Compose

If you prefer to use `docker-compose` please refer to the [documentation](docs/docker-compose.md).

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

        docker run -v $OVPN_DATA:/etc/openvpn -p 1194:1194/udp --cap-add=NET_ADMIN -e DEBUG=1 vip8/openvpn

* Test using a client that has openvpn installed correctly

        $ openvpn --config CLIENTNAME.ovpn

* Run through a barrage of debugging checks on the client if things don't just work

        $ ping 8.8.8.8    # checks connectivity without touching name resolution
        $ dig google.com  # won't use the search directives in resolv.conf
        $ nslookup google.com # will use search

* Consider setting up a [systemd service](/docs/systemd.md) for automatic
  start-up at boot time and restart in the event the OpenVPN daemon or Docker
  crashes.

## How Does It Work?

Initialize the volume container using the `vip8/openvpn` image with the
included scripts to automatically generate:

- Diffie-Hellman parameters
- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key from HMAC security

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `-v` argument, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

To generate a client certificate, `vip8/openvpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environmental
variables place the PKI CA under `/etc/openvpn/pki`.

Conveniently, `vip8/openvpn` comes with a script called `ovpn_getclient`,
which dumps an inline OpenVPN client configuration file.  This single file can
then be given to a client for access to the VPN.

To enable Two Factor Authentication for clients (a.k.a. OTP) see [this document](/docs/otp.md).

## OpenVPN Details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `net30`, because it works on the widest range of OS.
`p2p`, for instance, does not work on Windows.

The UDP server uses`192.168.255.0/24` for dynamic clients by default.

The client profile specifies `redirect-gateway def1`, meaning that after
establishing the VPN connection, all traffic will go through the VPN.
This might cause problems if you use local DNS recursors which are not
directly reachable, since you will try to reach them through the VPN
and they might not answer to you. If that happens, use public DNS
resolvers like those of Google (8.8.4.4 and 8.8.8.8) or OpenDNS
(208.67.222.222 and 208.67.220.220).


## Security Discussion

The Docker container runs its own EasyRSA PKI Certificate Authority.  This was
chosen as a good way to compromise on security and convenience.  The container
runs under the assumption that the OpenVPN container is running on a secure
host, that is to say that an adversary does not have access to the PKI files
under `/etc/openvpn/pki`.  This is a fairly reasonable compromise because if an
adversary had access to these files, the adversary could manipulate the
function of the OpenVPN server itself (sniff packets, create a new PKI CA, MITM
packets, etc).

* The certificate authority key is kept in the container by default for
  simplicity.  It's highly recommended to secure the CA key with some
  passphrase to protect against a filesystem compromise.  A more secure system
  would put the EasyRSA PKI CA on an offline system (can use the same Docker
  image and the script [`ovpn_copy_server_files`](/docs/paranoid.md) to accomplish this).
* It would be impossible for an adversary to sign bad or forged certificates
  without first cracking the key's passphase should the adversary have root
  access to the filesystem.
* The EasyRSA `build-client-full` command will generate and leave keys on the
  server, again possible to compromise and steal the keys.  The keys generated
  need to be signed by the CA which the user hopefully configured with a passphrase
  as described above.
* Assuming the rest of the Docker container's filesystem is secure, TLS + PKI
  security should prevent any malicious host from using the VPN.


## Benefits of Running Inside a Docker Container

### The Entire Daemon and Dependencies are in the Docker Image

This means that it will function correctly (after Docker itself is setup) on
all distributions Linux distributions such as: Ubuntu, Arch, Debian, Fedora,
etc.  Furthermore, an old stable server can run a bleeding edge OpenVPN server
without having to install/muck with library dependencies (i.e. run latest
OpenVPN with latest OpenSSL on Ubuntu 12.04 LTS).

### It Doesn't Stomp All Over the Server's Filesystem

Everything for the Docker container is contained in two images: the ephemeral
run time image (vip8/openvpn) and the `$OVPN_DATA` data volume. To remove
it, remove the corresponding containers, `$OVPN_DATA` data volume and Docker
image and it's completely removed.  This also makes it easier to run multiple
servers since each lives in the bubble of the container (of course multiple IPs
or separate ports are needed to communicate with the world).

### Some (arguable) Security Benefits

At the simplest level compromising the container may prevent additional
compromise of the server.  There are many arguments surrounding this, but the
take away is that it certainly makes it more difficult to break out of the
container.  People are actively working on Linux containers to make this more
of a guarantee in the future.

## Differences from jpetazzo/dockvpn

* No longer uses serveconfig to distribute the configuration via https
* Proper PKI support integrated into image
* OpenVPN config files, PKI keys and certs are stored on a storage
  volume for re-use across containers
* Addition of tls-auth for HMAC security

## Originally Tested On

* Docker hosts:
  * server a [Digital Ocean](https://www.digitalocean.com/?refcode=d19f7fe88c94) Droplet with 512 MB RAM running Ubuntu 14.04
* Clients
  * Android App OpenVPN Connect 1.1.14 (built 56)
     * OpenVPN core 3.0 android armv7a thumb2 32-bit
  * OS X Mavericks with Tunnelblick 3.4beta26 (build 3828) using openvpn-2.3.4
  * ArchLinux OpenVPN pkg 2.3.4-1


## License
[![FOSSA Status](images/openvpn-github-Readme/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn-1684038252898-3.svg+xml)](https://app.fossa.io/projects/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn?ref=badge_large)
