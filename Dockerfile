# COMPOSER
FROM composer:1.9.0 AS builder

# BASE IMAGE
FROM php:7.3-apache

# LABEL
LABEL maintainer="Abhishek Desai"

ARG SOURCE_PATH="/var/www/html"

ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# INSTALL
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        wget \
        git \
        zip \
        unzip \
        libxml2-dev \
    && docker-php-ext-install mbstring\
        opcache \
        bcmath \
        pdo \
        mysqli \
        pdo_mysql \
        soap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENABLE APACHE MODULES
RUN a2enmod rewrite

COPY entrypoint.sh /usr/local/bin/

# WORKDIR
WORKDIR ${SOURCE_PATH}

#https://docs.docker.com/develop/develop-images/multistage-build/
COPY --from=builder /usr/bin/composer /usr/local/bin/composer

# COPY composer.json and composer.lock before code for optimization
COPY composer.json composer.lock ./

# Installing dependencies from composer.json
RUN composer install --no-plugins --no-scripts --no-autoloader

# COPY source code
COPY . ${SOURCE_PATH}/

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# CLEAN UP - CREATING CACHING DIRECTORY AND PERMISSION
RUN chmod +x /usr/local/bin/entrypoint.sh ;\
    chmod -R 0755 ${SOURCE_PATH}/app/storage ;\
    chown -R www-data:www-data ${SOURCE_PATH}

EXPOSE 80

# ENTRYPOINT SETUP
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]