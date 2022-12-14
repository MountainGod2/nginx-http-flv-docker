FROM lsiobase/alpine:3.16 as builder
RUN apk add --update build-base git bash gcc make g++ zlib-dev linux-headers pcre-dev openssl-dev
RUN git clone https://github.com/winshining/nginx-http-flv-module.git && \
    git clone https://github.com/nginx/nginx.git
RUN cd nginx && ./auto/configure --add-module=../nginx-http-flv-module && make && make install

FROM lsiobase/alpine:3.16 as nginx
RUN apk add --update pcre ffmpeg
COPY --from=builder /usr/local/nginx /usr/local/nginx

EXPOSE 80 443 1935
VOLUME ["/etc/nginx", "/var/cache/nginx"]

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
CMD ["-g", "daemon off;"]

COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod 444 /etc/nginx/nginx.conf
