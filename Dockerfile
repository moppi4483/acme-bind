FROM ventz/bind

ENV DOMAIN server.tld

ADD entrypoint.sh /entrypoint.sh
RUN apk update  \
    && apk add --no-cache py-pip certbot acme-client openssl ca-certificates \
    && rm -rf /var/cache/apk/* \
    && pip install --upgrade pip \
    && pip install ceretbot-dns-rfc2136 \
    && chmod 711 /entrypoint.sh

VOLUME ["/etc/letsencrypt", "/etc/bind", "/var/cache/bind"]
EXPOSE 53 53/udp
CMD ["/entrypoint.sh"]
