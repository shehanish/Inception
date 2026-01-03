#!/bin/bash
set -e

# Read database password from secret
DB_PASSWORD=$(cat /run/secrets/db_password)

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h"${MYSQL_HOST}"  -u"${MYSQL_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 2
done
echo "MariaDB is up and running"

# Change to WordPress directory
cd /var/www/html

# Download WordPress if not already present
if [ ! -f wp-config.php ]; then
    echo "Installing WordPress..."
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
		--dbhost="${MYSQL_HOST}" \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    
    # Create additional WordPress user
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
    
    echo "WordPress installation complete"
else
    echo "WordPress is already installed"
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Start PHP-FPM in foreground
echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
