# Default Dockerfile
#
# @link     https://www.hyperf.io
# @document https://doc.hyperf.io
# @contact  group@hyperf.io
# @license  https://github.com/hyperf-cloud/hyperf/blob/master/LICENSE

FROM  hyperf/hyperf:7.4-alpine-v3.11-cli
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    APP_ENV=prod \
    SCAN_CACHEABLE=(true) \
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libstdc++ openssl git bash libc-dev make  php7-dev php7-pear pkgconf re2c pcre-dev zlib-dev libtool automake pcre pcre2-dev"

RUN apk --no-cache upgrade \
      &&  apk add --no-cache  $PHPIZE_DEPS libaio-dev

#RUN apk update \
#    && git clone --depth 1 --branch v1.4.0 https://github.com/edenhill/librdkafka.git \
#       && cd librdkafka \
#       && ./configure \
#       && make \
#       && make install

RUN apk add --no-cache librdkafka-dev

RUN pecl channel-update pecl.php.net \
    && pecl install rdkafka-4.0.3 \
    && echo "extension=rdkafka.so" > /etc/php7/php.ini \
    && apk del $PHPIZE_DEPS

RUN set -ex \
    && apk update \
    # install composer
    && cd /tmp \
    && wget https://github.com/composer/composer/releases/download/1.8.6/composer.phar \
    && chmod u+x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    # show php version and extensions
    && php -v \
    && php -m \
    #  ---------- some config ----------
    && cd /etc/php7 \
    # - config PHP
    && { \
        echo "upload_max_filesize=100M"; \
        echo "post_max_size=108M"; \
        echo "memory_limit=1024M"; \
        echo "date.timezone=Asia/Shanghai"; \
    } | tee conf.d/99-overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"


WORKDIR /var/www

EXPOSE 9501

ENTRYPOINT ["php", "bin/hyperf.php","start"]
