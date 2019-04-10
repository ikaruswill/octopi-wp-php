FROM php:7.2-fpm-alpine3.8

# install the PHP extensions we need
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		libjpeg-turbo-dev \
		libpng-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache zip; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

ADD php.ini /usr/local/etc/php/
# ADD php-fpm.conf /usr/local/etc/php-fpm.d/zz-docker.conf

ENV PHP_USER=www-data PHP_GROUP=www-data

ARG uid=1000
ARG gid=1000

RUN apk --no-cache add shadow && \
    usermod -u ${uid} www-data && \
    groupmod -g ${gid} www-data

# Setting ownership and permissions of web root
RUN mkdir /www && \
    chown $PHP_USER:$PHP_GROUP /www && \
    chmod 755 /www
WORKDIR /www

CMD ["php-fpm"]
