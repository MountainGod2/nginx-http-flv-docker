FROM lsiobase/alpine:3.16 as builder
RUN apk add --update build-base git bash gcc make g++ zlib-dev linux-headers pcre-dev openssl-dev
RUN git clone https://github.com/winshining/nginx-http-flv-module.git && \
    git clone https://github.com/nginx/nginx.git
RUN cd nginx && ./auto/configure --add-module=../nginx-http-flv-module && make && make install

FROM lsiobase/alpine:3.16 as nginx
RUN apk add --update pcre ffmpeg

COPY --from=builder /usr/local/nginx /usr/local/nginx

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
EXPOSE 80 443 1935

VOLUME ["/etc/nginx", "/var/cache/nginx"]

# Set up entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 555 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []

# Set up config file
COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod 444 /etc/nginx/nginx.conf
