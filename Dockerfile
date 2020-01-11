FROM wodby/php:7.3

USER root

RUN set -eux; \
	\
	apk add --no-cache --virtual .fetch-deps gnupg; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	curl -fsSL -o php.tar.xz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	if [ -n "$PHP_MD5" ]; then \
		echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apk del --no-network .fetch-deps

RUN set -xe; \
    \
    # yaf.
    mkdir -p /usr/src/php/ext/yaf; \
    yaf_url="http://pecl.php.net/get/yaf-3.0.8.tgz"; \
    wget -qO- "${yaf_url}" | tar xz --strip-components=1 -C /usr/src/php/ext/yaf; \
    docker-php-ext-configure yaf; \
    docker-php-ext-install yaf; \
    \
    rm -rf \
        /usr/src/php/ext/yaf \
        /usr/include/php \
        /usr/lib/php/build \
        /tmp/* \
        /root/.composer \
        /var/cache/apk/*; 

COPY config/docker-php-ext-yaf.ini $PHP_INI_DIR/conf.d/

USER wodby
