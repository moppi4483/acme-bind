FROM alpine:latest

ENV DOMAIN server.tld
ENV EMAIL your@mail.addr

ADD entrypoint.sh /entrypoint.sh
RUN apk update  \
    && apk add --no-cache bind bind-tools py-pip certbot acme-client openssl ca-certificates \
    && rm -rf /var/cache/apk/* \
    && mkdir -m 0770 -p /etc/bind && chown -R root:named /etc/bind \
    && mkdir -m 0770 -p /var/cache/bind && chown -R root:named /var/cache/bind \
    && wget -q -O /etc/bind/bind.keys https://ftp.isc.org/isc/bind9/keys/9.11/bind.keys.v9_11 \
    && rndc-confgen -a -r /dev/urandom \
    && pip install --upgrade pip \
    && pip install certbot-dns-rfc2136 \
    && echo "0 5 1 * * /usr/bin/certbot renew --no-self-upgrade" > /etc/crontabs/root \
    && chmod 711 /entrypoint.sh

VOLUME ["/etc/letsencrypt", "/etc/bind", "/var/cache/bind"]
EXPOSE 53 53/udp
CMD ["/entrypoint.sh"]
