FROM php:7.4-apache

# Install system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    cron \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Apache modules
RUN a2enmod rewrite headers

# Working dir
WORKDIR /var/www/demo-project

# Copy composer files early for caching
COPY composer.json composer.lock ./

# Install packages without autoload
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts --no-autoloader

# Copy entire Laravel project
COPY . .

# Install again with autoload and optimization
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Create Laravel required directories
RUN mkdir -p storage/framework/{cache/data,sessions,views} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache

# Storage + cache permissions
RUN chmod -R 775 storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

# Apache document root
ENV APACHE_DOCUMENT_ROOT=/var/www/demo-project/public

# Change Apache config for new doc root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# Copy your Apache vhost
COPY docker/apache/laravel.conf /etc/apache2/sites-available/000-default.conf

# ----------------------------------------------------------
#  CRON SETUP
# ----------------------------------------------------------

# Copy cron file (updated path inside it!)
COPY docker/cron/laravel-cron /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron \
    && crontab /etc/cron.d/laravel-cron

# Create cron log inside Laravel storage
RUN touch /var/www/demo-project/storage/logs/cron.log \
    && chmod 666 /var/www/demo-project/storage/logs/cron.log

# Startup script: start cron + apache
RUN echo '#!/bin/bash\n\
    service cron start\n\
    tail -F /var/www/demo-project/storage/logs/cron.log &\n\
    apache2-foreground' > /usr/local/bin/start.sh \
    && chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]
