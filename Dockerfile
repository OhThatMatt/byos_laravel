FROM bnussbau/php:8.3-fpm-opcache-imagick-puppeteer-alpine3.20

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/custom.ini

# Create required directories with proper permissions
RUN mkdir -p /var/log/supervisor \
    && mkdir -p storage/logs \
    && mkdir -p storage/framework/{cache,sessions,views} \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/testing \
    && chmod -R 775 storage \
    && chown -R www-data:www-data storage \
    && mkdir -p bootstrap/cache \
    && chmod -R 775 bootstrap/cache \
    && chown -R www-data:www-data bootstrap \
    && mkdir -p database \
    && touch database/database.sqlite \
    && chmod -R 777 database

# Copy application files
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data ./.env.example ./.env

# Set proper environment variables
RUN echo "VIEW_COMPILED_PATH=/var/www/html/storage/framework/views" >> .env \
    && echo "CACHE_DRIVER=file" >> .env

# Install application dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
RUN npm ci && npm run build

# Generate application key and run migrations
RUN php artisan key:generate --force
RUN php artisan migrate --force

# Ensure storage directories exist and have proper permissions
RUN mkdir -p storage/framework/views \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/testing \
    && chown -R www-data:www-data storage \
    && chmod -R 775 storage

# Create entrypoint script properly
COPY - <<'EOF' /docker-entrypoint.sh
#!/bin/sh
set -e

echo "Setting correct permissions..."
chmod -R 777 /var/www/html/database
chown -R www-data:www-data /var/www/html/database
chmod -R 775 /var/www/html/storage
chown -R www-data:www-data /var/www/html/storage

echo "Starting supervisord..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /docker-entrypoint.sh

# Expose port 80
EXPOSE 80

# Use entrypoint script
CMD ["/docker-entrypoint.sh"]
