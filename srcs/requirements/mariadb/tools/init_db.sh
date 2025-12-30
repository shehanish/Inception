#!/bin/bash

set -e

# Ensure data directory exists and has proper permissions
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

# Initialize MariaDB data directory if not already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    echo "Starting temporary MariaDB for initial setup..."
    # Start MariaDB in background
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    MYSQL_PID=$!
    
    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to start..."
    for i in {30..0}; do
        if mysqladmin ping --silent; then
            break
        fi
        echo "Waiting for MariaDB... $i"
        sleep 1
    done
    
    if [ "$i" = 0 ]; then
        echo "MariaDB failed to start"
        exit 1
    fi
    
    echo "MariaDB started, configuring database..."
    
    # Run SQL commands
    mysql -u root << EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "MariaDB initialization complete!"
    
    # Shutdown the temporary MariaDB
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQL_PID
fi

echo "Database: ${MYSQL_DATABASE}"
echo "User: ${MYSQL_USER}"

# Start MySQL in foreground
echo "Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql
