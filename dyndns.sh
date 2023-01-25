#!/bin/sh

key="acme"
secret="WSZFYQcJVAAiH7FrkayQQqqJkmBeL6mifM/8JCmvn6rB0bbyGzFOKdVh6l62/OdZU/LyyhOyy6p28qnJLKW4iA=="

FILE="/extIP"

ip=$(curl ipecho.net/plain)

if [ -f "$FILE" ]; then
    while read line 
    do 
        oldIP=$line
    done < $FILE

    echo "alte externe IP: " $oldIP
    echo "neue externe IP: " $ip

    if [ "$ip" = "$oldIP" ]; then
        echo "keine Änderung der externen IP - keine weiteren Aktionen..."
        exit 0;
    fi
fi

echo "Aktualisierung der externen IP..."

nsupdate -y hmac-sha512:$key:$secret <<EOF
server localhost
update delete dyndns.$DOMAIN A
update add dyndns.$DOMAIN 180 A $ip
send
EOF

echo $ip > $FILE
