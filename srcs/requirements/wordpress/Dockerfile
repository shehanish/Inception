FROM debian:bookworm

# Install PHP-FPM and required PHP extensions
RUN apt-get update && \
    apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-mysqli \
    php8.2-gd \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-zip \
    php8.2-intl \
    php8.2-soap \
    wget \
    curl \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM to listen on port 9000 instead of socket
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|g' /etc/php/8.2/fpm/pool.d/www.conf && \
    sed -i 's|;clear_env = no|clear_env = no|g' /etc/php/8.2/fpm/pool.d/www.conf

# Create required directories
RUN mkdir -p /var/www/html /run/php

# Download and install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy WordPress setup script
COPY tools/setup_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_wordpress.sh

# Set working directory
WORKDIR /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Run setup script and start PHP-FPM
ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]
CMD ["php-fpm8.2", "-F"]
