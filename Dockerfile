FROM ventz/bind

ENV DOMAIN server.tld
ENV EMAIL your@mail.addr

ADD entrypoint.sh /entrypoint.sh
RUN apk update  \
    && apk add --no-cache bind-tools py-pip certbot acme-client openssl ca-certificates \
    && rm -rf /var/cache/apk/* \
    && pip install --upgrade pip \
    && pip install certbot-dns-rfc2136 \
    && chmod 711 /entrypoint.sh

VOLUME ["/etc/letsencrypt", "/etc/bind", "/var/cache/bind"]
EXPOSE 53 53/udp
CMD ["/entrypoint.sh"]
