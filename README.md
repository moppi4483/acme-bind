# acme-bind

This is a docker image, contained Bind9 name server with LET'S ENCRYPT wildcase SSL certificates base on Alpine.

# How to use

If you don't need wildcase SSL certificates, you should use normal BIND9 server, like below:
```
docker run -p 53:53 -p 53:53/udp -d ventz/bind
```

More details you can read this [project](https://github.com/ventz/docker-bind). 

To get LET'S ENCRYPT SSL certificates via DNS, you need to pull and run this container, like below:
```
docker run -e DOMAIN=your.domain.tld \
-p 53:53 -p 53:53/udp \
-v your-config-dir:/etc/bind \
-v your-zone-data:/var/cache/bind \
-v certs-store-dir:/etc/letsencrypt \
-d leejoneshane/acme-bind
```

In the first time startup, SSL certificates generate may not working, becouse you should modify bind __named.conf__ first. Otherwise the certbot plugin has no permission to add TXT record into zone file for you.

please read anbd follow the log messages to do that:
```
docker logs your-container-id
```

When your modify is done, restart your container instance and try to get the SSL certificates:
```
docker exec your-container-id sh
#>rndc reload //reload named.config 
#>/entrypoint.sh your.domain.tld //generate SSL certificates
```

.If you need more SSL certificates __after__ container is running, you should run the command from console like below:
```
docker exec your-container-id www.your.domain.tld
```
