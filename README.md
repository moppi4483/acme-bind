# acme-bind

This is a docker image, contained Bind9 name server with LET'S ENCRYPT wildcase SSL certificates base on Alpine.

# How to use

If you don't need wildcase SSL certificates, you should use normal BIND9 server, like below:
```
docker run -p 53:53 -p 53:53/udp -d ventz/bind
```

More detail you can read this [documents](https://github.com/ventz/docker-bind). 

To get LET'S ENCRYPT SSL certificates via DNS, you need to pull and run this container, like below:
```
docker run -e DOMAIN=your.domain.tld \
-p 53:53 -p 53:53/udp \
-v your-config-dir:/etc/bind \
-v your-zone-data:/var/cache/bind \
-v certs-store-dir:/etc/letsencrypt \
-d leejoneshane/acme-bind
```

If you need more SSL certificates __after__ container is running, you should run the command from console like below:
```
docker exec your-container-id www.your.domain.tld www2.your.domain.tld
```