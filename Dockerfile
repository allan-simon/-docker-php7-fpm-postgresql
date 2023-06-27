FROM php:8.1-fpm
# Install modules
RUN buildDeps="libpq-dev libzip-dev libicu-dev libpng-dev libjpeg-dev libfreetype6-dev libmagickwand-dev libxslt-dev wget unzip git yarn libssl-dev aptitude autoconf libtool make libc-client-dev libkrb5-dev" &&\
    apt-get update && \
    apt-get install -y gnupg2 && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get install -y $buildDeps --no-install-recommends && \
    apt remove -y curl && apt purge curl && \
    rm -rf /usr/local/include/curl && \
    rm -r /var/lib/apt/lists/* && \
    # Install cURL version 7.88.1 as it's not compatible with the latest version
    # of OpenSSL. See: https://stackoverflow.com/a/75867650
    cd /tmp && rm -rf curl* && \
    wget https://curl.haxx.se/download/curl-7.88.1.zip && \
    unzip curl-7.88.1.zip && cd curl-7.88.1 && \
    ./buildconf && ./configure --with-ssl && \
    make && make install && \
    cp /usr/local/bin/curl /usr/bin/curl && \
    # Fix the LDD link issue: https://github.com/curl/curl/issues/4448
    # We do this because removing the old cURL version did not remove its libraries
    # and the new cURL version is first loading these one instead of the new ones
    rm -rf /usr/lib/`uname -p`-linux-gnu/libcurl.so* && ldconfig && \
    # install imagick
    # use github version for now until release from https://pecl.php.net/get/imagick is ready for PHP 8
    # see: https://github.com/Imagick/imagick/issues/358#issuecomment-768586107
    mkdir -p /usr/src/php/ext/imagick; \
    curl -fsSL https://github.com/Imagick/imagick/archive/06116aa24b76edaf6b1693198f79e6c295eda8a9.tar.gz | tar xvz -C "/usr/src/php/ext/imagick" --strip 1; \
    ln -s /usr/lib/x86_64-linux-gnu/ImageMagick-6.8.9/bin-Q16/MagickWand-config /usr/bin && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install \
        opcache \
        pdo \
        pdo_pgsql \
        pgsql \
        sockets \
        xsl \
        imap \
        sysvsem \
        bcmath \
        intl && \
    echo 'memory_limit = -1' > /usr/local/etc/php/conf.d/gitlab-ci.ini && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["php-fpm"]
