# Dockerfile for a simple Nginx stream replicator

# Separate build stage to keep build dependencies out of our final image
ARG ALPINE_VERSION=alpine:3.8
FROM ${ALPINE_VERSION}

# Software versions to build
ARG NGINX_VERSION=nginx-1.2.6
ARG NGINX_HTTP_FLV_MODULE_VERSION=4e12f45427d8ca15c1328b71baed757f8d852013

# Install buildtime dependencies
# Note: We build against LibreSSL instead of OpenSSL, because LibreSSL is already included in Alpine
RUN apk --no-cache add build-base libressl-dev

# Download sources
RUN mkdir -p /build && \
    wget -O - https://nginx.org/download/${NGINX_VERSION}.tar.gz | tar -zxC /build -f - && \
    mv /build/${NGINX_VERSION} /build/nginx && \
    wget -O - https://github.com/winshining/nginx-http-flv-module/archive/${NGINX_HTTP_FLV_MODULE_VERSION}.tar.gz | tar -zxC /build -f - && \
    mv /build/nginx-http-flv-module-${NGINX_HTTP_FLV_MODULE_VERSION} /build/nginx-http-flv-module

# Build a minimal version of nginx
RUN cd /build/nginx && \
    ./configure \
        --build=MountainGod2/nginx-http-flv-docker \
        --prefix=/etc/nginx \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=/tmp/nginx/client-body \
        --user=nginx --group=nginx \
        --without-http-cache \
        --without-http_access_module \
        --without-http_auth_basic_module \
        --without-http_autoindex_module \
        --without-http_browser_module \
        --without-http_charset_module \
        --without-http_empty_gif_module \
        --without-http_fastcgi_module \
        --without-http_geo_module \
        --without-http_grpc_module \
        --without-http_gzip_module \
        --without-http_limit_conn_module \
        --without-http_limit_req_module \
        --without-http_map_module \
        --without-http_memcached_module \
        --without-http_mirror_module \
        --without-http_proxy_module \
        --without-http_referer_module \
        --without-http_rewrite_module \
        --without-http_scgi_module \
        --without-http_split_clients_module \
        --without-http_ssi_module \
        --without-http_upstream_hash_module \
        --without-http_upstream_ip_hash_module \
        --without-http_upstream_keepalive_module \
        --without-http_upstream_least_conn_module \
        --without-http_upstream_random_module \
        --without-http_upstream_zone_module \
        --without-http_userid_module \
        --without-http_uwsgi_module \
        --without-mail_imap_module \
        --without-mail_pop3_module \
        --without-mail_smtp_module \
        --without-pcre \
        --without-poll_module \
        --without-select_module \
        --without-stream_access_module \
        --without-stream_geo_module \
        --without-stream_limit_conn_module \
        --without-stream_map_module \
        --without-stream_return_module \
        --without-stream_split_clients_module \
        --without-stream_upstream_hash_module \
        --without-stream_upstream_least_conn_module \
        --without-stream_upstream_random_module \
        --without-stream_upstream_zone_module \
        --with-ipv6 \
        --add-module=/build/nginx-http-flv-module && \
    make -j $(getconf _NPROCESSORS_ONLN)

# Final image stage
FROM ${ALPINE_VERSION}

# Set up group and user
RUN addgroup -S nginx && \
    adduser -s /sbin/nologin -G nginx -S -D -H nginx

# Set up directories
RUN mkdir -p /etc/nginx /var/log/nginx /var/www && \
    chown -R nginx:nginx /var/log/nginx /var/www && \
    chmod -R 775 /var/log/nginx /var/www

# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up exposed ports
EXPOSE 1935

# Set up entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 555 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []

# Copy files from build stage
COPY --from=0 /build/nginx/objs/nginx /usr/local/sbin/nginx
RUN chmod 550 /usr/local/sbin/nginx

# Set up config file
COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod 444 /etc/nginx/nginx.conf
