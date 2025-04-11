ARG SOURCE_VERSION=1.27.4
ARG DOCKER_TAG=1.27.4-debian-12-r9

FROM bitnami/nginx:${DOCKER_TAG} AS builder
USER root
## Redeclare SOURCE_VERSION so it can be used as a parameter inside this build stage
ARG SOURCE_VERSION
## Install required packages and build dependencies
RUN install_packages dirmngr gpg gpg-agent curl build-essential git \
    libpcre3-dev zlib1g-dev libperl-dev libssl-dev \
    libxml2 libxml2-dev libxslt-dev libgd-dev geoip-database libgeoip-dev
## Add trusted NGINX PGP key for tarball integrity verification
RUN gpg --keyserver keyserver.ubuntu.com --recv-key ABF5BD827BD9BF62
RUN curl -sSL https://nginx.org/keys/nginx_signing.key | gpg --import -
## Download NGINX, verify integrity and extract
RUN cd /tmp && \
    curl -O http://nginx.org/download/nginx-${SOURCE_VERSION}.tar.gz && \
    curl -O http://nginx.org/download/nginx-${SOURCE_VERSION}.tar.gz.asc && \
    # TODO: fix this
    # gpg --verify nginx-${SOURCE_VERSION}.tar.gz.asc nginx-${SOURCE_VERSION}.tar.gz && \
    tar xzf nginx-${SOURCE_VERSION}.tar.gz

RUN cd /tmp/nginx-${SOURCE_VERSION} && \
    git clone https://github.com/nginx/njs.git

## Compile NGINX with desired module
RUN cd /tmp/nginx-${SOURCE_VERSION} && \
    rm -rf /opt/bitnami/nginx && \
    ./configure --prefix=/opt/bitnami/nginx --with-compat \
    --add-dynamic-module=njs/nginx \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_perl_module=dynamic \
    --with-mail=dynamic \
    --with-stream=dynamic \
    --with-stream_geoip_module=dynamic && \
    make && \
    make install

RUN echo "load_module modules/ngx_http_js_module.so;" | cat - /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx.conf && \
    cp /tmp/nginx.conf /opt/bitnami/nginx/conf/nginx.conf

FROM bitnami/nginx:${DOCKER_TAG}
USER root
COPY --from=builder /opt/bitnami/nginx/modules/* /opt/bitnami/nginx/modules/
## Enable module
RUN install_packages libxml2
RUN mkdir -p /var/cache/nginx/emby/subs
RUN chown 1001:0 -R /var/cache/nginx/emby

RUN echo "load_module modules/ngx_http_js_module.so;" | cat - /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx.conf && \
    cp /tmp/nginx.conf /opt/bitnami/nginx/conf/nginx.conf
RUN echo "load_module modules/ngx_http_js_module.so;" | cat - /opt/bitnami/nginx/conf.default/nginx.conf > /tmp/nginx.conf && \
    cp /tmp/nginx.conf /opt/bitnami/nginx/conf.default/nginx.conf

RUN rm /tmp/nginx.conf
## Set the container to be run as a non-root user by default
USER 1001
