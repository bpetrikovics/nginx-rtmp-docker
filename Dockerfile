ARG NGINX_VERSION=1.21.6
ARG NGINX_RTMP_VERSION=1.2.2

# First stage - builder

FROM debian:bullseye-slim AS builder

# Re-declare these ARGS so they can be available after the FROM
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

USER root

RUN apt update && apt -y upgrade && apt -y install \
    curl \
    build-essential \
    libpcre3-dev \
    libssl-dev \
    zlib1g-dev

WORKDIR /build

RUN curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xvzf nginx-${NGINX_VERSION}.tar.gz

RUN curl -LO https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_VERSION}.tar.gz && \
    tar xvzf v${NGINX_RTMP_VERSION}.tar.gz

WORKDIR /build/nginx-${NGINX_VERSION}

RUN ./configure --prefix=/opt/nginx \
    --add-dynamic-module=../nginx-rtmp-module-${NGINX_RTMP_VERSION} \
    --with-compat && make && make install


# Second stage - extend the factory nginx image

FROM nginx:${NGINX_VERSION}

ARG NGINX_RTMP_VERSION

COPY --from=builder /opt/nginx/modules/ngx_rtmp_module.so /usr/lib/nginx/modules/
COPY --from=builder /build/nginx-rtmp-module-${NGINX_RTMP_VERSION}/stat.xsl /var/www/rtmp/

RUN echo "load_module modules/ngx_rtmp_module.so;" | cat - /etc/nginx/nginx.conf > /tmp/nginx.conf && \
    cp /tmp/nginx.conf /etc/nginx/nginx.conf
