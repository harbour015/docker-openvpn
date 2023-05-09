# 使用的镜像
FROM alpine:latest

LABEL maintainer="Li qinghai <61864003@qq.com>"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester libqrencode && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# 需要的脚本
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

# 内部使用的端口是1194/udp,可以使用`docker run -p 443:1194/tcp`重新映射
EXPOSE 1194/udp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# 使用PAM模块，添加对otp身份验证的支持
# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
