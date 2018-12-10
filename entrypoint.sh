#!/bin/sh

chown -R root:named /etc/bind /var/cache/bind /var/run/named
chmod -R 770 /var/cache/bind /var/run/named
chmod -R 750 /etc/bind

# generate rndc config, if not exists
if [[ ! -f /etc/letsencrypt/credentials.ini ]]; then
    rndc-confgen -A hmac-sha512 -b 512 -r /dev/urandom -k acme. > /etc/bind/rndc.conf
    sed -i "/#/d" /etc/bind/rndc.conf
    mykey=$(cat /etc/bind/rndc.conf | grep secret | sed -r 's/(\s+)secret \"(.*)\";$/\2/g')
    echo "\
    dns_rfc2136_server = 127.0.0.1
    dns_rfc2136_port = 953
    dns_rfc2136_name = acme.
    dns_rfc2136_secret = $mykey
    dns_rfc2136_algorithm = HMAC-SHA512" > /etc/letsencrypt/credentials.ini

    echo "\
controls {
    inet 127.0.0.1 port 953
    allow { 127.0.0.1; } keys { \"acme.\"; };
};" >> /etc/bind/rndc.conf

    if [ ! grep -Fxq 'include "/etc/bind/rndc.conf";' /etc/bind/named.conf ]; then
        sed -i '/options/i\include "/etc/bind/rndc.conf";' /etc/bind/named.conf
    fi
fi

# Initial certificate request, but skip if cached
if [[ "${DOMAIN}" != "server.tld" ]]; then
    if [ ! -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
        certbot certonly --dns-rfc2136 \
        --dns-rfc2136-credentials /etc/letsencrypt/credentials.ini \
        -d ${DOMAIN} \
        -d *.${DOMAIN} \
   
        cd /etc/letsencrypt
        ln -s live/*.${DOMAIN}/cert.pem cert.pem
        ln -s live/*.${DOMAIN}/chain.pem chain.pem
        ln -s live/*.${DOMAIN}/fullchain.pem fullchain.pem
        ln -s live/*.${DOMAIN}/privkey.pem privkey.pem  
   else
      certbot renew
   fi
fi

if [ -z "$1" ]; then
    # Run in foreground and log to STDERR (console):
    exec /usr/sbin/named -c /etc/bind/named.conf -g -u named
else
    for d in "$@"
    do
        certbot certonly --dns-rfc2136 \
        --dns-rfc2136-credentials /etc/letsencrypt/credentials.ini \
        --dns-rfc2136-propagation-seconds 30 \
        -d $d \
    done
fi