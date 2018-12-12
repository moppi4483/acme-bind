#!/bin/sh

chown -R root:named /etc/bind /var/cache/bind /var/run/named
chmod -R 770 /var/cache/bind /var/run/named
chmod -R 750 /etc/bind

# generate tsig key for update TXT record, if not exists
if [[ ! -f /etc/letsencrypt/credentials.ini ]]; then
    b=$(tsig-keygen -a hmac-sha512 -r /dev/urandom)
    mykey=$(echo $b | sed -r "s/(.*)secret \"(.*)\"(.*)$/\2/g")
    cat > /etc/bind/acme.key <<EOF
key "acme" {
    algorithm hmac-sha512;
    secret "$mykey";
};
EOF
    echo "\
dns_rfc2136_server = 127.0.0.1
dns_rfc2136_port = 53
dns_rfc2136_name = acme
dns_rfc2136_secret = $mykey
dns_rfc2136_algorithm = HMAC-SHA512" > /etc/letsencrypt/credentials.ini
    chmod 0600 /etc/letsencrypt/credentials.ini
    
    if [ -z $(grep -Fx 'include "/etc/bind/acme.key";' /etc/bind/named.conf) ]; then
        sed -i '/options/i\include "/etc/bind/acme.key";' /etc/bind/named.conf
    fi
    echo "\
新增以下內容到想要取得金鑰的領域組態中：
zone "${DOMAIN}" {
    type master;
    allow-update { key "acme"; };
};
或
zone "${DOMAIN}" {
    type master;
    update-policy {
        grant update subdomain ${DOMAIN}.;
    };
}
完成設定後，請重新執行容器。
"
fi

if [ -z $(ps -ef | grep named) ]; then
    exec /usr/sbin/named -c /etc/bind/named.conf -g -u named
fi

# Initial certificate request, but skip if cached
if [[ "${DOMAIN}" != "server.tld" ]]; then
    if [ ! -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
        certbot certonly --dns-rfc2136 \
        --dns-rfc2136-credentials /etc/letsencrypt/credentials.ini \
        --preferred-challenges dns-01 \
        --server https://acme-v02.api.letsencrypt.org/directory \
        --email ${EMAIL} \
        -d ${DOMAIN} \
        --agree-tos

        if [ -f /etc/letsencrypt/live/${DOMAIN}/cert.pem ]; then
            ln -s /etc/letsencrypt/live/${DOMAIN}/cert.pem /etc/letsencrypt/cert.pem
        fi
        if [ -f /etc/letsencrypt/live/${DOMAIN}/chain.pem ]; then        
            ln -s /etc/letsencrypt/live/${DOMAIN}/chain.pem /etc/letsencrypt/chain.pem
        fi
        if [ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then        
            ln -s /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /etc/letsencrypt/fullchain.pem
        fi
        if [ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then        
            ln -s /etc/letsencrypt/live/${DOMAIN}/privkey.pem /etc/letsencrypt/privkey.pem
        fi
   else
      certbot renew
   fi
fi

if [ ! -z "$1" ]; then
    certbot certonly --dns-rfc2136 \
    --dns-rfc2136-credentials /etc/letsencrypt/credentials.ini \
    --preferred-challenges dns-01 \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --email ${EMAIL} \
    -d $1 \
    --agree-tos
fi
