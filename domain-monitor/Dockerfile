FROM php:8.3-apache-bookworm AS runtime_base

RUN apt-get update && apt-get install -y --no-install-recommends \
      libicu-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
      libxml2-dev libcurl4-openssl-dev libonig-dev pkg-config tzdata \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install -j"$(nproc)" \
         pdo pdo_mysql mysqli intl zip gd bcmath mbstring curl xml \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

FROM runtime_base AS builder

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN apt-get update && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*

ARG DOMAIN_MONITOR_REF=main
RUN git clone --depth 1 --branch "${DOMAIN_MONITOR_REF}" \
    https://github.com/Hosteroid/domain-monitor.git /build

WORKDIR /build
RUN composer install --no-dev --optimize-autoloader --no-interaction

FROM runtime_base

WORKDIR /var/www/html
COPY --from=builder /build .

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
      /etc/apache2/sites-available/000-default.conf \
    && echo "Timeout 300" > /etc/apache2/conf-available/timeouts.conf \
    && a2enconf timeouts

RUN { \
      echo 'max_execution_time = 0'; \
      echo 'max_input_vars = 3000'; \
      echo 'memory_limit = 512M'; \
      echo 'post_max_size = 32M'; \
      echo 'upload_max_filesize = 16M'; \
      echo 'date.timezone = UTC'; \
      echo 'opcache.enable = 1'; \
      echo 'opcache.enable_cli = 1'; \
    } > /usr/local/etc/php/conf.d/domain-monitor.ini

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
