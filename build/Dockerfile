ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as base

ARG NGINX_VERSION
ARG NJS_VERSION
ARG PKG_RELEASE

ENV NGINX_VERSION=${NGINX_VERSION}
ENV NJS_VERSION=${NJS_VERSION}
ENV PKG_RELEASE=${PKG_RELEASE}

ENV CFLAGS "-fstack-protector-strong -fpic -fpie -Wl,-O1 -O2 -Wl,--hash-style=both"
ENV CPPFLAGS "$CFLAGS"
ENV LDFLAGS "-O1 --hash-style=both"

RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && adduser -u 1000 -D -S -G www-data www-data \
    && apkArch="$(cat /etc/apk/arch)" \
    && nginxPackages=" \
        nginx=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-xslt=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-geoip=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-image-filter=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${PKG_RELEASE}" \
    && KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
    && apk add --no-cache --virtual .cert-deps openssl \
    && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
    && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
         echo "key verification succeeded!"; \
         mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
       else \
        echo "key verification failed!"; \
        exit 1; \
       fi \
    && apk del .cert-deps \
    && apk add --no-cache tzdata pcre $nginxPackages --repository "https://nginx.org/packages/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main/" \
    && apk add --no-cache --virtual .build-dev openssl-dev pcre-dev zlib-dev linux-headers  alpine-sdk \
    && tempDir="$(mktemp -d)" \
    && cd ${tempDir} \
    && curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar zxvf nginx-${NGINX_VERSION}.tar.gz \
    && git clone --recurse-submodules https://github.com/google/ngx_brotli.git \
    && cd ${tempDir}/nginx-${NGINX_VERSION}/ && ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules \
                                                                      --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log \
                                                                          --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid \
                                                        --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp \
                                        --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                                              --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                                     --with-perl_modules_path=/usr/lib/perl5/vendor_perl --user=nginx --group=nginx --with-compat --with-file-aio \
                                                --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module \
                                           --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module \
                                --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module \
                                   --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail \
                                                        --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module \
                     --with-stream_ssl_preread_module --with-cc-opt='-Os -fomit-frame-pointer -g' --with-ld-opt=-Wl,--as-needed,-O1,--sort-common \
                                                                                                               --add-module=${tempDir}/ngx_brotli \
    && make \
    && make install \
    && cd / && rm -rf ${tempDir} \
    && rm -rf /usr/sbin/*.old \
    && rm -rf /etc/nginx/*.default \
    && apk del .build-dev \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /var/cache/nginx \
    && chgrp -R root /var/cache/nginx /var/run /var/log/nginx \
    && chmod -R 770 /var/cache/nginx /var/run /var/log/nginx

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
