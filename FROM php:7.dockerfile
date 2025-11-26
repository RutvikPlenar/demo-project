FROM php:7.4-fpm

# Install system packages
RUN apt-get update && apt-get install -y \
    cron \
    git \
    unzip \
    libpq-dev \
    libzip-dev && \
    docker-php-ext-install pdo pdo_mysql zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Create application folder
WORKDIR /var/www/demo-project

# Copy app files
COPY . .

# Install dependencies
RUN composer install --no-interaction --prefer-dist

# Copy crontab file
COPY docker/cron/laravel-cron /etc/cron.d/laravel-cron

# Give permissions
RUN chmod 0644 /etc/cron.d/laravel-cron

# Apply cron job
RUN crontab /etc/cron.d/laravel-cron

# Start cron + php-fpm together
CMD cron && php-fpm
