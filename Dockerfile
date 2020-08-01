FROM nginx:1-alpine as builder

# ENV NGINX_VERSION 1.16.0 # defined in the base image
ENV NGX_BROTLI_VERSION 0.1.2
ENV BROTLI_VERSION 1.0.7

RUN set -x \
    && mkdir -p /usr/src \
# dowload and extract source files
    && wget -qO- https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar xzf - -C /usr/src \
    && wget -qO- https://github.com/eustas/ngx_brotli/archive/v$NGX_BROTLI_VERSION.tar.gz | tar xzf - -C /usr/src \
    && wget -qO- https://github.com/google/brotli/archive/v$BROTLI_VERSION.tar.gz | tar xzf - -C /usr/src \
# ngx_brotli needs brotli files under its deps/brotli directory
    && rm -rf /usr/src/ngx_brotli-$NGX_BROTLI_VERSION/deps/brotli/ \
    && ln -s /usr/src/brotli-$BROTLI_VERSION /usr/src/ngx_brotli-$NGX_BROTLI_VERSION/deps/brotli \
# install packages needed to build nginx and ngx_brotli
    && apk add --no-cache \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg1 \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        perl-dev \
    && cd /usr/src/nginx-$NGINX_VERSION \
# extract original nginx build arguments and append ngx_brotli as dynamic module
    && CNF="$(2>&1 nginx -V | sed -n 's/^configure arguments: //p') --add-dynamic-module=../ngx_brotli-$NGX_BROTLI_VERSION" \
# build modules
    && ./configure $CNF \
    && make modules

# copy built modules to a new clean image
FROM nginx:1-alpine

COPY --from=builder /usr/src/nginx-$NGINX_VERSION/objs/ngx_http_brotli_*_module.so /usr/lib/nginx/modules/
